//! Local persistence: favourites, play history, settings and the session.
//!
//! Everything lives in one SQLite file under the XDG data directory
//! (`~/.local/share/sparkmusic/sparkmusic.db`). The UI never sees SQL — the
//! QObject exposes JSON in and JSON out.

use std::path::{Path, PathBuf};
use std::sync::Mutex;

use rusqlite::{params, Connection};
use serde::{Deserialize, Serialize};

pub const SCHEMA_VERSION: i64 = 3;

/// A saved track. The shape matches the QML `TrackRow` model so favourites can
/// be fed straight into the same list component.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Track {
    pub id: i64,
    pub title: String,
    #[serde(default)]
    pub artist: String,
    #[serde(default, alias = "shortArtist")]
    pub short_artist: String,
    #[serde(default)]
    pub album: String,
    #[serde(default)]
    pub year: String,
    #[serde(default)]
    pub label: String,
    #[serde(default)]
    pub genre: String,
    #[serde(default)]
    pub duration: i64,
    #[serde(default)]
    pub favorited: bool,
    #[serde(default)]
    pub note: String,
}

impl Track {
    pub fn into_json(self) -> serde_json::Value {
        serde_json::json!({
            "id": self.id,
            "title": self.title,
            "artist": self.artist,
            "shortArtist": if self.short_artist.is_empty() { self.artist.clone() } else { self.short_artist },
            "album": self.album,
            "year": self.year,
            "label": self.label,
            "genre": self.genre,
            "duration": self.duration,
            "favorited": true,
            "note": self.note,
        })
    }
}

pub struct Database {
    conn: Mutex<Connection>,
    path: Option<PathBuf>,
}

impl Database {
    /// Default location, creating the parent directory when needed.
    pub fn default_path() -> Option<PathBuf> {
        let base = std::env::var_os("XDG_DATA_HOME")
            .map(PathBuf::from)
            .or_else(|| {
                std::env::var_os("HOME").map(|home| PathBuf::from(home).join(".local/share"))
            })?;
        Some(base.join("sparkmusic").join("sparkmusic.db"))
    }

    pub fn open_default() -> rusqlite::Result<Self> {
        match Self::default_path() {
            Some(path) => {
                if let Some(parent) = path.parent() {
                    let _ = std::fs::create_dir_all(parent);
                }
                Self::open(&path)
            }
            None => Self::open_in_memory(),
        }
    }

    pub fn open(path: &Path) -> rusqlite::Result<Self> {
        let conn = Connection::open(path)?;
        let mut db = Self::init(conn)?;
        db.path = Some(path.to_path_buf());
        db.restrict_permissions();
        Ok(db)
    }

    /// The file holds `MUSIC_U`; keep it owner-only on POSIX systems.
    fn restrict_permissions(&self) {
        #[cfg(unix)]
        if let Some(path) = &self.path {
            use std::os::unix::fs::PermissionsExt;
            let _ = std::fs::set_permissions(path, std::fs::Permissions::from_mode(0o600));
        }
    }

    pub fn open_in_memory() -> rusqlite::Result<Self> {
        let conn = Connection::open_in_memory()?;
        Self::init(conn)
    }

    fn init(conn: Connection) -> rusqlite::Result<Self> {
        conn.execute_batch(
            "PRAGMA journal_mode = WAL;
             PRAGMA foreign_keys = ON;
             CREATE TABLE IF NOT EXISTS favorites (
                 song_id  INTEGER PRIMARY KEY,
                 title    TEXT NOT NULL,
                 artist   TEXT NOT NULL DEFAULT '',
                 album    TEXT NOT NULL DEFAULT '',
                 duration INTEGER NOT NULL DEFAULT 0,
                 added_at INTEGER NOT NULL
             );
             CREATE TABLE IF NOT EXISTS plays (
                 seq      INTEGER PRIMARY KEY AUTOINCREMENT,
                 song_id  INTEGER NOT NULL,
                 title    TEXT NOT NULL,
                 artist   TEXT NOT NULL DEFAULT '',
                 album    TEXT NOT NULL DEFAULT '',
                 duration INTEGER NOT NULL DEFAULT 0,
                 played_at INTEGER NOT NULL
             );
             CREATE TABLE IF NOT EXISTS settings (
                 key   TEXT PRIMARY KEY,
                 value TEXT NOT NULL
             );
             CREATE TABLE IF NOT EXISTS session (
                 id     INTEGER PRIMARY KEY CHECK (id = 1),
                 cookie TEXT NOT NULL,
                 saved_at INTEGER NOT NULL
             );
             CREATE TABLE IF NOT EXISTS cache (
                 key      TEXT PRIMARY KEY,
                 payload  TEXT NOT NULL,
                 saved_at INTEGER NOT NULL
             );
             CREATE TABLE IF NOT EXISTS search_history (
                 query       TEXT PRIMARY KEY,
                 searched_at INTEGER NOT NULL,
                 hits        INTEGER NOT NULL DEFAULT 1
             );",
        )?;
        // v1 databases predate the artist/album/duration snapshot columns.
        let columns: Vec<String> = {
            let mut stmt = conn.prepare("PRAGMA table_info(plays)")?;
            let rows = stmt.query_map([], |row| row.get::<_, String>(1))?;
            rows.collect::<Result<_, _>>()?
        };
        for (name, decl) in [
            ("artist", "TEXT NOT NULL DEFAULT ''"),
            ("album", "TEXT NOT NULL DEFAULT ''"),
            ("duration", "INTEGER NOT NULL DEFAULT 0"),
        ] {
            if !columns.iter().any(|c| c == name) {
                conn.execute_batch(&format!("ALTER TABLE plays ADD COLUMN {name} {decl};"))?;
            }
        }
        conn.pragma_update(None, "user_version", SCHEMA_VERSION)?;
        Ok(Self {
            conn: Mutex::new(conn),
            path: None,
        })
    }

    fn lock(&self) -> std::sync::MutexGuard<'_, Connection> {
        self.conn
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
    }

    // ------------------------------------------------------------- favourites
    pub fn add_favorite(&self, track: &Track) -> rusqlite::Result<()> {
        self.lock().execute(
            "INSERT INTO favorites (song_id, title, artist, album, duration, added_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(song_id) DO UPDATE SET
                 title = excluded.title,
                 artist = excluded.artist,
                 album = excluded.album,
                 duration = excluded.duration",
            params![
                track.id,
                track.title,
                track.artist,
                track.album,
                track.duration,
                now_secs()
            ],
        )?;
        Ok(())
    }

    pub fn remove_favorite(&self, song_id: i64) -> rusqlite::Result<()> {
        self.lock()
            .execute("DELETE FROM favorites WHERE song_id = ?1", params![song_id])?;
        Ok(())
    }

    pub fn is_favorite(&self, song_id: i64) -> rusqlite::Result<bool> {
        let count: i64 = self.lock().query_row(
            "SELECT COUNT(*) FROM favorites WHERE song_id = ?1",
            params![song_id],
            |row| row.get(0),
        )?;
        Ok(count > 0)
    }

    pub fn favorites(&self) -> rusqlite::Result<Vec<Track>> {
        let conn = self.lock();
        let mut stmt = conn.prepare(
            "SELECT song_id, title, artist, album, duration
             FROM favorites ORDER BY added_at DESC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(Track {
                id: row.get(0)?,
                title: row.get(1)?,
                artist: row.get(2)?,
                short_artist: row.get(2)?,
                album: row.get(3)?,
                duration: row.get(4)?,
                year: String::new(),
                label: "LOCAL".into(),
                genre: String::new(),
                favorited: true,
                note: "本地收藏 · 存储于 sparkmusic.db".into(),
            })
        })?;
        rows.collect()
    }

    // --------------------------------------------------------------- history
    pub fn record_play(&self, track: &Track) -> rusqlite::Result<()> {
        self.lock().execute(
            "INSERT INTO plays (song_id, title, artist, album, duration, played_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![
                track.id,
                track.title,
                track.artist,
                track.album,
                track.duration,
                now_secs()
            ],
        )?;
        Ok(())
    }

    pub fn history(&self, limit: i64) -> rusqlite::Result<Vec<Track>> {
        let conn = self.lock();
        let mut stmt = conn.prepare(
            "SELECT p.song_id, p.title,
                    COALESCE(NULLIF(p.artist, ''), (SELECT artist FROM favorites f WHERE f.song_id = p.song_id), ''),
                    COALESCE(NULLIF(p.album, ''),  (SELECT album  FROM favorites f WHERE f.song_id = p.song_id), ''),
                    MAX(p.duration, COALESCE((SELECT duration FROM favorites f WHERE f.song_id = p.song_id), 0)),
                    MAX(p.played_at)
             FROM plays p
             GROUP BY p.song_id
             ORDER BY MAX(p.played_at) DESC
             LIMIT ?1",
        )?;
        let rows = stmt.query_map(params![limit], |row| {
            Ok(Track {
                id: row.get(0)?,
                title: row.get(1)?,
                artist: row.get(2)?,
                short_artist: row.get(2)?,
                album: row.get(3)?,
                duration: row.get(4)?,
                year: String::new(),
                label: "HISTORY".into(),
                genre: String::new(),
                favorited: false,
                note: "播放历史".into(),
            })
        })?;
        rows.collect()
    }

    pub fn clear_history(&self) -> rusqlite::Result<()> {
        self.lock().execute("DELETE FROM plays", [])?;
        Ok(())
    }

    // -------------------------------------------------------------- settings
    pub fn set_setting(&self, key: &str, value: &str) -> rusqlite::Result<()> {
        self.lock().execute(
            "INSERT INTO settings (key, value) VALUES (?1, ?2)
             ON CONFLICT(key) DO UPDATE SET value = excluded.value",
            params![key, value],
        )?;
        Ok(())
    }

    pub fn setting(&self, key: &str) -> Option<String> {
        self.lock()
            .query_row(
                "SELECT value FROM settings WHERE key = ?1",
                params![key],
                |row| row.get(0),
            )
            .ok()
    }

    // ----------------------------------------------------------------- cache
    pub fn cache_put(&self, key: &str, payload: &str) -> rusqlite::Result<()> {
        self.lock().execute(
            "INSERT INTO cache (key, payload, saved_at) VALUES (?1, ?2, ?3)
             ON CONFLICT(key) DO UPDATE SET payload = excluded.payload, saved_at = excluded.saved_at",
            params![key, payload, now_secs()],
        )?;
        Ok(())
    }

    pub fn cache_get(&self, key: &str, max_age_secs: i64) -> Option<String> {
        let conn = self.lock();
        let (payload, saved_at): (String, i64) = conn
            .query_row(
                "SELECT payload, saved_at FROM cache WHERE key = ?1",
                params![key],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .ok()?;
        if now_secs() - saved_at <= max_age_secs {
            Some(payload)
        } else {
            None
        }
    }

    pub fn cache_stats(&self) -> (i64, i64) {
        self.lock()
            .query_row(
                "SELECT COUNT(*), COALESCE(SUM(LENGTH(payload)), 0) FROM cache",
                [],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .unwrap_or((0, 0))
    }

    pub fn clear_cache(&self) -> rusqlite::Result<()> {
        self.lock().execute("DELETE FROM cache", [])?;
        Ok(())
    }

    // -------------------------------------------------------- search history
    pub fn record_search(&self, query: &str) -> rusqlite::Result<()> {
        let query = query.trim();
        if query.is_empty() {
            return Ok(());
        }
        self.lock().execute(
            "INSERT INTO search_history (query, searched_at, hits) VALUES (?1, ?2, 1)
             ON CONFLICT(query) DO UPDATE SET
                 searched_at = excluded.searched_at,
                 hits = hits + 1",
            params![query, now_secs()],
        )?;
        Ok(())
    }

    pub fn search_history(&self, limit: i64) -> rusqlite::Result<Vec<String>> {
        let conn = self.lock();
        let mut stmt =
            conn.prepare("SELECT query FROM search_history ORDER BY searched_at DESC LIMIT ?1")?;
        let rows = stmt.query_map(params![limit.max(1)], |row| row.get(0))?;
        rows.collect()
    }

    pub fn clear_search_history(&self) -> rusqlite::Result<()> {
        self.lock().execute("DELETE FROM search_history", [])?;
        Ok(())
    }

    // --------------------------------------------------------------- session
    pub fn save_session(&self, cookie: &str) -> rusqlite::Result<()> {
        self.lock().execute(
            "INSERT INTO session (id, cookie, saved_at) VALUES (1, ?1, ?2)
             ON CONFLICT(id) DO UPDATE SET cookie = excluded.cookie, saved_at = excluded.saved_at",
            params![cookie, now_secs()],
        )?;
        Ok(())
    }

    pub fn load_session(&self) -> Option<String> {
        self.lock()
            .query_row("SELECT cookie FROM session WHERE id = 1", [], |row| {
                row.get(0)
            })
            .ok()
    }

    pub fn clear_session(&self) -> rusqlite::Result<()> {
        self.lock().execute("DELETE FROM session", [])?;
        Ok(())
    }
}

fn now_secs() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn track(id: i64) -> Track {
        Track {
            id,
            title: format!("song {id}"),
            artist: "artist".into(),
            short_artist: "artist".into(),
            album: "album".into(),
            year: "2026".into(),
            label: "NETEASE".into(),
            genre: String::new(),
            duration: 200,
            favorited: false,
            note: String::new(),
        }
    }

    #[test]
    fn favourites_round_trip() {
        let db = Database::open_in_memory().unwrap();
        assert!(!db.is_favorite(1).unwrap());
        db.add_favorite(&track(1)).unwrap();
        assert!(db.is_favorite(1).unwrap());
        assert_eq!(db.favorites().unwrap().len(), 1);
        db.add_favorite(&track(1)).unwrap(); // idempotent
        assert_eq!(db.favorites().unwrap().len(), 1);
        db.remove_favorite(1).unwrap();
        assert!(!db.is_favorite(1).unwrap());
    }

    #[test]
    fn history_dedupes_by_song() {
        let db = Database::open_in_memory().unwrap();
        db.record_play(&track(7)).unwrap();
        db.record_play(&track(7)).unwrap();
        db.record_play(&track(8)).unwrap();
        let history = db.history(10).unwrap();
        assert_eq!(history.len(), 2);
        assert_eq!(history[0].id, 8); // most recent first
        db.clear_history().unwrap();
        assert!(db.history(10).unwrap().is_empty());
    }

    #[test]
    fn settings_and_session_are_single_valued() {
        let db = Database::open_in_memory().unwrap();
        assert_eq!(db.setting("theme"), None);
        db.set_setting("theme", "ink").unwrap();
        db.set_setting("theme", "paper").unwrap();
        assert_eq!(db.setting("theme").as_deref(), Some("paper"));

        db.save_session("MUSIC_U=abc; __csrf=tok").unwrap();
        assert_eq!(
            db.load_session().as_deref(),
            Some("MUSIC_U=abc; __csrf=tok")
        );
        db.save_session("MUSIC_U=xyz").unwrap();
        assert_eq!(db.load_session().as_deref(), Some("MUSIC_U=xyz"));
        db.clear_session().unwrap();
        assert_eq!(db.load_session(), None);
    }

    #[test]
    fn cache_respects_ttl() {
        let db = Database::open_in_memory().unwrap();
        db.cache_put("lyric:1", "{\"lrc\":{}}").unwrap();
        assert_eq!(db.cache_get("lyric:1", 60).as_deref(), Some("{\"lrc\":{}}"));
        assert_eq!(db.cache_get("lyric:1", -1), None); // expired
        assert_eq!(db.cache_get("missing", 60), None);
        assert_eq!(db.cache_stats().0, 1);
        db.clear_cache().unwrap();
        assert_eq!(db.cache_stats().0, 0);
    }

    #[test]
    fn search_history_dedupes_and_orders() {
        let db = Database::open_in_memory().unwrap();
        db.record_search("a").unwrap();
        db.record_search("b").unwrap();
        db.record_search("a").unwrap();
        let history = db.search_history(10).unwrap();
        assert_eq!(history.len(), 2);
        assert_eq!(history[0], "a"); // touched most recently
        db.clear_search_history().unwrap();
        assert!(db.search_history(10).unwrap().is_empty());
    }

    #[test]
    fn json_shape_matches_the_qml_model() {
        let value = track(3).into_json();
        assert_eq!(value["id"], 3);
        assert_eq!(value["shortArtist"], "artist");
        assert_eq!(value["favorited"], true);
        assert_eq!(value["duration"], 200);
    }
}
