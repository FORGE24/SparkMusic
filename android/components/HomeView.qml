import QtQuick

Item {
    id: root
    property var app
    readonly property var themeColors: app.pal
    readonly property var tabs: [
        { key: "curated", label: "策展" },
        { key: "favorites", label: "收藏" },
        { key: "editions", label: "辑" },
        { key: "search", label: "检索" },
        { key: "settings", label: "设置" }
    ]

    Item {
        id: nav
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        height: 86

        LogoLockup {
            id: brand
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 1
            app: root.app
            suffix: "ARCHIVE / 目录"
            markSize: 21
            wordSize: 12
            suffixSize: 9
        }

        Row {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            spacing: 8

            Repeater {
                model: root.tabs
                delegate: Item {
                    width: tabButton.width
                    height: 44
                    StilleTextButton {
                        id: tabButton
                        themeColors: root.themeColors
                        text: modelData.label
                        fontSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        active: app.homeTab === modelData.key
                        muted: app.homeTab !== modelData.key
                        onClicked: app.homeTab = modelData.key
                    }
                    Rectangle {
                        width: app.homeTab === modelData.key ? 8 : 0
                        height: 1
                        color: root.themeColors.ink
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        StilleTextButton {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            themeColors: root.themeColors
            text: app.loggedIn
                ? (app.nickname.length > 6 ? app.nickname.substring(0, 6) + "…" : app.nickname)
                : "未登录"
            fontSize: 11
            horizontalAlignment: Text.AlignRight
            muted: !app.loggedIn
            onClicked: {
                if (app.loggedIn) app.homeTab = "settings";
                else app.openLogin();
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: root.themeColors.faint
        }
    }

    Connections {
        target: app
        function onHomeTabChanged() { scroll.contentY = 0; }
        function onPortraitViewChanged() { if (app.portraitView === "home") scroll.contentY = 0; }
    }

    Flickable {
        id: scroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: nav.bottom
        anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: paneColumn.height + 76
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: paneColumn
            width: scroll.width

            // ---------------------------------------------------------- curated
            Item {
                width: parent.width
                visible: app.homeTab === "curated"
                height: visible ? curatedColumn.height : 0

                Column {
                    id: curatedColumn
                    x: 24
                    width: parent.width - 48

                    Column {
                        width: parent.width
                        spacing: 0
                        topPadding: 22
                        bottomPadding: 18
                        Text {
                            text: "NO. 11 / 2026 · CURATED INDEX"
                            color: root.themeColors.secondary
                            font.family: root.themeColors.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 2.0
                            bottomPadding: 10
                        }
                        Text {
                            width: parent.width
                            text: app.listTitle
                            color: root.themeColors.ink
                            font.family: root.themeColors.serif
                            font.pixelSize: 24
                            font.weight: Font.ExtraLight
                            font.letterSpacing: 2.2
                            lineHeight: 1.35
                            wrapMode: Text.WordWrap
                            bottomPadding: 8
                        }
                        Text {
                            width: parent.width
                            text: app.listSubtitle
                            color: root.themeColors.secondary
                            font.family: root.themeColors.serif
                            font.pixelSize: 12
                            font.letterSpacing: 0.8
                            lineHeight: 1.6
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: root.themeColors.faint }

                    Repeater {
                        model: app.homeTracks
                        delegate: TrackRow {
                            width: curatedColumn.width
                            app: root.app
                            track: modelData
                            ordinal: index
                            playbackContext: app.homeTracks
                            themeColors: root.themeColors
                            onPlayRequested: app.playFrom(app.homeTracks, modelData)
                        }
                    }

                    Item { width: 1; height: 26 }
                }
            }

            // ------------------------------------------------------- favorites
            Item {
                width: parent.width
                visible: app.homeTab === "favorites"
                height: visible ? favoritesColumn.height : 0

                Column {
                    id: favoritesColumn
                    x: 24
                    width: parent.width - 48

                    Column {
                        width: parent.width
                        topPadding: 22
                        bottomPadding: 18
                        spacing: 0
                        Text {
                            text: "PRIVATE COLLECTION · " + app.padNumber(app.favoriteCount) + " 首"
                            color: root.themeColors.secondary
                            font.family: root.themeColors.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 2.0
                            bottomPadding: 10
                        }
                        Text {
                            text: "私人藏音"
                            color: root.themeColors.ink
                            font.family: root.themeColors.serif
                            font.pixelSize: 25
                            font.weight: Font.ExtraLight
                            font.letterSpacing: 2.2
                            bottomPadding: 8
                        }
                        Text {
                            width: parent.width
                            text: "与播放室实时同步的静默曲目单。"
                            color: root.themeColors.secondary
                            font.family: root.themeColors.serif
                            font.pixelSize: 12
                            font.letterSpacing: 0.8
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: root.themeColors.faint }

                    Item {
                        width: parent.width
                        height: 54
                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 150
                            text: app.likedPlaylistId.length > 0
                                ? "网易云 · 我喜欢的音乐"
                                : (app.loggedIn ? "正在读取账户歌单…" : "登录网易云以读取「我喜欢的音乐」")
                            color: root.themeColors.ink
                            font.family: root.themeColors.serif
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        StilleTextButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            themeColors: root.themeColors
                            fontSize: 10
                            text: app.loggedIn ? "载入 →" : "登录 →"
                            horizontalAlignment: Text.AlignRight
                            onClicked: {
                                if (app.loggedIn) app.loadLiked();
                                else app.openLogin();
                            }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.themeColors.ultra }
                    }

                    Repeater {
                        model: app.favoriteTracks
                        delegate: TrackRow {
                            width: favoritesColumn.width
                            app: root.app
                            track: modelData
                            ordinal: index
                            playbackContext: app.favoriteTracks
                            themeColors: root.themeColors
                            onPlayRequested: app.playFrom(app.favoriteTracks, modelData)
                        }
                    }

                    Text {
                        visible: app.favoriteTracks.length === 0
                        width: parent.width
                        topPadding: 54
                        text: "此处尚无藏音。\n轻触任意曲目的「收藏」，即会写入这册静默目录。"
                        color: root.themeColors.secondary
                        font.family: root.themeColors.serif
                        font.pixelSize: 13
                        lineHeight: 1.9
                        wrapMode: Text.WordWrap
                    }
                    Item { width: 1; height: 26 }
                }
            }

            // --------------------------------------------------------- editions
            Item {
                width: parent.width
                visible: app.homeTab === "editions"
                height: visible ? editionsColumn.height : 0

                Column {
                    id: editionsColumn
                    x: 24
                    width: parent.width - 48

                    Column {
                        width: parent.width
                        topPadding: 22
                        bottomPadding: 18
                        spacing: 0
                        Text {
                            text: "EDITIONS · 网易云歌单"
                            color: root.themeColors.secondary
                            font.family: root.themeColors.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 2.0
                            bottomPadding: 10
                        }
                        Text {
                            text: "主题声景辑录"
                            color: root.themeColors.ink
                            font.family: root.themeColors.serif
                            font.pixelSize: 25
                            font.weight: Font.ExtraLight
                            font.letterSpacing: 2.2
                            bottomPadding: 8
                        }
                        Text {
                            width: parent.width
                            text: "点选任一榜单，实时读取网易云音乐歌单与完整曲目。"
                            color: root.themeColors.secondary
                            font.family: root.themeColors.serif
                            font.pixelSize: 12
                            font.letterSpacing: 0.8
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: root.themeColors.faint }

                    Repeater {
                        model: app.editions
                        delegate: Item {
                            id: editionItem
                            width: editionsColumn.width
                            height: 86
                            property var edition: modelData

                            Item {
                                width: parent.width
                                height: parent.height
                                Text {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.topMargin: 14
                                    text: editionItem.edition.code
                                    color: root.themeColors.secondary
                                    font.family: root.themeColors.serifLatin
                                    font.pixelSize: 9
                                    font.letterSpacing: 1.5
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 14
                                    text: editionItem.edition.title
                                    color: root.themeColors.ink
                                    font.family: root.themeColors.serif
                                    font.pixelSize: 17
                                    font.weight: Font.Normal
                                    font.letterSpacing: 1.4
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 100
                                    anchors.right: loadHint.left
                                    anchors.rightMargin: 12
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 18
                                    text: editionItem.edition.description
                                    color: root.themeColors.secondary
                                    font.family: root.themeColors.serif
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                                Text {
                                    id: loadHint
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 14
                                    text: "载入 →"
                                    color: root.themeColors.secondary
                                    font.family: root.themeColors.serif
                                    font.pixelSize: 10
                                    font.letterSpacing: 1.2
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: app.openPlaylist(editionItem.edition.id, editionItem.edition.title, "editions")
                            }
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.themeColors.ultra }
                        }
                    }

                    Item {
                        width: parent.width
                        height: app.accountPlaylists.length > 0 ? 58 : 0
                        visible: app.accountPlaylists.length > 0
                        Text {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 12
                            text: "账户歌单 · MY PLAYLISTS"
                            color: root.themeColors.secondary
                            font.family: root.themeColors.serifLatin
                            font.pixelSize: 9
                            font.letterSpacing: 1.8
                        }
                    }

                    Repeater {
                        model: app.accountPlaylists
                        delegate: Item {
                            width: editionsColumn.width
                            height: 52
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 76
                                text: modelData.name
                                color: root.themeColors.ink
                                font.family: root.themeColors.serif
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.count + " 首 →"
                                color: root.themeColors.secondary
                                font.family: root.themeColors.serif
                                font.pixelSize: 10
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: app.openPlaylist(modelData.id, modelData.name, "editions")
                            }
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.themeColors.ultra }
                        }
                    }
                    Item { width: 1; height: 26 }
                }
            }

            // ----------------------------------------------------------- search
            Item {
                width: parent.width
                visible: app.homeTab === "search"
                height: visible ? searchColumn.height : 0

                Column {
                    id: searchColumn
                    x: 24
                    width: parent.width - 48

                    Item {
                        width: parent.width
                        height: 74

                        TextInput {
                            id: searchInput
                            anchors.left: parent.left
                            anchors.right: countText.left
                            anchors.rightMargin: 16
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 10
                            height: 30
                            text: app.searchQuery
                            color: root.themeColors.ink
                            selectionColor: root.themeColors.accent
                            selectedTextColor: root.themeColors.canvas
                            font.family: root.themeColors.serif
                            font.pixelSize: 16
                            font.letterSpacing: 1.0
                            selectByMouse: true
                            clip: true
                            onTextChanged: app.searchQuery = text
                            onAccepted: searchInput.focus = false
                        }
                        Text {
                            anchors.left: searchInput.left
                            anchors.verticalCenter: searchInput.verticalCenter
                            visible: searchInput.text.length === 0
                            text: "键入曲名、演奏者或风格……"
                            color: root.themeColors.secondary
                            opacity: 0.55
                            font.family: root.themeColors.serif
                            font.pixelSize: 14
                            font.letterSpacing: 0.8
                        }
                        Text {
                            id: countText
                            anchors.right: parent.right
                            anchors.verticalCenter: searchInput.verticalCenter
                            text: app.padNumber(app.filteredTracks().length) + " 项"
                            color: root.themeColors.secondary
                            font.family: root.themeColors.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 1.2
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: searchInput.activeFocus ? root.themeColors.ink : root.themeColors.faint
                            Behavior on color { ColorAnimation { duration: 220 } }
                        }
                    }

                    Repeater {
                        model: app.filteredTracks()
                        delegate: TrackRow {
                            width: searchColumn.width
                            app: root.app
                            track: modelData
                            ordinal: index
                            playbackContext: app.filteredTracks()
                            themeColors: root.themeColors
                            onPlayRequested: app.playFrom(app.filteredTracks(), modelData)
                        }
                    }

                    Text {
                        visible: app.filteredTracks().length === 0
                        width: parent.width
                        topPadding: 52
                        text: "没有找到相应的声景。\n换一个更短的词，或回到策展目录。"
                        color: root.themeColors.secondary
                        font.family: root.themeColors.serif
                        font.pixelSize: 13
                        lineHeight: 1.9
                        wrapMode: Text.WordWrap
                    }
                    Item { width: 1; height: 26 }
                }
            }

            // --------------------------------------------------------- settings
            Item {
                width: parent.width
                visible: app.homeTab === "settings"
                height: visible ? settingsColumn.height : 0

                Column {
                    id: settingsColumn
                    x: 24
                    width: parent.width - 48

                    Column {
                        width: parent.width
                        topPadding: 22
                        bottomPadding: 18
                        spacing: 0
                        Text {
                            text: "SYSTEM LEDGER · 器物与尺度"
                            color: root.themeColors.secondary
                            font.family: root.themeColors.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 2.0
                            bottomPadding: 10
                        }
                        Text {
                            text: "系统设置"
                            color: root.themeColors.ink
                            font.family: root.themeColors.serif
                            font.pixelSize: 25
                            font.weight: Font.ExtraLight
                            font.letterSpacing: 2.2
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: root.themeColors.faint }

                    Item {
                        width: parent.width
                        height: 66
                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                text: app.loggedIn ? ("网易云 · " + app.nickname) : "访客 · 未登录"
                                color: root.themeColors.ink
                                font.family: root.themeColors.serif
                                font.pixelSize: 14
                                font.letterSpacing: 1.0
                            }
                            Text {
                                text: app.accountNote
                                color: root.themeColors.secondary
                                font.family: root.themeColors.serif
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: 240
                            }
                        }
                        StilleTextButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            themeColors: root.themeColors
                            fontSize: 10
                            text: app.loggedIn ? "退出登录" : "登录 →"
                            horizontalAlignment: Text.AlignRight
                            muted: true
                            onClicked: {
                                if (app.loggedIn) app.logout();
                                else app.openLogin();
                            }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: root.themeColors.ultra }

                    Item {
                        width: parent.width
                        height: 52
                        Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "纸墨主题"; color: root.themeColors.ink; font.family: root.themeColors.serif; font.pixelSize: 13; font.letterSpacing: 1.2 }
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            StilleTextButton { themeColors: root.themeColors; fontSize: 12; text: "宣纸"; activeRule: true; horizontalAlignment: Text.AlignRight; active: app.themeMode === "paper"; onClicked: app.themeMode = "paper" }
                            Text { text: " / "; color: root.themeColors.faint; font.family: root.themeColors.serifLatin; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                            StilleTextButton { themeColors: root.themeColors; fontSize: 12; text: "玄墨"; activeRule: true; horizontalAlignment: Text.AlignRight; active: app.themeMode === "ink"; onClicked: app.themeMode = "ink" }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: root.themeColors.ultra }

                    Item {
                        width: parent.width
                        height: 52
                        Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "辅助网格"; color: root.themeColors.ink; font.family: root.themeColors.serif; font.pixelSize: 13; font.letterSpacing: 1.2 }
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            StilleTextButton { themeColors: root.themeColors; fontSize: 12; text: "显示"; activeRule: true; horizontalAlignment: Text.AlignRight; active: app.showGrid; onClicked: app.showGrid = true }
                            Text { text: " / "; color: root.themeColors.faint; font.family: root.themeColors.serifLatin; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                            StilleTextButton { themeColors: root.themeColors; fontSize: 12; text: "隐藏"; activeRule: true; horizontalAlignment: Text.AlignRight; active: !app.showGrid; onClicked: app.showGrid = false }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: root.themeColors.ultra }

                    Item {
                        width: parent.width
                        height: 52
                        Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "音频规格"; color: root.themeColors.ink; font.family: root.themeColors.serif; font.pixelSize: 13; font.letterSpacing: 1.2 }
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            StilleTextButton { themeColors: root.themeColors; fontSize: 11; text: "HIGH 320"; activeRule: true; horizontalAlignment: Text.AlignRight; active: app.qualityLevel === "exhigh"; onClicked: { app.qualityLevel = "exhigh"; app.quality = "HIGH 320KBPS"; core.setSetting("quality", "exhigh"); } }
                            Text { text: " / "; color: root.themeColors.faint; font.family: root.themeColors.serifLatin; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                            StilleTextButton { themeColors: root.themeColors; fontSize: 11; text: "LOSSLESS"; activeRule: true; horizontalAlignment: Text.AlignRight; active: app.qualityLevel === "lossless"; onClicked: { app.qualityLevel = "lossless"; app.quality = "FLAC 24-BIT / 96KHZ"; core.setSetting("quality", "lossless"); } }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: root.themeColors.faint }

                    StilleTextButton { width: parent.width; themeColors: root.themeColors; fontSize: 12; text: app.likedPlaylistId.length > 0 ? "读取我喜欢的音乐 →" : "我喜欢的音乐（登录后可用）"; horizontalAlignment: Text.AlignLeft; onClicked: { if (app.likedPlaylistId.length > 0) app.loadLiked(); else app.openLogin(); } }
                    Rectangle { width: parent.width; height: 1; color: root.themeColors.ultra }
                    Rectangle { width: parent.width; height: 1; color: root.themeColors.ultra }
                    StilleTextButton { width: parent.width; visible: app.loggedIn; themeColors: root.themeColors; fontSize: 12; text: "退出登录"; horizontalAlignment: Text.AlignLeft; muted: true; onClicked: app.logout() }
                    Item { width: 1; height: 26 }
                }
            }
        }
    }
}
