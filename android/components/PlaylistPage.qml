import QtQuick

Item {
    id: root
    property var app
    readonly property var themeColors: app.pal
    visible: app.playlistOpen
    z: 30

    Rectangle { anchors.fill: parent; color: root.themeColors.canvas }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 12
        height: 136

        StilleTextButton {
            id: back
            anchors.left: parent.left
            anchors.top: parent.top
            themeColors: root.themeColors
            fontSize: 11
            text: "← 返回"
            horizontalAlignment: Text.AlignLeft
            muted: true
            onClicked: app.closePlaylist()
        }

        Text {
            id: eyebrow
            anchors.left: parent.left
            anchors.top: back.bottom
            anchors.topMargin: 4
            text: "PLAYLIST · 网易云音乐"
            color: root.themeColors.secondary
            font.family: root.themeColors.serifLatin
            font.pixelSize: 9
            font.letterSpacing: 1.8
        }
        Text {
            id: title
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: eyebrow.bottom
            anchors.topMargin: 8
            text: app.playlistTitle
            color: root.themeColors.ink
            font.family: root.themeColors.serif
            font.pixelSize: 25
            font.weight: Font.ExtraLight
            font.letterSpacing: 2.0
            elide: Text.ElideRight
        }
        Text {
            anchors.left: parent.left
            anchors.top: title.bottom
            anchors.topMargin: 4
            text: app.playlistSubtitle
            color: root.themeColors.secondary
            font.family: root.themeColors.serif
            font.pixelSize: 10
            elide: Text.ElideRight
        }
        StilleTextButton {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            themeColors: root.themeColors
            fontSize: 11
            text: "播放全部 →"
            horizontalAlignment: Text.AlignRight
            active: true
            onClicked: {
                if (app.playlistTracks.length > 0)
                    app.playFrom(app.playlistTracks, app.playlistTracks[0], true);
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        height: 1
        color: root.themeColors.faint
    }

    Flickable {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: 1
        contentWidth: width
        contentHeight: listColumn.height + 76
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: listColumn
            x: 24
            width: list.width - 48

            Repeater {
                model: app.playlistTracks
                delegate: TrackRow {
                    width: listColumn.width
                    app: root.app
                    track: modelData
                    ordinal: index
                    playbackContext: app.playlistTracks
                    themeColors: root.themeColors
                    onPlayRequested: app.playFrom(app.playlistTracks, modelData)
                }
            }

            Text {
                visible: app.playlistTracks.length === 0
                width: parent.width
                topPadding: 56
                text: app.busy ? "正在读取歌单……" : "这个歌单暂时没有可显示曲目。"
                color: root.themeColors.secondary
                font.family: root.themeColors.serif
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
