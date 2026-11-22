import QtQuick

Item {
    id: horizon
    property var themeColors
    property real progress: 0
    property int currentSeconds: 0
    property int duration: 1
    property bool showFloating: true
    signal seek(real ratio)

    height: 44
    implicitHeight: 44

    Canvas {
        id: rule
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var y = height / 2;
            ctx.strokeStyle = horizon.themeColors.faint;
            ctx.lineWidth = 1;
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
            ctx.strokeStyle = horizon.themeColors.ink;
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width * horizon.progress, y); ctx.stroke();
            ctx.fillStyle = horizon.themeColors.accent;
            ctx.beginPath();
            ctx.arc(width * horizon.progress, y, mouse.pressed ? 7 : 5, 0, Math.PI * 2);
            ctx.fill();
        }
    }

    Text {
        visible: horizon.showFloating && mouse.pressed
        text: {
            var sec = Math.round(horizon.progress * horizon.duration);
            return (sec < 600 ? "0" : "") + Math.floor(sec / 60) + ":" + (sec % 60 < 10 ? "0" : "") + (sec % 60);
        }
        x: Math.max(0, Math.min(width - implicitWidth, width * horizon.progress - implicitWidth / 2))
        y: -24
        color: horizon.themeColors.ink
        font.family: horizon.themeColors.serifLatin
        font.pixelSize: 10
        font.letterSpacing: 1.4
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function apply(x) {
            var ratio = Math.max(0, Math.min(1, x / width));
            horizon.seek(ratio);
            rule.requestPaint();
        }
        onPressed: apply(mouse.x)
        onPositionChanged: if (pressed) apply(mouse.x)
        onReleased: rule.requestPaint()
        onCanceled: rule.requestPaint()
    }

    onProgressChanged: rule.requestPaint()
}
