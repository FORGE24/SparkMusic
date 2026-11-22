import QtQuick

Item {
    id: root
    property var app
    property var track
    property int ordinal: 0
    property var playbackContext: []
    property var themeColors
    signal playRequested()
    readonly property bool expanded: app.expandedTrackId === track.id
    readonly property bool current: app.currentTrack.id === track.id
    width: parent ? parent.width : 0
    height: head.height + drawer.height
    Behavior on height { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }

    Item {
        id: head
        width: root.width
        height: 54

        Rectangle {
            anchors.fill: parent
            color: headMouse.containsMouse ? root.themeColors.ultra : "transparent"
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            spacing: 4
            Rectangle {
                width: 4; height: 4; radius: 2
                color: root.current ? root.themeColors.accent : "transparent"
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: app.padNumber(root.ordinal + 1)
                color: root.themeColors.secondary
                font.family: root.themeColors.serifLatin
                font.pixelSize: 10
                font.letterSpacing: 1.3
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 36
            anchors.right: duration.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.track.title
            color: root.themeColors.ink
            opacity: root.current || root.expanded ? 1.0 : 0.82
            font.family: root.themeColors.serif
            font.pixelSize: 16
            font.weight: Font.Light
            font.letterSpacing: 1.0
            elide: Text.ElideRight
        }

        Text {
            id: duration
            anchors.right: exhibit.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: app.formatTime(root.track.duration)
            color: root.themeColors.secondary
            font.family: root.themeColors.serifLatin
            font.pixelSize: 10
            font.letterSpacing: 1.2
        }

        Text {
            id: exhibit
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            text: root.expanded ? "收" : "展"
            color: root.expanded ? root.themeColors.ink : root.themeColors.secondary
            font.family: root.themeColors.serif
            font.pixelSize: 9
            horizontalAlignment: Text.AlignRight
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: root.expanded ? root.themeColors.faint : root.themeColors.ultra
        }

        MouseArea {
            id: headMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.playRequested()
            onPressAndHold: app.expandedTrackId = root.expanded ? "" : root.track.id
        }

        MouseArea {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 44
            onClicked: app.expandedTrackId = root.expanded ? "" : root.track.id
        }
    }

    Item {
        id: drawer
        width: root.width
        anchors.top: head.bottom
        height: root.expanded ? 124 : 0
        clip: true
        opacity: root.expanded ? 1 : 0
        Behavior on height { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 260 } }

        Column {
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: 4

            Row {
                width: parent.width
                spacing: 14

                Item {
                    width: 54
                    height: 54
                    Rectangle {
                        anchors.fill: parent
                        color: root.themeColors.canvas
                        border.color: root.themeColors.faint
                        border.width: 1
                    }
                    Image {
                        id: rowCover
                        anchors.fill: parent
                        anchors.margins: 3
                        source: root.track.cover || ""
                        sourceSize.width: 108
                        sourceSize.height: 108
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: source.toString().length > 0 && status === Image.Ready
                    }
                    StampArt {
                        anchors.fill: parent
                        visible: !root.track.cover || rowCover.status !== Image.Ready
                        themeColors: root.themeColors
                        trackId: root.track.id
                    }
                }

                Column {
                    width: parent.width - 68
                    spacing: 5
                    Text {
                        text: "EXHIBIT · " + (root.track.album || "网易云音乐") + (root.track.year ? " / " + root.track.year : "")
                        color: root.themeColors.secondary
                        font.family: root.themeColors.serifLatin
                        font.pixelSize: 9
                        font.letterSpacing: 1.6
                    }
                    Text {
                        width: parent.width
                        text: root.track.note.length > 0
                            ? root.track.note
                            : ((root.track.album || "网易云音乐") + " · " + (root.track.label || "NETEASE"))
                        color: root.themeColors.ink
                        opacity: 0.78
                        font.family: root.themeColors.serif
                        font.pixelSize: 12
                        font.letterSpacing: 0.5
                        lineHeight: 1.55
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.track.label + " · " + root.track.tag
                        color: root.themeColors.secondary
                        font.family: root.themeColors.serifLatin
                        font.pixelSize: 9
                        font.letterSpacing: 1.0
                    }
                }
            }

            Item {
                width: parent.width
                height: 46
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: app.isFavorite(root.track) ? "已收录 · PRIVATE" : "未收录 · PRIVATE"
                    color: root.themeColors.secondary
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 9
                    font.letterSpacing: 1.4
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    StilleTextButton {
                        themeColors: root.themeColors
                        fontSize: 11
                        text: app.isFavorite(root.track) ? "取消收藏" : "收藏"
                        horizontalAlignment: Text.AlignRight
                        onClicked: app.toggleFavorite(root.track)
                    }
                    StilleTextButton {
                        themeColors: root.themeColors
                        fontSize: 11
                        text: "播放这首 →"
                        horizontalAlignment: Text.AlignRight
                        onClicked: root.playRequested()
                    }
                }
            }
        }
    }
}
