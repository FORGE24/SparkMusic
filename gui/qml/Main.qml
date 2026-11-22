import QtQuick
import QtQuick.Layouts
import QtMultimedia

Window {
    id: root

    width: 1360
    height: 860
    visible: true
    title: qsTr("静听 · STILLE")
    color: pal.canvas
    // Client-side chrome: the paper is the title bar.
    flags: Qt.Window | Qt.FramelessWindowHint

    readonly property string serif: "Noto Serif CJK SC"
    readonly property string serifLatin: "Noto Serif"
    readonly property string serifDisplay: "Cormorant Garamond"

    property string theme: typeof launchTheme !== "undefined" && launchTheme !== "" ? launchTheme : "paper"
    property bool gridOn: false
    property string view: typeof initialView !== "undefined" ? initialView : "home"
    property string section: typeof initialSection !== "undefined" ? initialSection : "curated"

    readonly property var paper: ({
        canvas: "#F2F1ED", ink: "#141414",
        ink2: "#8E141414", ink3: "#5C141414",
        faint: "#24141414", ultra: "#0F141414",
        rule: "#24141414", accent: "#D93829"
    })
    readonly property var inkPal: ({
        canvas: "#121212", ink: "#EAE8E3",
        ink2: "#8EEAE8E3", ink3: "#5CEAE8E3",
        faint: "#24EAE8E3", ultra: "#0FEAE8E3",
        rule: "#24EAE8E3", accent: "#D93829"
    })
    readonly property var pal: theme === "paper" ? paper : inkPal

    // ------------------------------------------------------------------ data
    property var tracks: []
    property var searchResults: []
    property string searchStatus: "键入曲名、演奏者、专辑或厂牌……"
    property string listTitle: "载入中……"
    property string listSubtitle: ""
    property int currentIndex: 0
    readonly property var currentTrack: tracks.length > 0
        ? tracks[Math.min(currentIndex, tracks.length - 1)] : null
    property bool playing: false
    property real volume: 0.68
    property int position: 0
    readonly property real progress: currentTrack && currentTrack.duration > 0
        ? Math.min(1, Math.max(0, position / currentTrack.duration)) : 0
    // Captured before a track change so the old playhead can travel home.
    property real handoffProgress: 0
    property var lyrics: []
    property string playbackNote: ""
    property var favorites: []
    property var history: []
    property var searchHistory: []
    property var accountPlaylists: []
    property string accountNote: ""
    property string cacheNote: ""
    property string exportNote: ""
    property bool currentFavorited: false
    property string currentCover: ""
    property double coverRequestId: 0
    property bool loggedIn: false
    property string nickname: ""
    // NetEase user ids exceed 32-bit ints; double holds every id exactly
    // (JS numbers are exact up to 2^53), so never narrow this to `int`.
    property double userUid: 0
    property string likedPlaylistId: ""
    property string quality: "exhigh"
    property bool lyricFollow: true
    readonly property string appVersion: typeof launchVersion !== "undefined" ? launchVersion : "0.1.1-beta"

    MediaPlayer {
        id: audio
        audioOutput: AudioOutput { volume: root.volume }
        onPositionChanged: if (root.playing) root.position = Math.floor(position / 1000)
        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.StoppedState && root.playing
                    && audio.duration > 0 && position >= audio.duration - 100)
                root.nextTrack();
        }
    }

    Timer {
        interval: 1000
        running: root.playing && !audio.hasAudio
        repeat: true
        onTriggered: {
            if (root.currentTrack && root.position < root.currentTrack.duration)
                root.position += 1;
            else
                root.playing = false;
        }
    }

    // Covers for local favourites/history are resolved by song id. Defer the
    // blocking request so the player paints immediately.
    Timer {
        id: coverTimer
        interval: 0
        repeat: false
        onTriggered: root.fetchCover(root.coverRequestId)
    }

    // Volume is dragged continuously; debounce the SQLite write.
    Timer {
        id: volumeSaveTimer
        interval: 320
        onTriggered: core.setSetting("volume", String(root.volume))
    }

    Component.onCompleted: {
        if (typeof launchTheme === "undefined" || launchTheme === "")
            theme = core.setting("theme") || "paper";
        gridOn = (core.setting("grid") || "0") === "1";
        quality = core.setting("quality") || "exhigh";
        lyricFollow = (core.setting("lyricFollow") || "1") === "1";
        var savedVolume = core.setting("volume");
        if (savedVolume.length > 0) {
            var parsedVolume = Number(savedVolume);
            if (!isNaN(parsedVolume))
                volume = Math.max(0, Math.min(1, parsedVolume));
        }

        refreshLibrary();

        if (typeof launchDemoAccount !== "undefined" && launchDemoAccount) {
            loggedIn = true;
            nickname = "演示账户";
            likedPlaylistId = "24325528";
            accountPlaylists = [
                { id: "24325528", name: "我喜欢的音乐", count: 128, specialType: 5 },
                { id: "3778678", name: "热歌榜", count: 100, specialType: 0 },
                { id: "19723756", name: "飙升榜", count: 100, specialType: 0 }
            ];
        }

        var saved = core.loadSession();
        if (saved.length > 0) {
            var acc = JSON.parse(core.account());
            var me = acc.account || null;
            if (me && me.id) {
                loggedIn = true;
                nickname = (acc.profile || {}).nickname || "";
                userUid = Number(me.id);
                fetchAccountPlaylists();
            } else if (acc.code === 200 || acc.code === 301) {
                // The server explicitly says this MUSIC_U is not a session.
                // Do not clear on a transport error (-1): offline starts
                // must keep the saved login for the next launch.
                core.clearCookies();
                core.clearSession();
            }
        }

        loadPlaylist("3778678", "热歌榜");
        if (typeof launchPlay !== "undefined" && launchPlay >= 0)
            playTrack(launchPlay);
    }

    onThemeChanged: core.setSetting("theme", theme)
    onGridOnChanged: core.setSetting("grid", gridOn ? "1" : "0")
    onVolumeChanged: volumeSaveTimer.restart()

    // ------------------------------------------------------------- API glue
    function coverFromSong(song) {
        var album = song.al || song.album || {};
        return album.picUrl || album.pic_url || "";
    }

    function trackFromSong(song) {
        var artist = "";
        if (song.ar && song.ar.length > 0) artist = song.ar[0].name;
        else if (song.artists && song.artists.length > 0) artist = song.artists[0].name;
        var albumObj = song.al || song.album || {};
        var album = albumObj.name || "";
        return {
            id: song.id,
            title: song.name,
            artist: artist,
            shortArtist: artist,
            album: album || "",
            cover: coverFromSong(song),
            year: "",
            label: "NETEASE",
            genre: "",
            duration: Math.round((song.dt || song.duration || 0) / 1000),
            favorited: false,
            note: ""
        };
    }

    function loadPlaylist(id, title) {
        listTitle = "载入中……";
        // 1000 is the upstream window cap; the ListView virtualizes the rows.
        var raw = core.playlist(Number(id), 1000);
        var out = [];
        try {
            var data = JSON.parse(raw);
            var playlist = data.playlist || {};
            // v6 normally carries playlist.tracks; the fallback also accepts
            // a top-level songs array (older/v4-shaped payloads).
            var songs = (playlist.tracks && playlist.tracks.length > 0)
                    ? playlist.tracks : (data.songs || []);
            for (var i = 0; i < songs.length; i++)
                out.push(trackFromSong(songs[i]));
            if (out.length > 0) {
                listTitle = title || playlist.name;
                listSubtitle = out.length + " 首 · " + (playlist.name || "网易云音乐");
            } else {
                var code = data.code !== undefined ? data.code : "?";
                var msg = data.message || data.msg || "";
                var ids = (playlist.trackIds || []).length;
                var count = playlist.trackCount !== undefined ? playlist.trackCount : "?";
                var special = Number(playlist.specialType || 0);
                var likedHint = (special === 5
                        || (title && String(title).indexOf("喜欢") >= 0))
                        ? "（「我喜欢的音乐」需要登录本人账号）" : "";
                listTitle = "该歌单暂无曲目";
                listSubtitle = (playlist.name ? playlist.name + " · " : "")
                        + "code " + code
                        + " · 曲目 " + count + " / ID " + ids
                        + (msg.length > 0 ? " · " + msg : "")
                        + likedHint;
            }
        } catch (e) {
            listTitle = "解析失败";
            listSubtitle = raw.substring(0, 140);
        }
        tracks = out;
        currentIndex = 0;
        coverTimer.stop();
        coverRequestId = 0;
        currentCover = out.length > 0 ? (out[0].cover || "") : "";
    }

    function openPlaylist(id, title) {
        section = "curated";
        loadPlaylist(id, title);
    }

    function searchModel(query) {
        if (query.trim().length === 0) {
            searchResults = [];
            searchStatus = "键入曲名、演奏者、专辑或厂牌……";
            return;
        }
        var raw = core.searchSongs(query, 20, 0);
        try {
            var data = JSON.parse(raw);
            var songs = (data.result || {}).songs || [];
            var out = [];
            for (var i = 0; i < songs.length; i++)
                out.push(trackFromSong(songs[i]));
            searchResults = out;
            searchStatus = "命中 " + ((data.result || {}).songCount || 0) + " 项 · 显示 " + out.length + " 项";
        } catch (e) {
            searchResults = [];
            searchStatus = "检索失败";
        }
        refreshLibrary();

        if (typeof launchDemoAccount !== "undefined" && launchDemoAccount) {
            loggedIn = true;
            nickname = "演示账户";
            likedPlaylistId = "24325528";
            accountPlaylists = [
                { id: "24325528", name: "我喜欢的音乐", count: 128, specialType: 5 },
                { id: "3778678", name: "热歌榜", count: 100, specialType: 0 },
                { id: "19723756", name: "飙升榜", count: 100, specialType: 0 }
            ];
        }
    }

    function playTrack(index) {
        if (index < 0 || index >= tracks.length) return;
        handoffProgress = progress;
        currentIndex = index;
        position = 0;
        lyrics = [];
        playbackNote = "";
        playing = true;
        view = "player";
        var track = tracks[index];
        currentFavorited = core.isFavorite(track.id);
        loadCover(track);
        core.recordPlay(JSON.stringify(track));
        refreshLibrary();

        if (typeof launchDemoAccount !== "undefined" && launchDemoAccount) {
            loggedIn = true;
            nickname = "演示账户";
            likedPlaylistId = "24325528";
            accountPlaylists = [
                { id: "24325528", name: "我喜欢的音乐", count: 128, specialType: 5 },
                { id: "3778678", name: "热歌榜", count: 100, specialType: 0 },
                { id: "19723756", name: "飙升榜", count: 100, specialType: 0 }
            ];
        }
        loadLyrics(track.id);
        loadUrl(track.id);
    }

    function refreshLibrary() {
        favorites = JSON.parse(core.favorites());
        history = JSON.parse(core.history(20));
        searchHistory = JSON.parse(core.searchHistory(8));
        var stats = JSON.parse(core.cacheStats());
        cacheNote = stats.entries + " 条 · " + (stats.bytes / 1024).toFixed(0) + " KB";
    }

    function exportFavorites() {
        var path = core.exportFavorites("");
        exportNote = path.length > 0 ? ("已写入 " + path) : "导出失败（没有收藏或路径不可写）";
    }

    function toggleFavorite() {
        if (!currentTrack) return;
        if (currentFavorited) {
            core.removeFavorite(currentTrack.id);
            currentFavorited = false;
        } else {
            core.addFavorite(JSON.stringify(currentTrack));
            currentFavorited = true;
        }
        refreshLibrary();

        if (typeof launchDemoAccount !== "undefined" && launchDemoAccount) {
            loggedIn = true;
            nickname = "演示账户";
            likedPlaylistId = "24325528";
            accountPlaylists = [
                { id: "24325528", name: "我喜欢的音乐", count: 128, specialType: 5 },
                { id: "3778678", name: "热歌榜", count: 100, specialType: 0 },
                { id: "19723756", name: "飙升榜", count: 100, specialType: 0 }
            ];
        }
    }

    function playFavorite(index) {
        if (index < 0 || index >= favorites.length) return;
        tracks = favorites;
        playTrack(index);
    }

    function playHistory(index) {
        if (index < 0 || index >= history.length) return;
        tracks = history;
        playTrack(index);
    }

    function playSearchResult(index) {
        tracks = searchResults;
        playTrack(index);
    }

    function loadUrl(id) {
        var raw = core.songUrl(String(id), quality);
        try {
            var data = JSON.parse(raw);
            var first = (data.data || [])[0] || {};
            if (first.url) {
                audio.source = first.url;
                audio.play();
                playbackNote = "";
            } else {
                audio.stop();
                audio.source = "";
                playbackNote = "该曲目暂无可播放地址（版权或登录限制），仅显示歌词。";
            }
        } catch (e) {
            playbackNote = "播放地址解析失败";
        }
    }

    function loadCover(track) {
        if (!track) {
            coverTimer.stop();
            currentCover = "";
            coverRequestId = 0;
            return;
        }
        if (track.cover && track.cover.length > 0) {
            coverTimer.stop();
            currentCover = track.cover;
            coverRequestId = 0;
            return;
        }
        // Local favourites/history do not store a cover, so resolve one by id
        // from song detail; API tracks already carry al.picUrl.
        currentCover = "";
        coverRequestId = Number(track.id);
        coverTimer.restart();
    }

    function fetchCover(id) {
        if (!currentTrack || Number(currentTrack.id) !== Number(id))
            return;
        var raw = core.songDetail(Number(id));
        try {
            var songs = JSON.parse(raw).songs || [];
            if (songs.length > 0 && currentTrack
                    && Number(currentTrack.id) === Number(id))
                currentCover = coverFromSong(songs[0]);
        } catch (e) {}
    }

    function loadLyrics(id) {
        var raw = core.lyric(Number(id));
        try {
            lyrics = parseLrc(((JSON.parse(raw).lrc) || {}).lyric || "");
        } catch (e) {
            lyrics = [];
        }
    }

    function parseLrc(text) {
        var out = [];
        var lines = text.split("\n");
        var re = /^\[(\d+):(\d+)(?:[.:](\d+))?\]\s*(.*)$/;
        for (var i = 0; i < lines.length; i++) {
            var m = re.exec(lines[i].trim());
            if (!m) continue;
            var content = m[4].trim();
            if (content.length === 0) continue;
            out.push({ time: Number(m[1]) * 60 + Number(m[2]), text: content, sub: "" });
        }
        return out;
    }

    function handleLoggedIn(nick) {
        var raw = core.account();
        var data = {};
        try {
            data = JSON.parse(raw);
        } catch (e) {}
        var me = data.account || null;
        if (!me || !me.id) {
            // code 200 with account:null means the cookie did not stick;
            // -1 means the verification request itself failed.
            loggedIn = false;
            userUid = 0;
            accountPlaylists = [];
            accountNote = (data.code === 200 || data.code === 301)
                    ? "登录响应成功，但会话未建立（account 为空）。请重试或改用 Cookie 登录。"
                    : "账户校验失败 · " + (data.code !== undefined ? data.code : "?")
                      + (data.message ? " · " + data.message : "");
            view = "login";
            return;
        }
        loggedIn = true;
        nickname = nick.length > 0 ? nick : ((data.profile || {}).nickname || "");
        userUid = Number(me.id);
        // Generic login paths (SMS) return the credential in the JSON body;
        // persist it even if the caller forgot so a restart stays signed in.
        core.saveSession();
        view = "home";
        section = "curated";
        fetchAccountPlaylists();
    }

    function clearSession() {
        core.clearCookies();
        core.clearSession();
        accountPlaylists = [];
        accountNote = "";
        loggedIn = false;
        nickname = "";
        userUid = 0;
        likedPlaylistId = "";
    }

    function signOut() {
        clearSession();
        view = "login";
    }

    function fetchAccountPlaylists() {
        accountPlaylists = [];
        accountNote = "";
        likedPlaylistId = "";
        if (userUid <= 0) {
            accountNote = "账户未就绪，请重新登录";
            return;
        }
        var raw = core.userPlaylists(Number(userUid));
        try {
            var data = JSON.parse(raw);
            if (data.code !== 200) {
                var why = data.message || data.msg || "";
                accountNote = "账户歌单读取失败 · " + data.code
                        + (why.length > 0 ? " · " + why : "");
                return;
            }
            var lists = data.playlist || (data.data || {}).playlist || [];
            var out = [];
            for (var i = 0; i < lists.length; i++) {
                var p = lists[i];
                var special = Number(p.specialType || 0);
                out.push({
                    id: String(p.id),
                    name: p.name,
                    count: Number(p.trackCount || 0),
                    specialType: special
                });
                // Some accounts no longer expose specialType == 5, so keep a
                // name fallback ("我喜欢的音乐" / "喜欢的音乐").
                var byName = p.name && String(p.name).indexOf("喜欢的音乐") >= 0;
                if (likedPlaylistId.length === 0 && (special === 5 || byName))
                    likedPlaylistId = String(p.id);
            }
            accountPlaylists = out;
            if (out.length === 0)
                accountNote = "该账户没有歌单（可能被设为私密）";
        } catch (e) {
            accountNote = "歌单解析失败 · " + raw.substring(0, 100);
        }
    }

    function loadLiked() {
        if (likedPlaylistId.length === 0)
            fetchAccountPlaylists();
        if (likedPlaylistId.length > 0) {
            loadPlaylist(likedPlaylistId, "我喜欢的音乐");
        } else {
            accountNote = "未找到「我喜欢的音乐」，请确认登录状态";
        }
    }

    function nextTrack() {
        if (tracks.length === 0) return;
        playTrack((currentIndex + 1) % tracks.length);
    }

    function prevTrack() {
        if (tracks.length === 0) return;
        playTrack((currentIndex - 1 + tracks.length) % tracks.length);
    }

    function openPlayer() {
        // Entering the room keeps the current stream untouched; only an empty
        // queue starts the first track.
        if (!currentTrack && tracks.length > 0)
            playTrack(Math.min(currentIndex, tracks.length - 1));
        view = "player";
    }

    function togglePlay() {
        playing = !playing;
        if (audio.source.toString() !== "") {
            if (playing) audio.play(); else audio.pause();
        }
    }

    function clock(seconds) {
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function accountLabel() {
        if (!loggedIn) return "未登录";
        var name = nickname.length > 0 ? nickname : "已登录";
        return name.length > 12 ? name.substring(0, 11) + "…" : name;
    }

    // ----------------------------------------------------------------- -shell
    Item {
        id: stage
        anchors.fill: parent

        Row {
            id: gridOverlay
            anchors.fill: parent
            anchors.leftMargin: 56
            anchors.rightMargin: 56
            opacity: root.gridOn ? 1 : 0
            visible: opacity > 0.001
            spacing: 16
            Behavior on opacity {
                NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
            }

            property real breath: 0
            property real drift: 0

            // Very slow, almost subliminal brightness breathing while playing.
            SequentialAnimation {
                id: gridBreath
                running: root.gridOn && root.playing
                loops: Animation.Infinite
                NumberAnimation {
                    target: gridOverlay
                    property: "breath"
                    from: 0; to: 1
                    duration: 4200
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: gridOverlay
                    property: "breath"
                    from: 1; to: 0
                    duration: 4200
                    easing.type: Easing.InOutSine
                }
                onRunningChanged: if (!running) gridOverlay.breath = 0
            }

            // A couple of columns step sideways when the archive changes.
            SequentialAnimation {
                id: gridArchive
                NumberAnimation {
                    target: gridOverlay
                    property: "drift"
                    from: 0; to: 1
                    duration: 520
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: gridOverlay
                    property: "drift"
                    from: 1; to: 0
                    duration: 620
                    easing.type: Easing.InOutCubic
                }
            }

            Connections {
                target: root
                function onCurrentTrackChanged() {
                    if (root.gridOn) gridArchive.restart();
                }
            }

            Repeater {
                model: 12

                Rectangle {
                    id: gridColumn
                    property int col: index
                    width: (gridOverlay.width - 11 * 16) / 12
                    height: gridOverlay.height
                    color: "transparent"
                    border.color: root.pal.ultra
                    border.width: 1

                    opacity: root.playing
                        ? 0.64 + 0.36 * (0.5 + 0.5 * Math.sin(
                              (gridOverlay.breath * 2 + col / 12) * Math.PI * 2))
                        : 0.72
                    Behavior on opacity {
                        // Follow the breath directly; only smooth the settle
                        // when playback stops.
                        enabled: !root.playing
                        NumberAnimation { duration: 700; easing.type: Easing.OutCubic }
                    }

                    transform: Translate {
                        x: gridOverlay.drift * (col % 2 === 0 ? 2.6 : -1.8)
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.color: root.pal.ink3
                        border.width: 1
                        opacity: {
                            if (!root.gridOn) return 0;
                            var center = (gridColumn.col + 0.5) / 12;
                            return Math.abs(center - root.progress) <= (0.5 / 12)
                                ? (root.playing ? 0.46 : 0.30) : 0;
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }

        Item {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64
            anchors.leftMargin: 56
            anchors.rightMargin: 56

            // Frameless window drag. DragHandler only activates after a real
            // drag, so clicking links/title text still behaves normally.
            DragHandler {
                target: null
                acceptedButtons: Qt.LeftButton
                onActiveChanged: if (active) root.startSystemMove()
            }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                spacing: 10

                Image {
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    source: root.theme === "ink"
                        ? "qrc:/branding/mark-ink.png"
                        : "qrc:/branding/mark-paper.png"
                    sourceSize.width: 36
                    sourceSize.height: 36
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.view === "login" ? "STILLE · ARCHIVE / 扉页"
                        : root.view === "player" ? "STILLE · ARCHIVE / 播放室"
                        : "STILLE · ARCHIVE / 目录"
                    color: root.pal.ink2
                    font.family: root.serifLatin
                    font.pixelSize: 11
                    font.letterSpacing: 1.6
                }
            }

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                spacing: 26

                // Now-playing strip: visible on every page except the login
                // gate, so the catalog/favourites/settings show what is running.
                Item {
                    visible: root.view !== "login" && root.currentTrack
                    height: 20
                    width: nowRow.width

                    Row {
                        id: nowRow
                        spacing: 10

                        Rectangle {
                            width: 5; height: 5; radius: 2.5
                            color: root.pal.accent
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.playing
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, 160)
                            text: root.currentTrack ? root.currentTrack.title : ""
                            color: root.pal.ink
                            font.family: root.serif
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, 96)
                            text: root.currentTrack ? root.currentTrack.artist : ""
                            color: root.pal.ink3
                            font.family: root.serif
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            width: 52; height: 2
                            color: root.pal.faint
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                width: parent.width * root.progress
                                height: 2
                                color: root.pal.accent
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.playing ? "播放中" : "暂停"
                            color: root.pal.ink3
                            font.family: root.serif
                            font.pixelSize: 9
                            font.letterSpacing: 1.2
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openPlayer()
                    }
                }

                TopLink {
                    text: root.accountLabel()
                    active: !root.loggedIn
                    onClicked: {
                        if (root.loggedIn) {
                            root.view = "home";
                            root.section = "favorites";
                        } else {
                            root.view = "login";
                        }
                    }
                }
                TopLink {
                    text: "宣纸 / 玄墨"
                    onClicked: root.theme = root.theme === "paper" ? "ink" : "paper"
                }
                TopLink {
                    text: "网格"
                    active: root.gridOn
                    onClicked: root.gridOn = !root.gridOn
                }

                Rectangle {
                    width: 1; height: 13
                    color: root.pal.faint
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    spacing: 14
                    anchors.verticalCenter: parent.verticalCenter
                    WindowControl {
                        glyph: "–"
                        onClicked: root.showMinimized()
                    }
                    WindowControl {
                        glyph: root.visibility === Window.Maximized ? "❐" : "□"
                        onClicked: {
                            if (root.visibility === Window.Maximized)
                                root.showNormal();
                            else
                                root.showMaximized();
                        }
                    }
                    WindowControl {
                        glyph: "×"
                        danger: true
                        onClicked: root.close()
                    }
                }
            }
        }

        Item {
            id: horizon
            anchors.top: topBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 56
            anchors.rightMargin: 56
            height: 22

            property bool scrubbing: false
            property bool snapping: false
            property real shownProgress: root.progress

            // Playing uses a one-second linear interpolation so the dot glides
            // instead of stepping; dragging follows with a little inertia and
            // snaps back to the target on release.
            Behavior on shownProgress {
                NumberAnimation {
                    duration: horizon.scrubbing ? 90 : (horizon.snapping ? 180 : 980)
                    easing.type: (horizon.scrubbing || horizon.snapping)
                        ? Easing.OutCubic : Easing.Linear
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 1
                color: root.pal.rule
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * horizon.shownProgress
                height: 1
                color: root.pal.ink
                opacity: root.playing ? 1 : 0.62
                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            }

            // A faint echo that travels back to zero when the archive changes.
            Rectangle {
                id: returnDot
                width: 5; height: 5; radius: 2.5
                color: root.pal.accent
                opacity: 0
                anchors.verticalCenter: parent.verticalCenter
            }
            SequentialAnimation {
                id: returnDotAnimation
                ScriptAction {
                    script: {
                        returnDot.x = root.handoffProgress * (horizon.width - 5);
                        returnDot.opacity = root.playing ? 0.9 : 0;
                    }
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: returnDot
                        property: "x"
                        to: 0
                        duration: 650
                        easing.type: Easing.InOutCubic
                    }
                    NumberAnimation {
                        target: returnDot
                        property: "opacity"
                        to: 0
                        duration: 650
                        easing.type: Easing.InCubic
                    }
                }
            }

            Rectangle {
                id: playheadDot
                width: 5; height: 5; radius: 2.5
                color: root.pal.accent
                x: (parent.width - 5) * horizon.shownProgress
                anchors.verticalCenter: parent.verticalCenter
                scale: root.playing ? 1.15 : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: 520
                        easing.type: Easing.OutElastic
                        easing.amplitude: 0.12
                        easing.period: 1.4
                    }
                }
            }

            MouseArea {
                id: scrubArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property bool dragging: false

                function seek(x) {
                    if (!root.currentTrack || root.currentTrack.duration <= 0)
                        return;
                    var ratio = Math.max(0, Math.min(1, x / width));
                    root.position = Math.round(ratio * root.currentTrack.duration);
                    if (audio.source.toString() !== "")
                        audio.setPosition(root.position * 1000);
                }

                onPressed: (mouse) => {
                    dragging = true;
                    horizon.scrubbing = true;
                    seek(mouse.x);
                }
                onPositionChanged: (mouse) => {
                    if (dragging) seek(mouse.x);
                }
                onReleased: {
                    dragging = false;
                    horizon.scrubbing = false;
                    horizon.snapping = true;
                    snapTimer.restart();
                }
                onCanceled: {
                    dragging = false;
                    horizon.scrubbing = false;
                    horizon.snapping = true;
                    snapTimer.restart();
                }
            }

            Timer {
                id: snapTimer
                interval: 220
                onTriggered: horizon.snapping = false
            }

            Connections {
                target: root
                function onCurrentTrackChanged() {
                    if (root.playing) returnDotAnimation.restart();
                }
            }
        }

        Item {
            id: views
            anchors.top: horizon.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 56
            anchors.rightMargin: 56
            anchors.topMargin: 8
            anchors.bottomMargin: 40

            LoginView {
                anchors.fill: parent
                opacity: root.view === "login" ? 1 : 0
                visible: opacity > 0.001
                enabled: root.view === "login"
                z: root.view === "login" ? 2 : 1
                transform: Translate { y: (1 - opacity) * 12 }
                Behavior on opacity {
                    NumberAnimation { duration: 460; easing.type: Easing.OutCubic }
                }
                pal: root.pal
                serif: root.serif
                darkTheme: root.theme === "ink"
                onLoggedIn: (nick) => root.handleLoggedIn(nick)
                onGuestEntered: root.view = "home"
                sessionActive: root.loggedIn
                onSessionCleared: root.clearSession()
            }

            HomeView {
                anchors.fill: parent
                opacity: root.view === "home" ? 1 : 0
                visible: opacity > 0.001
                enabled: root.view === "home"
                z: root.view === "home" ? 2 : 1
                transform: Translate { y: (1 - opacity) * 12 }
                Behavior on opacity {
                    NumberAnimation { duration: 460; easing.type: Easing.OutCubic }
                }
                pal: root.pal
                serif: root.serif
                serifLatin: root.serifLatin
                serifDisplay: root.serifDisplay
                tracks: root.tracks
                listTitle: root.listTitle
                listSubtitle: root.listSubtitle
                searchResults: root.searchResults
                searchStatus: root.searchStatus
                section: root.section
                currentTrack: root.currentTrack
                themeName: root.theme
                gridOn: root.gridOn
                onSectionRequested: (name) => root.section = name
                onTrackActivated: (index) => root.playTrack(index)
                onPlayerRequested: root.openPlayer()
                onThemeRequested: (name) => root.theme = name
                onGridRequested: (on) => root.gridOn = on
                onSearchRequested: (query) => root.searchModel(query)
                onPlaylistRequested: (id, title) => root.openPlaylist(id, title)
                onSearchTrackActivated: (index) => root.playSearchResult(index)
                loggedIn: root.loggedIn
                nickname: root.nickname
                likedPlaylistId: root.likedPlaylistId
                onLoginRequested: root.view = "login"
                onLikedRequested: root.loadLiked()
                onSignOutRequested: root.signOut()
                favorites: root.favorites
                history: root.history
                onFavoriteActivated: (index) => root.playFavorite(index)
                onHistoryActivated: (index) => root.playHistory(index)
                onHistoryClearRequested: {
                    core.clearHistory();
                    root.refreshLibrary();
                }
                searchHistory: root.searchHistory
                cacheNote: root.cacheNote
                quality: root.quality
                lyricFollow: root.lyricFollow
                volume: root.volume
                appVersion: root.appVersion
                onQualityRequested: (level) => {
                    root.quality = level;
                    core.setSetting("quality", level);
                }
                onLyricFollowRequested: (on) => {
                    root.lyricFollow = on;
                    core.setSetting("lyricFollow", on ? "1" : "0");
                }
                onVolumeRequested: (value) => root.volume = value
                exportNote: root.exportNote
                onHistoryQueryRequested: (query) => {
                    root.section = "search";
                    root.searchModel(query);
                }
                onSearchClearRequested: {
                    core.clearSearchHistory();
                    root.refreshLibrary();
                }
                onCacheClearRequested: {
                    core.clearCache();
                    root.refreshLibrary();
                }
                onExportRequested: root.exportFavorites()
                accountPlaylists: root.accountPlaylists
                accountNote: root.accountNote
                coverUrl: root.currentCover
                onPlaylistActivated: (id, title) => root.openPlaylist(id, title)
            }

            PlayerView {
                anchors.fill: parent
                opacity: root.view === "player" ? 1 : 0
                visible: opacity > 0.001
                enabled: root.view === "player"
                z: root.view === "player" ? 2 : 1
                transform: Translate { y: (1 - opacity) * 12 }
                Behavior on opacity {
                    NumberAnimation { duration: 460; easing.type: Easing.OutCubic }
                }
                pal: root.pal
                serif: root.serif
                serifLatin: root.serifLatin
                serifDisplay: root.serifDisplay
                track: root.currentTrack
                coverUrl: root.currentCover
                volume: root.volume
                trackNumber: root.currentIndex + 1
                playing: root.playing
                position: root.position
                lyrics: root.lyrics
                playbackNote: root.playbackNote
                favorited: root.currentFavorited
                lyricFollow: root.lyricFollow
                onFavoriteToggled: root.toggleFavorite()
                onVolumeRequested: (value) => root.volume = value
                onTogglePlay: root.togglePlay()
                onNext: root.nextTrack()
                onPrev: root.prevTrack()
                onBack: root.view = "home"
            }
        }

        Shortcut {
            sequence: "Space"
            onActivated: root.togglePlay()
        }
        Shortcut {
            sequence: "Esc"
            onActivated: root.view = root.view === "player" ? "home" : "login"
        }
        Shortcut {
            sequence: "G"
            onActivated: root.gridOn = !root.gridOn
        }
        Shortcut {
            sequence: "T"
            onActivated: root.theme = root.theme === "paper" ? "ink" : "paper"
        }

        // Frameless windows have no server-side resize border.
        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 6
            enabled: root.visibility !== Window.Maximized
            cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.LeftEdge)
        }
        MouseArea {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 6
            enabled: root.visibility !== Window.Maximized
            cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.RightEdge)
        }
        MouseArea {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 6
            enabled: root.visibility !== Window.Maximized
            cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.TopEdge)
        }
        MouseArea {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 6
            enabled: root.visibility !== Window.Maximized
            cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.BottomEdge)
        }
    }

    // A hairline around the client-side window keeps the paper edge legible
    // without the native title-bar colour.
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: root.pal.faint
        border.width: 1
        z: 1000
    }

    component WindowControl: Item {
        id: windowControl
        property string glyph: ""
        property bool danger: false
        signal clicked()
        width: 16; height: 16

        Rectangle {
            anchors.fill: parent
            color: windowHover.containsMouse ? root.pal.ultra : "transparent"
            Behavior on color { ColorAnimation { duration: 160 } }
        }
        Text {
            anchors.centerIn: parent
            text: windowControl.glyph
            color: windowControl.danger && windowHover.containsMouse
                ? root.pal.accent : root.pal.ink3
            font.family: root.serifLatin
            font.pixelSize: 13
            Behavior on color { ColorAnimation { duration: 160 } }
        }
        MouseArea {
            id: windowHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: windowControl.clicked()
        }
    }

    component TopLink: Item {
        id: link
        property string text
        property bool active: false
        signal clicked()
        width: label.width
        height: 16
        Text {
            id: label
            text: link.text
            color: link.active ? root.pal.ink : root.pal.ink2
            font.family: root.serif
            font.pixelSize: 12
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: link.clicked()
        }
    }
}
