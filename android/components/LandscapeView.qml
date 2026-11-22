import QtQuick

Item {
    id: root
    property var app
    readonly property var themeColors: app.pal
    readonly property var track: app.currentTrack
    readonly property bool clockMode: track.instrumental || app.forceClockMode
    property string nowTime: Qt.formatTime(new Date(), "hh:mm")
    property int nowSeconds: new Date().getSeconds()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.nowTime = Qt.formatTime(new Date(), "hh:mm");
            root.nowSeconds = new Date().getSeconds();
        }
    }

    Item {
        id: top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 48
        anchors.rightMargin: 48
        anchors.topMargin: 10
        height: 52

        LogoLockup {
            anchors.left: parent.left
            anchors.top: parent.top
            app: app
            suffix: "案头播放 / LANDSCAPE"
            markSize: 19
            wordSize: 11
            suffixSize: 9
        }
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            text: "NO. " + app.padNumber(app.trackIndex + 1) + " / " + track.tag
            color: root.themeColors.secondary
            font.family: root.themeColors.serifLatin
            font.pixelSize: 10
            font.letterSpacing: 1.8
        }
        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: track.title
            color: root.themeColors.ink
            font.family: root.themeColors.serif
            font.pixelSize: 17
            font.letterSpacing: 1.4
        }
    }

    Horizon {
        id: horizon
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: top.bottom
        anchors.leftMargin: 48
        anchors.rightMargin: 48
        height: 30
        showFloating: false
        themeColors: root.themeColors
        progress: app.progress
        duration: app.duration
        currentSeconds: app.position
        onSeek: (ratio) => app.seek(ratio)
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: horizon.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 48
        anchors.rightMargin: 48
        anchors.topMargin: 12
        anchors.bottomMargin: 26
        spacing: 0

        // left: transport
        Item {
            width: parent.width * 0.24
            height: parent.height

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "TRANSPORT / 播控"
                    color: root.themeColors.secondary
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 9
                    font.letterSpacing: 2.0
                    bottomPadding: 6
                }
                StilleTextButton {
                    themeColors: root.themeColors
                    fontSize: 11
                    text: "PAUSE / " + (app.playing ? "暂停" : "播放")
                    horizontalAlignment: Text.AlignLeft
                    onClicked: app.togglePlay()
                }
                StilleTextButton {
                    themeColors: root.themeColors
                    fontSize: 11
                    text: "NEXT / 下一曲"
                    horizontalAlignment: Text.AlignLeft
                    onClicked: app.nextTrack()
                }
                StilleTextButton {
                    themeColors: root.themeColors
                    fontSize: 11
                    text: "PREV / 上一曲"
                    horizontalAlignment: Text.AlignLeft
                    onClicked: app.previousTrack()
                }
                StilleTextButton {
                    themeColors: root.themeColors
                    fontSize: 11
                    text: root.app.isFavorite(root.track) ? "FAVORITE / 已收藏" : "FAVORITE / 收藏"
                    horizontalAlignment: Text.AlignLeft
                    onClicked: app.toggleFavorite(root.track)
                }
                StilleTextButton {
                    themeColors: root.themeColors
                    fontSize: 11
                    text: "INDEX / 返回目录"
                    horizontalAlignment: Text.AlignLeft
                    onClicked: app.setView("home")
                }
            }
        }

        // center: lyric or clock
        Item {
            width: parent.width * 0.52
            height: parent.height

            Item {
                anchors.centerIn: parent
                width: parent.width * 0.9
                height: parent.height

                Column {
                    visible: !root.clockMode
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 12

                    Text {
                        width: parent.width
                        text: app.activeLyric ? app.activeLyric.text : ""
                        color: root.themeColors.ink
                        font.family: root.themeColors.serif
                        font.pixelSize: 27
                        font.weight: Font.ExtraLight
                        font.letterSpacing: 2.2
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        width: parent.width
                        text: app.nextLyric ? app.nextLyric.text : ""
                        color: root.themeColors.ink
                        opacity: 0.24
                        font.family: root.themeColors.serif
                        font.pixelSize: 12
                        font.letterSpacing: 1.2
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }

                Column {
                    visible: root.clockMode
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: root.nowTime
                        color: root.themeColors.ink
                        font.family: root.themeColors.serifLatin
                        font.pixelSize: 56
                        font.weight: Font.Light
                        font.letterSpacing: 2
                        horizontalAlignment: Text.AlignHCenter
                        width: 130
                    }
                    Text {
                        text: ("0" + root.nowSeconds).slice(-2) + " · LOCAL TIME"
                        color: root.themeColors.secondary
                        font.family: root.themeColors.serifLatin
                        font.pixelSize: 10
                        font.letterSpacing: 2.0
                        horizontalAlignment: Text.AlignHCenter
                        width: 130
                    }
                }
            }
        }

        // right: read-only placard
        Item {
            width: parent.width * 0.24
            height: parent.height

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: 5
                Text {
                    width: parent.width
                    text: root.track.title
                    color: root.themeColors.ink
                    font.family: root.themeColors.serif
                    font.pixelSize: 15
                    font.letterSpacing: 1.2
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: root.track.artist + "\n" + root.track.album + " · " + root.track.year
                    color: root.themeColors.secondary
                    font.family: root.themeColors.serif
                    font.pixelSize: 10
                    lineHeight: 1.55
                    wrapMode: Text.WordWrap
                }
                Text {
                    text: app.quality
                    color: root.themeColors.secondary
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 9
                    font.letterSpacing: 1.4
                    topPadding: 10
                }
            }
        }
    }
}
