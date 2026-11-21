import QtQuick
import QtQuick.Layouts

// View 2 — 音乐主页. Every list here is fed by the real API through Main.qml.
Item {
    id: home
    property var pal
    property string serif
    property string serifLatin
    property var tracks: []
    property string listTitle: ""
    property string listSubtitle: ""
    property var searchResults: []
    property string searchStatus: ""
    property string section: "curated"
    property var currentTrack
    property string coverUrl: ""
    property string themeName: "paper"
    property bool gridOn: false
    property bool loggedIn: false
    property string nickname: ""
    property string likedPlaylistId: ""
    property var favorites: []
    property var history: []
    property var searchHistory: []
    property var accountPlaylists: []
    property string accountNote: ""
    property string cacheNote: ""
    property string exportNote: ""

    signal sectionRequested(string name)
    signal trackActivated(int index)
    signal searchTrackActivated(int index)
    signal themeRequested(string name)
    signal gridRequested(bool on)
    signal searchRequested(string query)
    signal playlistRequested(string id, string title)
    signal loginRequested()
    signal likedRequested()
    signal signOutRequested()
    signal favoriteActivated(int index)
    signal historyActivated(int index)
    signal historyClearRequested()
    signal historyQueryRequested(string query)
    signal searchClearRequested()
    signal cacheClearRequested()
    signal exportRequested()
    signal playlistActivated(string id, string title)

    readonly property var editions: [
        { id: "3778678", title: "热歌榜", date: "DAILY", desc: "网易云音乐每日更新的热播单曲" },
        { id: "19723756", title: "飙升榜", date: "HOURLY", desc: "按播放增速实时滚动的上升曲目" },
        { id: "2884035", title: "原创榜", date: "WEEKLY", desc: "独立音乐人与原创作品周榜" }
    ]

    // Section tabs are ordered; the next section enters from the direction it
    // lives in, so moving 今日策展 -> 系统设置 feels like travelling forward.
    readonly property var sectionOrder: [
        "curated", "favorites", "collections", "search", "settings"
    ]
    property string previousSection: ""

    Component.onCompleted: previousSection = section
    onSectionChanged: {
        var from = sectionOrder.indexOf(previousSection);
        var to = sectionOrder.indexOf(section);
        if (from === to) return;
        var direction = to >= from ? 1 : -1;
        previousSection = section;
        if (section === "curated")
            curatedList.positionViewAtBeginning();
        else
            homeScroll.contentY = 0;
        centerStage.stageShift = direction * 22;
        centerStage.opacity = 0;
        sectionTransition.restart();
    }

    ParallelAnimation {
        id: sectionTransition
        NumberAnimation {
            target: centerStage
            property: "opacity"
            to: 1
            duration: 360
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: centerStage
            property: "stageShift"
            to: 0
            duration: 440
            easing.type: Easing.OutCubic
        }
    }

    Row {
        anchors.fill: parent
        spacing: 40

        // ------------------------------------------------------ left index
        Column {
            width: parent.width * 0.22
            spacing: 42

            Column {
                width: parent.width
                spacing: 12

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: "INDEX / 目录"
                    color: home.pal.ink3
                    font.family: home.serif
                    font.pixelSize: 10
                    font.letterSpacing: 2.2
                }

                Repeater {
                    model: [
                        { key: "curated", latin: "Curated", zh: "今日策展" },
                        { key: "favorites", latin: "Private", zh: "收藏夹" },
                        { key: "collections", latin: "Editions", zh: "策展辑" },
                        { key: "search", latin: "Search", zh: "检索" },
                        { key: "settings", latin: "System", zh: "系统设置" }
                    ]
                    SwissButton {
                        width: parent.width
                        pal: home.pal; serif: home.serif
                        latin: modelData.latin
                        zh: modelData.zh
                        active: home.section === modelData.key
                        onClicked: home.sectionRequested(modelData.key)
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 20
                visible: home.section !== "settings"
                SwissButton {
                    width: parent.width
                    pal: home.pal; serif: home.serif
                    latin: "Player"; zh: "进入播放室"
                    zhSize: 13
                    onClicked: home.trackActivated(Math.max(0, home.indexOf(home.currentTrack)))
                }
                SwissButton {
                    width: parent.width
                    pal: home.pal; serif: home.serif
                    latin: "Sign out"; zh: "退出聆听室"
                    zhSize: 13
                    onClicked: home.signOutRequested()
                }
            }

            Column {
                width: parent.width
                spacing: 16
                visible: home.section === "settings"

                SwissButton {
                    width: parent.width
                    pal: home.pal; serif: home.serif
                    latin: "Cache"; zh: "清除缓存"
                    zhSize: 13
                    onClicked: home.cacheClearRequested()
                }
                SwissButton {
                    width: parent.width
                    pal: home.pal; serif: home.serif
                    latin: "Export"; zh: "导出收藏 M3U8"
                    zhSize: 13
                    onClicked: home.exportRequested()
                }
                SwissButton {
                    width: parent.width
                    pal: home.pal; serif: home.serif
                    latin: "Sign out"; zh: "退出聆听室"
                    zhSize: 13
                    onClicked: home.signOutRequested()
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: home.cacheNote
                    color: home.pal.ink3
                    font.family: home.serif
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    visible: home.exportNote.length > 0
                    text: home.exportNote
                    color: home.pal.ink3
                    font.family: home.serif
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }
        }

        // -------------------------------------------------- centre column
        Item {
            id: centerStage
            width: parent.width * 0.52
            height: parent.height
            property real stageShift: 0
            transform: Translate { x: centerStage.stageShift }

            // The curated/account track list is the only unbounded list, so it
            // gets a real ListView (virtualized rows) instead of a Repeater.
            ListView {
                id: curatedList
                anchors.fill: parent
                visible: home.section === "curated"
                clip: true
                model: home.tracks
                spacing: 0
                cacheBuffer: 1400
                headerPositioning: ListView.InlineHeader
                verticalLayoutDirection: ListView.TopToBottom
                boundsBehavior: Flickable.StopAtBounds

                header: Column {
                    id: curatedHeader
                    width: curatedList.width
                    spacing: 22

                    Text {
                        text: "01 / 卷首策展 · FEATURED ARCHIVE"
                        color: home.pal.ink3
                        font.family: home.serifLatin
                        font.pixelSize: 10
                        font.letterSpacing: 1.9
                    }
                    Text {
                        width: parent.width
                        text: home.listTitle
                        color: home.pal.ink
                        font.family: home.serif
                        font.pixelSize: 44
                        font.weight: Font.ExtraLight
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        width: parent.width
                        text: home.listSubtitle
                        color: home.pal.ink2
                        font.family: home.serif
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                    Item { width: 1; height: 8 }
                }

                // Qt's ListView keeps contentY at the first header height when
                // the header's implicit height grows after fonts/layout settle,
                // which hides the title above the viewport. Re-anchor to the
                // real top whenever the header height changes.
                Connections {
                    target: curatedList.headerItem
                    function onHeightChanged() {
                        Qt.callLater(curatedList.positionViewAtBeginning);
                    }
                }

                delegate: TrackRow {
                    width: curatedList.width
                    pal: home.pal; serif: home.serif
                    track: modelData
                    number: index + 1
                    appearDelay: Math.min(index * 8, 180)
                    current: home.currentTrack && home.currentTrack.id === modelData.id
                    onActivated: home.trackActivated(index)
                }

                footer: Item {
                    width: curatedList.width
                    height: 40
                }
            }

            Flickable {
                id: homeScroll
                anchors.fill: parent
                visible: home.section !== "curated"
                clip: true
                contentHeight: content.implicitHeight + 40
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: content
                    width: parent.width
                    spacing: 26

                    // ---------------------------------------- favourites + history
                    Column {
                        width: parent.width
                        spacing: 22
                        visible: home.section === "favorites"

                        Text {
                            text: "02 / 收藏夹 · PRIVATE COLLECTION"
                            color: home.pal.ink3
                            font.family: home.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 1.9
                        }
                        Text {
                            text: "私人藏音"
                            color: home.pal.ink
                            font.family: home.serif
                            font.pixelSize: 44
                            font.weight: Font.ExtraLight
                        }
                        // ---- account playlists (needs a session) ----
                        Column {
                            width: parent.width
                            spacing: 8
                            visible: home.loggedIn

                            Text {
                                text: "账户歌单 · ACCOUNT"
                                color: home.pal.ink3
                                font.family: home.serifLatin
                                font.pixelSize: 9
                                font.letterSpacing: 1.8
                            }

                            Repeater {
                                model: home.accountPlaylists
                                Item {
                                    width: content.width
                                    height: 38
                                    Rectangle {
                                        anchors.fill: parent
                                        color: accountHover.containsMouse ? home.pal.ultra : "transparent"
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width; height: 1
                                        color: home.pal.faint
                                    }
                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        color: modelData.specialType === 5 ? home.pal.accent : home.pal.ink2
                                        font.family: home.serif
                                        font.pixelSize: 13
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.count + " 首"
                                        color: home.pal.ink3
                                        font.family: home.serif
                                        font.pixelSize: 10
                                    }
                                    MouseArea {
                                        id: accountHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: home.playlistActivated(modelData.id, modelData.name)
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                visible: home.accountPlaylists.length === 0
                                text: home.accountNote.length > 0 ? home.accountNote : "正在读取账户歌单…"
                                color: home.pal.ink3
                                font.family: home.serif
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }

                        Text {
                            visible: !home.loggedIn
                            width: parent.width
                            text: "登录后可读取「我喜欢的音乐」与全部账户歌单；"
                                  + "未登录时这里只显示本地收藏。"
                            color: home.pal.ink3
                            font.family: home.serif
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: "本地收藏 · LOCAL"
                            color: home.pal.ink3
                            font.family: home.serifLatin
                            font.pixelSize: 9
                            font.letterSpacing: 1.8
                        }

                        Text {
                            width: parent.width
                            text: home.favorites.length > 0
                                ? ("共 " + home.favorites.length + " 首 · 存于本地 sparkmusic.db")
                                : "还没有本地收藏。播放任意曲目后点击「收藏」即可写入。"
                            color: home.pal.ink2
                            font.family: home.serif
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width
                            Repeater {
                                model: home.favorites
                                TrackRow {
                                    width: content.width
                                    pal: home.pal; serif: home.serif
                                    track: modelData
                                    number: index + 1
                                    appearDelay: Math.min(index * 14, 280)
                                    current: home.currentTrack && home.currentTrack.id === modelData.id
                                    onActivated: home.favoriteActivated(index)
                                }
                            }
                        }

                        Item { width: 1; height: 14 }

                        Row {
                            width: parent.width
                            Text {
                                text: "最近播放 · RECENT"
                                color: home.pal.ink3
                                font.family: home.serifLatin
                                font.pixelSize: 10
                                font.letterSpacing: 1.9
                            }
                            Item { width: parent.width - 260; height: 1 }
                            Text {
                                visible: home.history.length > 0
                                text: "清除历史"
                                color: home.pal.ink3
                                font.family: home.serif
                                font.pixelSize: 11
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: home.historyClearRequested()
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            Repeater {
                                model: home.history.slice(0, 10)
                                TrackRow {
                                    width: content.width
                                    pal: home.pal; serif: home.serif
                                    track: modelData
                                    number: index + 1
                                    appearDelay: Math.min(index * 14, 280)
                                    current: false
                                    onActivated: home.historyActivated(index)
                                }
                            }
                        }
                    }

                    // ---------------------------------------- collections (real playlists)
                    Column {
                        width: parent.width
                        spacing: 22
                        visible: home.section === "collections"

                        Text {
                            text: "03 / 策展辑 · ARCHITECTURAL EDITIONS"
                            color: home.pal.ink3
                            font.family: home.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 1.9
                        }
                        Text {
                            text: "主题声景辑录"
                            color: home.pal.ink
                            font.family: home.serif
                            font.pixelSize: 44
                            font.weight: Font.ExtraLight
                        }
                        Text {
                            text: "网易云音乐官方榜单，点击即载入真实曲目"
                            color: home.pal.ink2
                            font.family: home.serif
                            font.pixelSize: 12
                        }

                        Repeater {
                            model: home.editions
                            Item {
                                width: content.width
                                height: 74
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width; height: 1
                                    color: home.pal.faint
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    text: modelData.title
                                    color: home.pal.ink
                                    font.family: home.serif
                                    font.pixelSize: 19
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    text: modelData.date
                                    color: home.pal.ink3
                                    font.family: home.serifLatin
                                    font.pixelSize: 10
                                    font.letterSpacing: 1.4
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 16
                                    text: modelData.desc
                                    color: home.pal.ink2
                                    font.family: home.serif
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: home.playlistRequested(modelData.id, modelData.title)
                                }
                            }
                        }
                    }

                    // ---------------------------------------- search (real API)
                    Column {
                        width: parent.width
                        spacing: 20
                        visible: home.section === "search"

                        Text {
                            text: "04 / 检索 · DIRECT INDEX QUERY"
                            color: home.pal.ink3
                            font.family: home.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 1.9
                        }

                        Item {
                            width: parent.width
                            height: 56
                            TextInput {
                                id: searchInput
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                color: home.pal.ink
                                selectionColor: home.pal.accent
                                font.family: home.serif
                                font.pixelSize: 26
                                clip: true
                                onTextChanged: searchTimer.restart()
                                Keys.onReturnPressed: home.searchRequested(text)
                            }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: home.pal.faint
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 12
                                visible: searchInput.text.length === 0
                                text: "键入曲名、演奏者、专辑或厂牌……"
                                color: home.pal.ink3
                                font.family: home.serif
                                font.pixelSize: 18
                            }
                        }

                        Text {
                            text: home.searchStatus
                            color: home.pal.ink3
                            font.family: home.serif
                            font.pixelSize: 11
                        }

                        Row {
                            width: parent.width
                            visible: home.searchHistory.length > 0
                            Text {
                                text: "最近检索 · RECENT"
                                color: home.pal.ink3
                                font.family: home.serifLatin
                                font.pixelSize: 10
                                font.letterSpacing: 1.8
                            }
                            Item { width: parent.width - 250; height: 1 }
                            Text {
                                text: "清除"
                                color: home.pal.ink3
                                font.family: home.serif
                                font.pixelSize: 11
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: home.searchClearRequested()
                                }
                            }
                        }

                        Flow {
                            width: parent.width
                            spacing: 18
                            visible: home.searchHistory.length > 0
                            Repeater {
                                model: home.searchHistory
                                Text {
                                    text: modelData
                                    color: home.pal.ink2
                                    font.family: home.serif
                                    font.pixelSize: 12
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: home.historyQueryRequested(modelData)
                                    }
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            Repeater {
                                model: home.searchResults
                                TrackRow {
                                    width: content.width
                                    pal: home.pal; serif: home.serif
                                    track: modelData
                                    number: index + 1
                                    appearDelay: Math.min(index * 14, 280)
                                    current: false
                                    onActivated: home.searchTrackActivated(index)
                                }
                            }
                        }
                    }

                    // ---------------------------------------- settings
                    Column {
                        width: parent.width
                        spacing: 22
                        visible: home.section === "settings"

                        Text {
                            text: "05 / 系统设置 · SYSTEM LEDGER"
                            color: home.pal.ink3
                            font.family: home.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 1.9
                        }
                        Text {
                            text: "器物与尺度"
                            color: home.pal.ink
                            font.family: home.serif
                            font.pixelSize: 44
                            font.weight: Font.ExtraLight
                        }
                        Text {
                            text: "无冗余控件 · 所有变更实时作用于声学引擎与网格画布"
                            color: home.pal.ink2
                            font.family: home.serif
                            font.pixelSize: 12
                        }

                        Repeater {
                            model: [
                                { key: "纸墨主题", options: ["宣纸白", "玄墨黑"] },
                                { key: "建筑网格", options: ["显示", "隐藏"] }
                            ]
                            Item {
                                width: content.width
                                height: 52
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width; height: 1
                                    color: home.pal.faint
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.key
                                    color: home.pal.ink2
                                    font.family: home.serif
                                    font.pixelSize: 13
                                }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 14
                                    Repeater {
                                        model: modelData.options
                                        Text {
                                            text: modelData
                                            color: home.optionActive(modelData) ? home.pal.ink : home.pal.ink3
                                            font.family: home.serif
                                            font.pixelSize: 12
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: home.optionChosen(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ----------------------------------------------------- right placard
        Column {
            width: parent.width * 0.22
            spacing: 36

            Item {
                width: 88; height: 88

                Rectangle {
                    anchors.fill: parent
                    border.color: home.pal.faint
                    border.width: 1
                    color: "transparent"
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: home.pal.canvas
                    clip: true
                    Image {
                        id: homeCover
                        anchors.fill: parent
                        source: home.coverUrl
                        sourceSize.width: 176
                        sourceSize.height: 176
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        visible: status === Image.Ready
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: "transparent"
                    border.color: home.pal.ink2
                    border.width: 1
                    opacity: 0.24
                }

                Rectangle {
                    width: 52; height: 52; radius: 26
                    anchors.centerIn: parent
                    color: "transparent"
                    border.color: home.pal.ink2
                    border.width: 1
                    visible: homeCover.status !== Image.Ready
                }
                Rectangle {
                    width: 4; height: 4
                    anchors.centerIn: parent
                    color: home.pal.accent
                    visible: homeCover.status !== Image.Ready
                }
            }

            Column {
                width: parent.width
                spacing: 5
                Text {
                    text: "PLACARD · NO. 01"
                    color: home.pal.ink3
                    font.family: home.serifLatin
                    font.pixelSize: 9
                    font.letterSpacing: 1.7
                }
                Text {
                    width: parent.width
                    text: home.currentTrack ? home.currentTrack.title : ""
                    color: home.pal.ink
                    font.family: home.serif
                    font.pixelSize: 20
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: home.currentTrack ? home.currentTrack.artist : ""
                    color: home.pal.ink2
                    font.family: home.serif
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: home.currentTrack ? home.currentTrack.album : ""
                    color: home.pal.ink3
                    font.family: home.serif
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }

            Column {
                width: parent.width
                spacing: 8
                Repeater {
                    model: [
                        ["来源", "网易云音乐"],
                        ["曲目", home.tracks.length + " 首"],
                        ["规格", "FLAC 24-bit · 96kHz"]
                    ]
                    Row {
                        width: parent.width
                        spacing: 12
                        Text {
                            text: modelData[0]
                            color: home.pal.ink3
                            font.family: home.serif
                            font.pixelSize: 10
                        }
                        Text {
                            text: modelData[1]
                            color: home.pal.ink2
                            font.family: home.serif
                            font.pixelSize: 10
                        }
                    }
                }
                Text {
                    width: parent.width
                    text: "所有曲目、专辑与播放地址均来自网易云音乐接口，"
                          + "以 eapi 信封请求，核心库动态链接。"
                    color: home.pal.ink3
                    font.family: home.serif
                    font.pixelSize: 11
                    lineHeight: 1.9
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Timer {
        id: searchTimer
        interval: 450
        onTriggered: home.searchRequested(searchInput.text)
    }

    function indexOf(track) {
        if (!track) return 0;
        for (var i = 0; i < tracks.length; i++)
            if (tracks[i].id === track.id) return i;
        return 0;
    }

    function optionActive(option) {
        if (option === "宣纸白") return themeName === "paper";
        if (option === "玄墨黑") return themeName === "ink";
        if (option === "显示") return gridOn;
        if (option === "隐藏") return !gridOn;
        return true;
    }

    function optionChosen(option) {
        if (option === "宣纸白") themeRequested("paper");
        else if (option === "玄墨黑") themeRequested("ink");
        else if (option === "显示") gridRequested(true);
        else if (option === "隐藏") gridRequested(false);
    }
}
