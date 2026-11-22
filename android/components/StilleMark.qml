import QtQuick

Canvas {
    id: mark
    property var themeColors
    property color inkColor: themeColors ? themeColors.ink : "#1E1D1B"
    property color accentColor: themeColors ? themeColors.accent : "#D94126"
    implicitWidth: 22
    implicitHeight: 22

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var cx = width / 2;
        var cy = height / 2;
        var r = Math.min(width, height) * 0.297;
        var lw = Math.max(0.65, Math.min(width, height) * 0.032);
        ctx.strokeStyle = inkColor;
        ctx.fillStyle = accentColor;
        ctx.lineWidth = lw;
        ctx.lineCap = "butt";

        // open outer ring, gap at upper-left (from the supplied line mark)
        ctx.beginPath();
        ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI, false);
        ctx.stroke();

        // short inner echo at lower-right
        ctx.beginPath();
        ctx.arc(cx, cy, r * 0.20 / 0.297, 0, Math.PI / 2, false);
        ctx.stroke();

        // split chord, leaving room for the vermilion star
        ctx.beginPath();
        ctx.moveTo(cx - r * 1.58, cy);
        ctx.lineTo(cx - r * 0.39, cy);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(cx + r * 0.39, cy);
        ctx.lineTo(cx + r * 1.58, cy);
        ctx.stroke();

        // four-point vermilion star
        var s = Math.min(width, height) * 0.156;
        var w = s * 0.20;
        ctx.beginPath();
        ctx.moveTo(cx, cy - s);
        ctx.lineTo(cx + w, cy - w);
        ctx.lineTo(cx + s, cy);
        ctx.lineTo(cx + w, cy + w);
        ctx.lineTo(cx, cy + s);
        ctx.lineTo(cx - w, cy + w);
        ctx.lineTo(cx - s, cy);
        ctx.lineTo(cx - w, cy - w);
        ctx.closePath();
        ctx.fill();
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onInkColorChanged: requestPaint()
    onAccentColorChanged: requestPaint()
}
