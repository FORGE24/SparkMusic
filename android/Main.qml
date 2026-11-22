import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtMultimedia
import "components"

Window {
    id: app
    visible: true
    readonly property real androidWidth: Screen.width
    readonly property real androidHeight: Screen.height
    width: Qt.platform.os === "android" ? androidWidth : (forceLandscape ? 844 : 390)
    height: Qt.platform.os === "android" ? androidHeight : (forceLandscape ? 390 : 844)
    color: pal.canvas
    title: "静听 · STILLE"
    visibility: Qt.platform.os === "android" ? Window.FullScreen : Window.Windowed

    property bool forceLandscape: Qt.application.arguments.indexOf("--landscape") !== -1
    readonly property bool landscape: width > height || forceLandscape
    property string themeMode: "paper"

    readonly property var paper: ({
        canvas: "#F2F1ED", ink: "#141414", secondary: "#77756F",
        faint: "rgba(20,20,20,0.14)", ultra: "rgba(20,20,20,0.06)",
        grid: "rgba(20,20,20,0.065)", accent: "#D93829",
        warm: "#8F4A37", cool: "#55666F", isInk: false,
        serif: "STILLE Song", serifLatin: "Cormorant Garamond"
    })
    readonly property var inkTheme: ({
        canvas: "#111112", ink: "#E8E6E1", secondary: "#9E9C96",
        faint: "rgba(232,230,225,0.14)", ultra: "rgba(232,230,225,0.06)",
        grid: "rgba(232,230,225,0.06)", accent: "#D93829",
        warm: "#C77A62", cool: "#889FA8", isInk: true,
        serif: "STILLE Song", serifLatin: "Cormorant Garamond"
    })
    readonly property var pal: themeMode === "ink" ? inkTheme : paper

    // Live catalogue. All network work goes through the CoreAsync façade; the
    // UI thread only receives JSON signals.
    property var tracks: []              // active playback queue
    property var homeTracks: []          // curated home list
    property var playlistTracks: []      // pushed playlist page
    property var favorites: []
    property var accountPlaylists: []
    property var searchResults: []
    property var lyrics: []
    property string nickname: ""
    property var userUid: 0
    property string likedPlaylistId: ""
    property string accountNote: ""
    property bool loggedIn: false
    property bool desktopAuthConfirmed: false
    property bool busy: false
    property bool autoPlayOnLoad: false
    property string busyText: "同步目录……"
    property string listTitle: "热歌榜"
    property string listSubtitle: "正在连接网易云音乐……"
    property bool playlistOpen: false
    property string playlistTitle: ""
    property string playlistSubtitle: ""
    property string playlistSourceTab: "editions"
    property string searchStatus: ""
    property string searchQuery: ""
    property string playbackNote: ""
    property string currentCover: ""
    property int audioDurationMs: 0
    property int position: 0
    property bool playing: false
    property string qualityLevel: "exhigh"
    property string quality: "HIGH 320KBPS"
    property real volume: 0.68
    property int playlistRequestId: 0
    property int playlistPageRequestId: 0
    property int curatedRequestId: 0
    property int playlistSeq: 0
    property int searchRequestId: 0
    property int searchPending: 0
    property bool scrubbing: false
    property string clockText: Qt.formatTime(new Date(), "hh:mm")

    property string portraitView: "home"
    property string homeTab: "curated"
    property string loginReturnView: "home"
    property string loginReturnTab: "curated"
    property bool showGrid: false
    property bool queueOpen: false
    property bool forceClockMode: false
    property int trackIndex: 0
    property int playModeIndex: 0
    property string expandedTrackId: ""
    property string openEditionId: ""

    readonly property var emptyTrack: ({
        id: "00", title: "静听", artist: "STILLE", album: "ARCHIVE", year: "2026",
        label: "NETEASE", tag: "诗意声景", duration: 0, cover: "",
        favorited: false, note: "正在读取网易云音乐目录。", instrumental: false
    })
    readonly property var currentTrack: tracks.length > 0 && trackIndex >= 0 && trackIndex < tracks.length
        ? tracks[trackIndex] : emptyTrack
    readonly property int activeLyricIndex: activeIndex(lyrics, position)
    readonly property var activeLyric: lyrics.length > 0 ? lyrics[activeLyricIndex] : null
    readonly property var previousLyric: activeLyricIndex > 0 ? lyrics[activeLyricIndex - 1] : null
    readonly property var nextLyric: activeLyricIndex + 1 < lyrics.length ? lyrics[activeLyricIndex + 1] : null
    readonly property int duration: audioDurationMs > 0 ? Math.round(audioDurationMs / 1000) : Math.max(1, currentTrack.duration)
    readonly property real progress: Math.min(1, Math.max(0, position / Math.max(1, duration)))
    readonly property int favoriteCount: favorites.length
    readonly property var favoriteTracks: favorites
    readonly property bool hasPlayback: tracks.length > 0 && trackIndex >= 0
        && trackIndex < tracks.length && String(currentTrack.id) !== "00"
    readonly property bool miniVisible: hasPlayback && !landscape
        && portraitView !== "player" && portraitView !== "login" && portraitView !== "auth"
    readonly property var editions: [
        { id: "3778678", code: "EDITION 01 · 热歌榜", title: "热歌榜", description: "网易云音乐实时热歌榜，按播放热度滚动更新。" },
        { id: "19723756", code: "EDITION 02 · 飙升榜", title: "飙升榜", description: "过去二十四小时播放涨幅最高的曲目。" },
        { id: "2884035", code: "EDITION 03 · 原创榜", title: "原创榜", description: "华语原创音乐人的每周新作与独立发行。" }
    ]

    MediaPlayer {
        id: audio
        audioOutput: AudioOutput {
            id: output
            volume: app.volume
        }
        onPositionChanged: if (!app.scrubbing) app.position = Math.floor(position / 1000)
        onDurationChanged: app.audioDurationMs = duration
        onPlaybackStateChanged: app.playing = playbackState === MediaPlayer.PlayingState
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) app.nextTrack(true);
        }
        onErrorOccurred: {
            if (error !== MediaPlayer.NoError)
                app.playbackNote = "音频输出 · " + errorString;
        }
    }

    Timer {
        interval: 300
        running: app.playing
        repeat: true
        onTriggered: if (!app.scrubbing) app.position = Math.floor(audio.position / 1000)
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: app.clockText = Qt.formatTime(new Date(), "hh:mm")
    }
    Timer {
        id: searchTimer
        interval: 360
        onTriggered: app.runSearch(app.searchQuery)
    }
    Timer {
        id: volumeSave
        interval: 500
        onTriggered: core.setSetting("volume", String(app.volume))
    }

    function padNumber(value) {
        var n = Number(value);
        return n < 10 ? "0" + n : String(n);
    }

    function formatTime(seconds) {
        var value = Math.max(0, Math.floor(seconds));
        var m = Math.floor(value / 60);
        var s = value % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function activeIndex(lines, pos) {
        var active = 0;
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].time <= pos) active = i;
        }
        return active;
    }

    function coverFromSong(song) {
        var album = song.al || song.album || {};
        var url = album.picUrl || album.pic_url || "";
        return String(url).replace(/^http:/, "https:");
    }

    function trackFromSong(song) {
        var artist = "";
        if (song.ar && song.ar.length > 0) artist = song.ar[0].name;
        else if (song.artists && song.artists.length > 0) artist = song.artists[0].name;
        else if (song.artist) artist = song.artist;
        var albumObj = song.al || song.album || {};
        var album = albumObj.name || song.albumName || "";
        var duration = Math.round((song.dt || song.duration || 0) / 1000);
        var id = String(song.id || song.songId || "");
        return {
            id: id,
            title: song.name || song.title || "未命名曲目",
            artist: artist || "未知演奏者",
            shortArtist: artist,
            album: album,
            cover: coverFromSong(song),
            year: "",
            label: "NETEASE",
            tag: "网易云音乐",
            duration: duration,
            favorited: core.isFavorite(Number(id)),
            note: "",
            instrumental: false
        };
    }

    function trackFromStored(track) {
        return {
            id: String(track.id),
            title: track.title || "",
            artist: track.artist || "",
            shortArtist: track.shortArtist || track.artist || "",
            album: track.album || "",
            cover: track.cover || "",
            year: track.year || "",
            label: track.label || "NETEASE",
            tag: track.tag || "收藏",
            duration: Number(track.duration || 0),
            favorited: true,
            note: track.note || "",
            instrumental: false
        };
    }

    function parseLrc(text) {
        var out = [];
        var lines = String(text || "").split("\n");
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

    function loadCurated(id, title) {
        playlistSeq += 1;
        curatedRequestId = playlistSeq;
        busy = true;
        busyText = "读取 " + (title || "策展") + "……";
        listTitle = title || "正在读取";
        listSubtitle = "连接网易云音乐……";
        api.loadPlaylist(curatedRequestId, Number(id), 1000, title || "");
    }

    function onCuratedReady(title, raw) {
        busy = false;
        var parsed = {};
        var songs = [];
        try {
            parsed = JSON.parse(raw);
            var playlist = parsed.playlist || {};
            songs = (playlist.tracks && playlist.tracks.length > 0) ? playlist.tracks : (parsed.songs || []);
        } catch (e) {
            listTitle = "目录读取失败";
            listSubtitle = String(raw).substring(0, 140);
            homeTracks = [];
            return;
        }
        var out = [];
        for (var i = 0; i < songs.length; i++) out.push(trackFromSong(songs[i]));
        homeTracks = out;
        if (out.length > 0) {
            var playlist = parsed.playlist || {};
            listTitle = title || playlist.name || "网易云音乐";
            listSubtitle = out.length + " 首 · " + (playlist.name || "NETEASE");
        } else {
            var code = parsed.code !== undefined ? parsed.code : "?";
            var message = parsed.message || parsed.msg || "";
            listTitle = "该歌单暂无曲目";
            listSubtitle = "code " + code + (message.length > 0 ? " · " + message : "");
        }
        if (autoPlayOnLoad && out.length > 0) {
            autoPlayOnLoad = false;
            playFrom(homeTracks, homeTracks[0], true);
        }
    }

    function openPlaylist(id, title, sourceTab) {
        playlistSourceTab = sourceTab || homeTab;
        playlistOpen = true;
        playlistTracks = [];
        playlistTitle = title || "歌单";
        playlistSubtitle = "连接网易云音乐……";
        playlistSeq += 1;
        playlistPageRequestId = playlistSeq;
        busy = true;
        busyText = "读取 " + playlistTitle + "……";
        api.loadPlaylist(playlistPageRequestId, Number(id), 1000, title || "");
    }

    function onPlaylistPageReady(title, raw) {
        busy = false;
        var parsed = {};
        var songs = [];
        try {
            parsed = JSON.parse(raw);
            var playlist = parsed.playlist || {};
            songs = (playlist.tracks && playlist.tracks.length > 0) ? playlist.tracks : (parsed.songs || []);
        } catch (e) {
            playlistTitle = "歌单读取失败";
            playlistSubtitle = String(raw).substring(0, 140);
            return;
        }
        var out = [];
        for (var i = 0; i < songs.length; i++) out.push(trackFromSong(songs[i]));
        playlistTracks = out;
        var playlist = parsed.playlist || {};
        playlistTitle = title || playlist.name || "歌单";
        playlistSubtitle = out.length + " 首 · " + (playlist.name || "NETEASE");
    }

    function closePlaylist() {
        playlistOpen = false;
        homeTab = playlistSourceTab;
    }

    function onPlaylistReady(requestId, title, raw) {
        if (requestId === curatedRequestId) onCuratedReady(title, raw);
        else if (requestId === playlistPageRequestId) onPlaylistPageReady(title, raw);
    }

    function playFrom(list, track, autoplay) {
        if (!list || list.length === 0 || !track) return;
        var copy = [];
        for (var i = 0; i < list.length; i++) copy.push(list[i]);
        tracks = copy;
        var index = -1;
        for (var j = 0; j < tracks.length; j++) {
            if (String(tracks[j].id) === String(track.id)) { index = j; break; }
        }
        if (index < 0) {
            tracks = [track];
            index = 0;
        }
        playlistOpen = false;
        expandedTrackId = "";
        playTrack(index, autoplay !== false);
    }

    function playTrack(index, autoplay) {
        if (index < 0 || index >= tracks.length) return;
        trackIndex = index;
        position = 0;
        audioDurationMs = 0;
        lyrics = [];
        playbackNote = "";
        playing = false;
        audio.stop();
        audio.source = "";
        var track = tracks[index];
        currentCover = track.cover || "";
        playlistOpen = false;
        portraitView = "player";
        core.recordPlay(JSON.stringify(track));
        api.loadLyric(Number(track.id));
        api.loadSongUrl(Number(track.id), qualityLevel);
        if (autoplay !== false) playing = true;
        if (!track.cover) api.loadSongDetail(Number(track.id));
    }

    function loadDetailFor(track) {
        if (!track || track.cover) return;
        api.loadSongDetail(Number(track.id));
    }

    function nextTrack(auto) {
        if (tracks.length === 0) return;
        var next = (trackIndex + 1) % tracks.length;
        if (playModes[playModeIndex].key === "shuffle") {
            var candidate = trackIndex;
            while (tracks.length > 1 && candidate === trackIndex)
                candidate = Math.floor(Math.random() * tracks.length);
            next = candidate;
        }
        playTrack(next, auto !== true);
    }

    function previousTrack() {
        if (tracks.length === 0) return;
        playTrack((trackIndex - 1 + tracks.length) % tracks.length, true);
    }

    readonly property var playModes: [
        { key: "loop", label: "循环" },
        { key: "single", label: "单曲" },
        { key: "shuffle", label: "漫游" }
    ]
    readonly property var currentMode: playModes[playModeIndex]

    function togglePlay() {
        if (tracks.length === 0) {
            if (portraitView === "player") setView("home");
            return;
        }
        if (audio.source.toString().length === 0) {
            api.loadSongUrl(Number(currentTrack.id), qualityLevel);
            playing = true;
            return;
        }
        if (playing) {
            audio.pause();
            playing = false;
        } else {
            audio.play();
            playing = true;
        }
    }

    function cycleMode() {
        playModeIndex = (playModeIndex + 1) % playModes.length;
    }

    function seek(ratio) {
        var target = Math.round(Math.max(0, Math.min(1, ratio)) * duration);
        position = target;
        if (audio.source.toString().length > 0)
            audio.position = target * 1000;
    }

    function isFavorite(track) {
        if (!track) return false;
        var id = String(track.id);
        for (var i = 0; i < favorites.length; i++) {
            if (String(favorites[i].id) === id) return true;
        }
        return false;
    }

    function toggleFavorite(track) {
        if (!track || String(track.id).length === 0) return;
        if (isFavorite(track)) core.removeFavorite(Number(track.id));
        else core.addFavorite(JSON.stringify(track));
        refreshLibrary();
    }

    function refreshLibrary() {
        try {
            var stored = JSON.parse(core.favorites());
            var out = [];
            for (var i = 0; i < stored.length; i++) out.push(trackFromStored(stored[i]));
            favorites = out;
        } catch (e) {
            favorites = [];
        }
    }

    function filteredTracks() {
        if (searchQuery.trim().length === 0) return homeTracks;
        return searchResults;
    }

    function runSearch(query) {
        if (String(query).trim().length === 0) {
            searchResults = [];
            searchStatus = "";
            return;
        }
        searchRequestId += 1;
        searchPending = searchRequestId;
        api.search(searchRequestId, String(query).trim(), 20);
    }

    function onSearchReady(requestId, query, raw) {
        if (requestId !== searchRequestId) return;
        if (String(query).trim() !== searchQuery.trim()) return;
        try {
            var data = JSON.parse(raw);
            var songs = (data.result || {}).songs || [];
            var out = [];
            for (var i = 0; i < songs.length; i++) out.push(trackFromSong(songs[i]));
            searchResults = out;
            searchStatus = "命中 " + ((data.result || {}).songCount || 0) + " 项";
        } catch (e) {
            searchResults = [];
            searchStatus = "检索失败";
        }
    }

    function loadAccount() {
        api.loadAccount();
    }

    function onAccountReady(raw) {
        var data = {};
        try { data = JSON.parse(raw); } catch (e) {}
        var me = data.account || null;
        if (!me || !me.id) {
            loggedIn = false;
            userUid = 0;
            accountNote = (data.code === 301 || data.code === 200)
                ? "尚未登录 · 网易云会话为空" : "账户接口不可用 · " + (data.code !== undefined ? data.code : "?");
            return;
        }
        loggedIn = true;
        userUid = Number(me.id);
        nickname = (data.profile || {}).nickname || "";
        accountNote = "已连接 · " + nickname;
        core.saveSession();
        api.loadUserPlaylists(userUid);
    }

    function onUserPlaylistsReady(raw) {
        var data = {};
        try { data = JSON.parse(raw); } catch (e) {}
        if (data.code !== 200) {
            accountNote = "账户歌单读取失败 · " + (data.code !== undefined ? data.code : "?");
            return;
        }
        var lists = data.playlist || (data.data || {}).playlist || [];
        var out = [];
        likedPlaylistId = "";
        for (var i = 0; i < lists.length; i++) {
            var p = lists[i];
            var special = Number(p.specialType || 0);
            out.push({ id: String(p.id), name: p.name || "未命名歌单", count: Number(p.trackCount || 0), specialType: special });
            var byName = p.name && String(p.name).indexOf("喜欢的音乐") >= 0;
            if (likedPlaylistId.length === 0 && (special === 5 || byName)) likedPlaylistId = String(p.id);
        }
        accountPlaylists = out;
        if (out.length === 0) accountNote = "该账户没有公开歌单";
    }

    function openDesktopAuth() {
        desktopAuthConfirmed = false;
        portraitView = "auth";
    }

    function confirmDesktopAuth() {
        desktopAuthConfirmed = true;
        portraitView = "player";
    }

    function openLogin() {
        loginReturnView = portraitView;
        loginReturnTab = homeTab;
        portraitView = "login";
        queueOpen = false;
    }

    function finishLogin(accountJson) {
        onAccountReady(accountJson);
        if (!loggedIn) return;
        portraitView = loginReturnView === "login" ? "home" : loginReturnView;
        if (homeTab !== loginReturnTab) homeTab = loginReturnTab;
    }

    function logout() {
        core.clearCookies();
        core.clearSession();
        loggedIn = false;
        nickname = "";
        userUid = 0;
        likedPlaylistId = "";
        accountPlaylists = [];
        accountNote = "已退出登录";
        homeTab = "settings";
        portraitView = "home";
    }

    function loadLiked() {
        if (likedPlaylistId.length > 0) openPlaylist(likedPlaylistId, "我喜欢的音乐", "favorites");
        else accountNote = "未找到「我喜欢的音乐」";
    }

    function setView(view) {
        portraitView = view;
        playlistOpen = false;
        queueOpen = false;
    }

    function goBack() {
        if (queueOpen) { queueOpen = false; return; }
        if (playlistOpen) { closePlaylist(); return; }
        if (portraitView === "player") { portraitView = "home"; return; }
        if (portraitView === "login" || portraitView === "auth") {
            portraitView = loginReturnView === "login" ? "home" : loginReturnView;
            homeTab = loginReturnTab;
            return;
        }
        if (homeTab !== "curated") { homeTab = "curated"; return; }
        Qt.quit();
    }

    function onSongUrlReady(id, raw) {
        if (!currentTrack || String(currentTrack.id) !== String(id)) return;
        try {
            var data = JSON.parse(raw);
            var first = (data.data || [])[0] || {};
            if (first.url) {
                audio.source = first.url;
                audio.play();
                playing = true;
                playbackNote = "";
            } else {
                playbackNote = "该曲目暂无可播放地址（版权或登录限制）";
                playing = false;
            }
        } catch (e) {
            playbackNote = "播放地址解析失败";
        }
    }

    function onLyricReady(id, raw) {
        if (!currentTrack || String(currentTrack.id) !== String(id)) return;
        try {
            var data = JSON.parse(raw);
            lyrics = parseLrc(((data.lrc) || {}).lyric || "");
        } catch (e) {
            lyrics = [];
        }
        if (lyrics.length === 0) {
            lyrics = [{
                time: 0,
                text: currentTrack.instrumental ? "纯器乐 · 静默聆听" : currentTrack.title,
                sub: "暂无歌词 · 网易云音乐"
            }];
        }
    }

    function onSongDetailReady(id, raw) {
        if (!currentTrack || String(currentTrack.id) !== String(id)) return;
        try {
            var songs = JSON.parse(raw).songs || [];
            if (songs.length > 0 && !currentCover) currentCover = coverFromSong(songs[0]);
        } catch (e) {}
    }

    // Persisted UI preferences; session is loaded after the first frame.
    function loadSettings() {
        var storedTheme = core.setting("theme");
        if (storedTheme === "ink" || storedTheme === "paper") themeMode = storedTheme;
        showGrid = (core.setting("grid") || "0") === "1";
        var savedVolume = core.setting("volume");
        if (savedVolume.length > 0) volume = Number(savedVolume);
        var savedQuality = core.setting("quality");
        if (savedQuality.length > 0) {
            qualityLevel = savedQuality;
            quality = savedQuality === "lossless" ? "FLAC 24-BIT / 96KHZ" : "HIGH 320KBPS";
        }
    }

    onThemeModeChanged: core.setSetting("theme", themeMode)
    onShowGridChanged: core.setSetting("grid", showGrid ? "1" : "0")
    onVolumeChanged: volumeSave.restart()

    Component.onCompleted: {
        loadSettings();
        refreshLibrary();
        var saved = core.loadSession();
        if (saved.length > 0) {
            loggedIn = true;
            api.loadAccount();
        } else {
            accountNote = "访客模式 · 可浏览热歌榜与检索";
        }
        loadCurated(3778678, "热歌榜");
    }

    Connections {
        target: api
        function onPlaylistReady(requestId, title, json) { app.onPlaylistReady(requestId, title, json); }
        function onSearchReady(requestId, query, json) { app.onSearchReady(requestId, query, json); }
        function onSongUrlReady(id, json) { app.onSongUrlReady(id, json); }
        function onLyricReady(id, json) { app.onLyricReady(id, json); }
        function onSongDetailReady(id, json) { app.onSongDetailReady(id, json); }
        function onAccountReady(json) { app.onAccountReady(json); }
        function onUserPlaylistsReady(json) { app.onUserPlaylistsReady(json); }
    }

    onSearchQueryChanged: searchTimer.restart()

    // A compact hand-drawn status row; Android runs fullscreen and the paper
    // itself supplies the chrome.
    Item {
        id: statusBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 28

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: app.clockText
            color: app.pal.ink
            opacity: 0.72
            font.family: app.pal.serifLatin
            font.pixelSize: 11
            font.letterSpacing: 0.8
        }

        Canvas {
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            width: 42
            height: 12
            opacity: 0.58
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = app.pal.ink;
                ctx.lineWidth = 0.9;
                for (var i = 0; i < 4; i++) {
                    var x = 1 + i * 3.2;
                    ctx.beginPath(); ctx.moveTo(x, 9 - i * 2); ctx.lineTo(x, 10); ctx.stroke();
                }
                ctx.strokeRect(25.5, 2.5, 12, 7);
                ctx.fillStyle = app.pal.ink;
                ctx.fillRect(27, 4, 8, 4);
                ctx.beginPath(); ctx.moveTo(38.5, 4.5); ctx.lineTo(38.5, 7.5); ctx.stroke();
            }
        }
    }

    Item {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: statusBar.bottom
        anchors.bottom: parent.bottom

        PlayerView {
            anchors.fill: parent
            app: app
            visible: !app.landscape && app.portraitView === "player"
            opacity: visible ? 1 : 0
            enabled: visible
            Behavior on opacity { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
        }
        HomeView {
            anchors.fill: parent
            app: app
            visible: !app.landscape && app.portraitView === "home"
            opacity: visible ? 1 : 0
            enabled: visible
            Behavior on opacity { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
        }
        LoginView {
            objectName: "loginView"
            anchors.fill: parent
            app: app
            visible: !app.landscape && app.portraitView === "login"
            opacity: visible ? 1 : 0
            enabled: visible
            Behavior on opacity { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
        }
        AuthView {
            anchors.fill: parent
            app: app
            visible: !app.landscape && app.portraitView === "auth"
            opacity: visible ? 1 : 0
            enabled: visible
            Behavior on opacity { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
        }
        LandscapeView {
            anchors.fill: parent
            app: app
            visible: app.landscape
            opacity: visible ? 1 : 0
            enabled: visible
            Behavior on opacity { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
        }

        PlaylistPage {
            anchors.fill: parent
            app: app
        }
    }

    MiniPlayer {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        app: app
    }

    GrainOverlay { anchors.fill: parent; themeColors: app.pal; z: 40 }
    GridOverlay {
        anchors.fill: parent
        themeColors: app.pal
        landscape: app.landscape
        visible: app.showGrid
        opacity: visible ? 1 : 0
        z: 50
        Behavior on opacity { NumberAnimation { duration: 420 } }
    }

    // Inline busy acknowledgement; network work is off-thread but the picture
    // should say when a new catalogue is being fetched.
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 18
        anchors.bottomMargin: 16
        width: busyLabel.implicitWidth + 24
        height: 30
        color: app.pal.canvas
        border.color: app.pal.faint
        border.width: 1
        visible: app.busy
        opacity: visible ? 1 : 0
        z: 80
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Text {
            id: busyLabel
            anchors.centerIn: parent
            text: app.busyText
            color: app.pal.secondary
            font.family: app.pal.serifLatin
            font.pixelSize: 9
            font.letterSpacing: 1.4
        }
    }

    Shortcut { sequence: "Space"; onActivated: app.togglePlay() }
    Shortcut { sequence: Qt.Key_Back; onActivated: app.goBack() }
    Shortcut {
        sequence: "Escape"
        onActivated: app.goBack()
    }
    Shortcut { sequence: "G"; onActivated: app.showGrid = !app.showGrid }
    Shortcut { sequence: "T"; onActivated: app.themeMode = app.themeMode === "ink" ? "paper" : "ink" }
}
