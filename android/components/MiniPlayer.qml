import QtQuick

Item {
    id: root
    property var app
    readonly property var themeColors: app.pal
    visible: app.miniVisible
    height: 58
    z: 80
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        color: root.themeColors.canvas
        border.color: root.themeColors.faint
        border.width: 1
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: root.themeColors.ink
        opacity: 0.18
    }
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        width: parent.width * app.progress
        height: 1
        color: root.themeColors.accent
        Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: app.setView("player")
    }

    Item {
        width: 30
        height: 30
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            anchors.fill: parent
            color: root.themeColors.canvas
            border.color: root.themeColors.faint
            border.width: 1
        }
        Image {
            id: miniCover
            anchors.fill: parent
            anchors.margins: 3
            source: app.currentCover || ""
            sourceSize.width: 60
            sourceSize.height: 60
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: source.toString().length > 0 && status === Image.Ready
        }
        StampArt {
            anchors.fill: parent
            visible: !app.currentCover || miniCover.status !== Image.Ready
            themeColors: root.themeColors
            trackId: app.currentTrack.id
        }
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 66
        anchors.right: controls.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        Text {
            width: parent.width
            text: app.currentTrack.title
            color: root.themeColors.ink
            font.family: root.themeColors.serif
            font.pixelSize: 13
            font.letterSpacing: 1.0
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: app.playbackNote.length > 0 ? app.playbackNote : app.currentTrack.artist
            color: root.themeColors.secondary
            font.family: root.themeColors.serif
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    Row {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        StilleTextButton {
            themeColors: root.themeColors
            fontSize: 11
            text: app.playing ? "暂停" : "播放"
            horizontalAlignment: Text.AlignRight
            onClicked: app.togglePlay()
        }
        StilleTextButton {
            themeColors: root.themeColors
            fontSize: 10
            text: "队列"
            horizontalAlignment: Text.AlignRight
            muted: true
            onClicked: {
                app.playlistOpen = false;
                app.portraitView = "player";
                app.queueOpen = true;
            }
        }
    }
}
