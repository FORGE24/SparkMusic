import QtQuick

Item {
    id: control
    property var themeColors
    property string text: ""
    property bool active: false
    property bool muted: false
    property bool activeRule: false
    property int fontSize: 12
    property int horizontalAlignment: Text.AlignLeft
    property alias font: label.font
    signal clicked()

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: control.clicked()

    implicitWidth: Math.max(44, label.implicitWidth + 8)
    implicitHeight: 44
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        color: hover.containsMouse || press.pressed ? control.themeColors.ultra : "transparent"
        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Text {
        id: label
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: control.horizontalAlignment
        text: control.text
        color: control.themeColors.ink
        opacity: press.pressed ? 0.42 : (control.muted ? 0.56 : (control.active ? 1.0 : 0.72))
        font.family: control.themeColors.serif
        font.pixelSize: control.fontSize
        font.letterSpacing: 2.0
        font.weight: Font.Normal
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    Rectangle {
        visible: control.active && control.activeRule
        width: label.implicitWidth
        height: 1
        color: control.themeColors.ink
        x: control.horizontalAlignment === Text.AlignRight
            ? control.width - width
            : (control.horizontalAlignment === Text.AlignHCenter ? (control.width - width) / 2 : 0)
        y: control.height - 3
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: press.pressed = true
        onReleased: press.pressed = false
        onCanceled: press.pressed = false
        onClicked: control.clicked()
    }
    QtObject { id: press; property bool pressed: false }
}
