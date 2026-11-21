import QtQuick
import QtQuick.Layouts

// One row of the editorial track index: number, title, artist, duration.
Item {
    id: row
    property var pal
    property string serif: "Noto Serif CJK SC"
    property string serifLatin: "Noto Serif"
    property var track
    property int number: 0
    property bool current: false
    property int appearDelay: 0
    signal activated()

    width: parent ? parent.width : 0
    height: 54
    opacity: 0
    transform: Translate { id: rowLift; y: 6 }

    SequentialAnimation {
        id: appear
        PauseAnimation { duration: row.appearDelay }
        ParallelAnimation {
            NumberAnimation {
                target: row
                property: "opacity"
                from: 0; to: 1
                duration: 360
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: rowLift
                property: "y"
                from: 6; to: 0
                duration: 420
                easing.type: Easing.OutCubic
            }
        }
    }
    Component.onCompleted: appear.start()

    Rectangle {
        anchors.fill: parent
        color: hover.containsMouse || row.current ? row.pal.ultra : "transparent"
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: row.pal.faint
    }

    // index
    Text {
        id: indexText
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: row.number > 0 ? ("0" + row.number).slice(-2) : row.track.id
        color: row.current ? row.pal.accent : row.pal.ink3
        font.family: row.serifLatin
        font.pixelSize: 11
        font.letterSpacing: 1.2
    }

    // playing dot
    Rectangle {
        width: 4; height: 4; radius: 2
        color: row.pal.accent
        visible: row.current
        anchors.left: indexText.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    // title
    Text {
        anchors.left: indexText.right
        anchors.leftMargin: 30
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.36
        text: row.track.title
        elide: Text.ElideRight
        color: row.current ? row.pal.ink : row.pal.ink
        font.family: row.serif
        font.pixelSize: 17
        font.weight: row.current ? Font.Medium : Font.Normal
    }

    // artist
    Text {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.5
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.3
        text: row.track.artist
        elide: Text.ElideRight
        color: row.pal.ink2
        font.family: row.serif
        font.pixelSize: 12
    }

    // favourite marker
    Text {
        visible: row.track.favorited === true
        anchors.right: duration.left
        anchors.rightMargin: 26
        anchors.verticalCenter: parent.verticalCenter
        text: "●"
        color: row.pal.accent
        font.pixelSize: 7
    }

    Text {
        id: duration
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: Math.floor(row.track.duration / 60) + ":"
              + ("0" + (row.track.duration % 60)).slice(-2)
        color: row.pal.ink3
        font.family: row.serifLatin
        font.pixelSize: 11
        font.letterSpacing: 1
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.activated()
    }
}
