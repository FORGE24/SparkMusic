import QtQuick

Canvas {
    id: stamp
    property var themeColors
    property string trackId: "01"

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var w = width;
        var h = height;
        ctx.strokeStyle = themeColors.faint;
        ctx.lineWidth = 1;
        ctx.strokeRect(0.5, 0.5, w - 1, h - 1);
        ctx.strokeStyle = themeColors.ink;
        ctx.fillStyle = themeColors.warm;
        ctx.lineWidth = 0.85;
        ctx.globalAlpha = 0.38;
        if (trackId === "01") {
            ctx.beginPath();
            ctx.arc(w * 0.5, h * 0.36, w * 0.2, 0, Math.PI * 2);
            ctx.stroke();
            ctx.globalAlpha = 0.28;
            ctx.fillStyle = themeColors.warm;
            ctx.beginPath();
            ctx.arc(w * 0.5, h * 0.36, w * 0.09, 0, Math.PI * 2);
            ctx.fill();
            ctx.globalAlpha = 0.58;
            ctx.beginPath(); ctx.moveTo(0, h * 0.68); ctx.lineTo(w, h * 0.68); ctx.stroke();
            ctx.globalAlpha = 0.3;
            ctx.beginPath(); ctx.moveTo(w * 0.17, h * 0.78); ctx.lineTo(w * 0.83, h * 0.78); ctx.stroke();
        } else if (trackId === "02") {
            ctx.globalAlpha = 0.45;
            ctx.strokeRect(w * 0.18, h * 0.18, w * 0.64, h * 0.64);
            ctx.globalAlpha = 0.32;
            ctx.fillStyle = themeColors.cool;
            ctx.beginPath(); ctx.arc(w * 0.4, h * 0.5, w * 0.17, 0, Math.PI * 2); ctx.fill();
            ctx.globalAlpha = 0.8;
            ctx.strokeStyle = themeColors.ink;
            ctx.beginPath(); ctx.arc(w * 0.6, h * 0.5, w * 0.17, 0, Math.PI * 2); ctx.stroke();
        } else if (trackId === "03") {
            for (var i = 1; i <= 3; i++) {
                ctx.globalAlpha = i === 2 ? 0.8 : 0.3;
                ctx.beginPath();
                ctx.moveTo(w * 0.25 * i, 0);
                ctx.lineTo(w * 0.25 * i, h);
                ctx.stroke();
            }
            ctx.globalAlpha = 0.26;
            ctx.fillStyle = themeColors.warm;
            ctx.fillRect(w * 0.25, h * 0.3, w * 0.25, h * 0.25);
            ctx.globalAlpha = 0.75;
            ctx.strokeStyle = themeColors.ink;
            ctx.beginPath(); ctx.arc(w * 0.62, h * 0.66, w * 0.12, 0, Math.PI * 2); ctx.stroke();
        } else if (trackId === "04") {
            ctx.globalAlpha = 0.72;
            ctx.strokeStyle = themeColors.warm;
            ctx.beginPath(); ctx.moveTo(0, h); ctx.lineTo(w, 0); ctx.stroke();
            ctx.globalAlpha = 0.3;
            ctx.strokeStyle = themeColors.ink;
            ctx.beginPath(); ctx.moveTo(w * 0.26, h); ctx.lineTo(w, h * 0.26); ctx.stroke();
            ctx.globalAlpha = 0.35;
            ctx.fillStyle = themeColors.cool;
            ctx.beginPath(); ctx.arc(w * 0.34, h * 0.66, w * 0.16, 0, Math.PI * 2); ctx.fill();
        } else if (trackId === "05") {
            ctx.globalAlpha = 0.72;
            ctx.beginPath(); ctx.arc(w * 0.5, h * 0.5, w * 0.3, 0, Math.PI * 2); ctx.stroke();
            ctx.globalAlpha = 0.4;
            ctx.beginPath(); ctx.moveTo(w * 0.16, h * 0.16); ctx.lineTo(w * 0.84, h * 0.84); ctx.stroke();
            ctx.strokeStyle = themeColors.cool;
            ctx.globalAlpha = 0.5;
            ctx.beginPath(); ctx.moveTo(w * 0.84, h * 0.16); ctx.lineTo(w * 0.16, h * 0.84); ctx.stroke();
            ctx.globalAlpha = 0.4;
            ctx.fillStyle = themeColors.warm;
            ctx.beginPath(); ctx.arc(w * 0.5, h * 0.5, w * 0.09, 0, Math.PI * 2); ctx.fill();
        } else {
            ctx.globalAlpha = 0.7;
            ctx.beginPath(); ctx.moveTo(0, h * 0.5); ctx.lineTo(w, h * 0.5); ctx.stroke();
            ctx.beginPath(); ctx.arc(w * 0.5, h * 0.5, w * 0.24, 0, Math.PI * 2); ctx.stroke();
            ctx.globalAlpha = 0.5;
            ctx.beginPath(); ctx.moveTo(w * 0.18, h * 0.82); ctx.lineTo(w * 0.5, h * 0.44); ctx.lineTo(w * 0.82, h * 0.82); ctx.stroke();
        }
        ctx.globalAlpha = 1;
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
