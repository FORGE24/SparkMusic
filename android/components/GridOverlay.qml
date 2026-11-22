import QtQuick

Canvas {
    id: overlay
    property var themeColors
    property bool landscape: false
    enabled: false

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var side = landscape ? 48 : 24;
        var gap = landscape ? 16 : 14;
        var columns = landscape ? 8 : 4;
        var usable = width - side * 2 - gap * (columns - 1);
        var columnWidth = usable / columns;
        ctx.strokeStyle = themeColors.grid;
        ctx.lineWidth = 1;
        for (var i = 0; i < columns; i++) {
            var x = side + i * (columnWidth + gap);
            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(x + columnWidth, 0); ctx.lineTo(x + columnWidth, height); ctx.stroke();
        }
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
