import QtQuick

Item {
    id: root
    property var app
    readonly property var themeColors: app.pal

    Column {
        id: placard
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 24
        spacing: 7
        bottomPadding: 18

        Text {
            width: parent.width
            text: "请求端： MacBook Pro · 桌面端"
            color: root.themeColors.secondary
            font.family: root.themeColors.serif
            font.pixelSize: 12
            font.letterSpacing: 1.2
        }
        Text {
            width: parent.width
            text: "节点： Tokyo · Edge"
            color: root.themeColors.secondary
            font.family: root.themeColors.serif
            font.pixelSize: 12
            font.letterSpacing: 1.2
        }
        Text {
            width: parent.width
            text: "协议： 端到端加密认证 (TLS 1.3)"
            color: root.themeColors.secondary
            font.family: root.themeColors.serif
            font.pixelSize: 12
            font.letterSpacing: 1.2
        }
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: placard.bottom
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        height: 1
        color: root.themeColors.faint
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 48
        spacing: 0

        Item {
            width: 84
            height: 76
            anchors.horizontalCenter: parent.horizontalCenter

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = root.themeColors.ink;
                    ctx.globalAlpha = 0.36;
                    ctx.lineWidth = 0.8;
                    var m = 8;
                    var l = 9;
                    // corner crop marks
                    ctx.beginPath(); ctx.moveTo(m, m + l); ctx.lineTo(m, m); ctx.lineTo(m + l, m); ctx.stroke();
                    ctx.beginPath(); ctx.moveTo(width - m - l, m); ctx.lineTo(width - m, m); ctx.lineTo(width - m, m + l); ctx.stroke();
                    ctx.beginPath(); ctx.moveTo(m, height - m - l); ctx.lineTo(m, height - m); ctx.lineTo(m + l, height - m); ctx.stroke();
                    ctx.beginPath(); ctx.moveTo(width - m - l, height - m); ctx.lineTo(width - m, height - m); ctx.lineTo(width - m, height - m - l); ctx.stroke();
                    // desktop
                    ctx.globalAlpha = 0.72;
                    ctx.strokeRect(width / 2 - 27, height / 2 - 24, 54, 36);
                    ctx.beginPath(); ctx.moveTo(width / 2 - 34, height / 2 + 18); ctx.lineTo(width / 2 + 34, height / 2 + 18); ctx.stroke();
                    ctx.fillStyle = root.themeColors.accent;
                    ctx.beginPath(); ctx.arc(width / 2, height / 2 - 6, 2.2, 0, Math.PI * 2); ctx.fill();
                }
            }
        }

        Text {
            width: parent.width
            text: app.desktopAuthConfirmed ? "已完成桌面端授权" : "确认于桌面端入室"
            color: root.themeColors.ink
            font.family: root.themeColors.serif
            font.pixelSize: 26
            font.weight: Font.ExtraLight
            font.letterSpacing: 3.5
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            topPadding: 28
        }
        Text {
            width: parent.width
            text: app.desktopAuthConfirmed
                ? "授权已写入本机 · 可回到播放室"
                : "掌端已识别桌面扉页动态码纹"
            color: root.themeColors.secondary
            font.family: root.themeColors.serif
            font.pixelSize: 12
            font.letterSpacing: 1.2
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            topPadding: 14
        }
    }

    Column {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 24
        anchors.bottomMargin: 24
        spacing: 0

        Row {
            anchors.right: parent.right
            spacing: 6
            Rectangle {
                width: 4; height: 4; radius: 2
                color: root.themeColors.accent
                anchors.verticalCenter: parent.verticalCenter
            }
            StilleTextButton {
                themeColors: root.themeColors
                text: app.desktopAuthConfirmed ? "回到播放室 —" : "确认授权 —"
                horizontalAlignment: Text.AlignRight
                active: true
                onClicked: {
                    if (app.desktopAuthConfirmed) app.setView("player");
                    else app.confirmDesktopAuth();
                }
            }
        }
        StilleTextButton {
            anchors.right: parent.right
            themeColors: root.themeColors
            text: "取消"
            horizontalAlignment: Text.AlignRight
            muted: true
            onClicked: app.setView("player")
        }
    }
}
