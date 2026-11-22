import QtQuick

// A typographic control in the Swiss ledger style: small latin label above the
// Chinese label, no box, hover reveals a hairline underline.
Item {
    id: control
    property var pal
    property string serif: "Noto Serif CJK SC"
    property string serifLatin: "Noto Serif"
    property string latin: ""
    property string zh: ""
    property bool active: false
    property bool danger: false
    property bool rightAligned: true
    property int zhSize: 15
    property bool pressed: false
    property real labelShiftX: 0
    property real extraLetterSpacing: 0
    signal clicked()

    width: parent ? parent.width : implicitWidth
    height: column.implicitHeight + 10

    Rectangle {
        anchors.fill: parent
        color: hover.containsMouse ? control.pal.ultra : "transparent"
        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Column {
        id: column
        width: control.width
        anchors.right: control.rightAligned ? parent.right : undefined
        anchors.left: control.rightAligned ? undefined : parent.left
        spacing: 2
        // A short damped press; amplitude is deliberately tiny.
        y: control.pressed ? 1 : 0
        scale: control.pressed ? 0.994 : 1
        transform: Translate { x: control.labelShiftX }
        // Short, monotonic press: elastic easing read as a twitch on click.
        Behavior on y {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }

        Text {
            visible: control.latin.length > 0
            width: parent.width
            horizontalAlignment: control.rightAligned ? Text.AlignRight : Text.AlignLeft
            text: control.latin.toUpperCase()
            color: control.pal.ink3
            font.family: control.serifLatin
            font.pixelSize: 10
            font.letterSpacing: 2.1
            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }
        Text {
            id: zhLabel
            width: parent.width
            horizontalAlignment: control.rightAligned ? Text.AlignRight : Text.AlignLeft
            text: control.zh
            color: control.danger ? control.pal.accent
                : control.active ? control.pal.ink : control.pal.ink2
            font.family: control.serif
            font.pixelSize: control.zhSize
            font.weight: control.active ? Font.Medium : Font.Normal
            font.letterSpacing: control.extraLetterSpacing
            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }
    }

    Rectangle {
        anchors.left: control.rightAligned ? undefined : parent.left
        anchors.right: control.rightAligned ? parent.right : undefined
        anchors.bottom: parent.bottom
        height: 1
        width: hover.containsMouse || control.active ? zhLabel.implicitWidth : 0
        color: control.danger ? control.pal.accent : control.pal.ink
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    // Mechanical label swap: the current label leaves left, the next one
    // enters from the right. PAUSE/PLAY also changes the text at this moment.
    SequentialAnimation {
        id: labelSwap
        NumberAnimation {
            target: control
            property: "labelShiftX"
            to: -6
            duration: 110
            easing.type: Easing.OutCubic
        }
        PropertyAction { target: control; property: "labelShiftX"; value: 6 }
        NumberAnimation {
            target: control
            property: "labelShiftX"
            to: 0
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: control.pressed = true
        onReleased: control.pressed = false
        onCanceled: control.pressed = false
        onClicked: {
            control.clicked();
            labelSwap.restart();
        }
    }
}
