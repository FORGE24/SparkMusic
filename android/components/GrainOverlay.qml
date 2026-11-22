import QtQuick

Canvas {
    id: grain
    property var themeColors
    enabled: false

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.fillStyle = themeColors.ink;
        ctx.globalAlpha = themeColors.isInk ? 0.028 : 0.022;
        var seed = 0x51A7E;
        for (var i = 0; i < 720; i++) {
            seed = (seed * 1664525 + 1013904223) & 0x7fffffff;
            var x = (seed % 10000) / 10000 * width;
            seed = (seed * 1664525 + 1013904223) & 0x7fffffff;
            var y = (seed % 10000) / 10000 * height;
            ctx.fillRect(x, y, 1, 1);
        }
        ctx.globalAlpha = 1;
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
