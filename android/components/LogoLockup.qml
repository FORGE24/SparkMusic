import QtQuick

Row {
    id: lockup
    property var app
    property var themeColors: app ? app.pal : null
    property string suffix: "ARCHIVE / 目录"
    property int markSize: 22
    property int wordSize: 12
    property int suffixSize: 9
    spacing: 8

    StilleMark {
        width: lockup.markSize
        height: lockup.markSize
        themeColors: lockup.themeColors
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: "STILLE"
        color: lockup.themeColors ? lockup.themeColors.ink : "#141414"
        font.family: lockup.themeColors ? lockup.themeColors.serifLatin : "Cormorant Garamond"
        font.pixelSize: lockup.wordSize
        font.letterSpacing: 3.0
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: lockup.suffix
        color: lockup.themeColors ? lockup.themeColors.secondary : "#77756F"
        font.family: lockup.themeColors ? lockup.themeColors.serif : "STILLE Song"
        font.pixelSize: lockup.suffixSize
        font.letterSpacing: 1.4
        anchors.verticalCenter: parent.verticalCenter
    }
}
