import QtQuick

Item {
    id: root
    property var app
    readonly property var themeColors: app.pal
    property string mode: "qr"                 // qr | sms | cookie
    property string qrRows: ""
    property string qrKey: ""
    property string qrState: "idle"
    property string statusText: "链路就绪 · WEB QR"
    property string statusCopy: "与 music.163.com/st/webplayer 同源登录。"
    property string errorMsg: ""
    property int pollErrors: 0
    property int autoRefreshes: 0
    property bool polling: false
    property bool pendingAccount: false
    property string phone: "+86 138 0024 1989"
    property string passcode: ""
    property string csrf: ""
    property string musicU: ""
    property bool smsSent: false

    function refreshQr() {
        qrKey = "";
        qrRows = "";
        qrState = "loading";
        pollErrors = 0;
        pendingAccount = false;
        statusText = "正在申请码纹 · QR";
        statusCopy = "与 webplayer 同源，扫码后在手机端确认。";
        api.loadQrKey();
    }

    function pollQr() {
        if (qrKey.length === 0 || polling) return;
        polling = true;
        api.pollQr(qrKey);
    }

    function setMode(next) {
        mode = next;
        errorMsg = "";
        if (next === "qr") refreshQr();
        if (next === "sms") {
            statusText = "短信验码 · 待发送";
            statusCopy = "输入手机号后获取六位验码。";
        }
        if (next === "cookie") {
            statusText = "凭证登入 · 待校验";
            statusCopy = "分别粘贴浏览器 Cookies 中的 __csrf 与 MUSIC_U。";
        }
    }

    function sendSms() {
        var cleaned = String(phone).replace(/[^0-9]/g, "");
        if (cleaned.length < 6) {
            statusText = "手机号无效";
            statusCopy = "请输入完整的手机号。";
            return;
        }
        statusText = "正在发送验码…";
        api.sendSms(cleaned);
    }

    function submitSms() {
        if (!smsSent) {
            sendSms();
            return;
        }
        var cleaned = String(phone).replace(/[^0-9]/g, "");
        if (String(passcode).trim().length === 0) {
            statusText = "验码为空";
            statusCopy = "请输入六位验码。";
            return;
        }
        statusText = "正在校验短信验码…";
        api.loginSms(cleaned, String(passcode).trim());
    }

    function cookieValue(raw, key) {
        var text = String(raw || "").trim();
        if (text.indexOf(key + "=") === 0) text = text.substring(key.length + 1);
        var semi = text.indexOf(";");
        if (semi >= 0) text = text.substring(0, semi);
        return text.trim();
    }

    function submitCookie() {
        var c = cookieValue(csrf, "__csrf");
        var u = cookieValue(musicU, "MUSIC_U");
        if (u.length < 8) {
            statusText = "MUSIC_U 无效";
            statusCopy = "请粘贴浏览器 Cookies 中完整的 MUSIC_U 值。";
            return;
        }
        statusText = "正在校验 Cookie…";
        api.loginCookie("MUSIC_U=" + u + (c.length > 0 ? "; __csrf=" + c : ""));
    }

    function submitPrimary() {
        if (mode === "qr") refreshQr();
        else if (mode === "sms") submitSms();
        else submitCookie();
    }

    Component.onCompleted: {
        if (visible) refreshQr();
    }
    onModeChanged: {
        if (mode === "sms") {
            statusText = smsSent ? "验码已发送" : "短信验码 · 待发送";
            statusCopy = "输入手机号后获取六位验码。";
        } else if (mode === "cookie") {
            statusText = "凭证登入 · 待校验";
            statusCopy = "分别粘贴浏览器 Cookies 中的 __csrf 与 MUSIC_U。";
        }
    }

    onVisibleChanged: {
        if (!visible) {
            pollTimer.stop();
            return;
        }
        if (mode === "qr" && (qrState === "idle" || qrState === "expired" || qrState === "error" || qrRows.length === 0))
            refreshQr();
        else if (mode === "qr" && qrKey.length > 0)
            pollTimer.start();
    }

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: root.pollQr()
    }

    Connections {
        target: api
        function onQrKeyReady(json) {
            if (root.mode !== "qr") return;
            try {
                var data = JSON.parse(json);
                if (!data.unikey) {
                    root.qrState = "error";
                    root.statusText = "码纹申请失败";
                    root.statusCopy = String(json).substring(0, 120);
                    return;
                }
                root.qrKey = data.unikey;
                root.qrRows = core.qrMatrix("https://music.163.com/login?codekey=" + data.unikey);
                root.qrState = "waiting";
                root.statusText = "等待扫码 · 801";
                root.statusCopy = "请用网易云音乐 App 扫描上方码纹。";
                pollTimer.start();
            } catch (e) {
                root.qrState = "error";
                root.statusText = "码纹解析失败";
                root.statusCopy = String(json).substring(0, 120);
            }
        }

        function onQrCheckReady(json) {
            root.polling = false;
            if (root.mode !== "qr") return;
            var data = {};
            try { data = JSON.parse(json); } catch (e) {}
            var code = data.code;
            if (code === 800) {
                if (root.autoRefreshes < 2) {
                    root.autoRefreshes += 1;
                    root.statusText = "码纹已逾时 · 正在刷新";
                    root.refreshQr();
                } else {
                    root.qrState = "expired";
                    pollTimer.stop();
                    root.statusText = "码纹已逾时";
                    root.statusCopy = "请点「刷新码纹」重新生成。";
                }
            } else if (code === 801) {
                root.qrState = "waiting";
                root.pollErrors = 0;
                root.statusText = "等待扫码 · 801";
            } else if (code === 802) {
                root.qrState = "scanned";
                root.pollErrors = 0;
                root.statusText = "已扫描 · 802";
                root.statusCopy = "请回到手机端确认登录。";
            } else if (code === 803) {
                root.qrState = "ok";
                pollTimer.stop();
                root.pendingAccount = true;
                root.statusText = "已授权 · 读取账户";
                root.statusCopy = "正在验证网易云会话……";
                api.loadAccount();
            } else if (code === 8821) {
                pollTimer.stop();
                root.qrState = "waiting";
                root.statusText = "风控拦截 · 8821";
                root.statusCopy = "请改用短信验码或 Cookie 登入。";
            } else {
                root.pollErrors += 1;
                root.statusText = "等待扫码 · " + (code !== undefined ? code : "?");
                root.statusCopy = (data.message || data.msg || "服务端未返回原因")
                    + (root.pollErrors >= 5 ? " · 请刷新码纹" : " · 继续等待");
                if (root.pollErrors >= 5) pollTimer.stop();
            }
        }

        function onSmsReady(json) {
            if (root.mode !== "sms") return;
            var data = {};
            try { data = JSON.parse(json); } catch (e) {}
            if (data.code === 200) {
                root.smsSent = true;
                root.statusText = "验码已发送";
                root.statusCopy = "请输入收到的六位验码。";
            } else {
                root.statusText = "验码发送失败 · " + (data.code !== undefined ? data.code : "?");
                root.statusCopy = data.message || data.msg || "请稍后再试。";
            }
        }

        function onLoginReady(json) {
            if (root.mode === "cookie") {
                // loginCookie returns the account check directly.
                try {
                    var acc = JSON.parse(json);
                    if (acc.account && acc.account.id) {
                        root.pendingAccount = false;
                        root.statusText = "已入室 · Cookie";
                        root.statusCopy = "凭证已写入本地会话。";
                        root.app.finishLogin(json);
                    } else {
                        root.statusText = "Cookie 未通过 · " + (acc.code !== undefined ? acc.code : "?");
                        root.statusCopy = "账户接口没有返回有效会话。";
                    }
                } catch (e) { root.statusCopy = String(json).substring(0, 120); }
                return;
            }
            if (root.mode !== "sms") return;
            var data = {};
            try { data = JSON.parse(json); } catch (e) {}
            if (data.code === 200) {
                root.pendingAccount = true;
                root.statusText = "验码通过 · 读取账户";
                root.statusCopy = "正在验证网易云会话……";
                api.loadAccount();
            } else {
                root.statusText = "验码失败 · " + (data.code !== undefined ? data.code : "?");
                root.statusCopy = data.message || data.msg || "请检查验码。";
            }
        }

        function onAccountReady(json) {
            if (!root.pendingAccount) return;
            root.pendingAccount = false;
            var data = {};
            try { data = JSON.parse(json); } catch (e) {}
            if (data.account && data.account.id) {
                root.statusText = "已入室 · " + ((data.profile || {}).nickname || "");
                root.statusCopy = "正在载入账户歌单。";
                root.app.finishLogin(json);
            } else {
                root.polling = false;
                root.statusText = "会话未建立 · " + (data.code !== undefined ? data.code : "?");
                root.statusCopy = "登录响应成功，但账户接口为空；请重试或改用 Cookie。";
            }
        }
    }

    // ---------------------------------------------------------- top placard
    Item {
        id: topNote
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 18
        height: 52

        LogoLockup {
            anchors.left: parent.left
            anchors.top: parent.top
            app: app
            suffix: "ARCHIVE · NO. 11 / 2026"
            markSize: 25
            wordSize: 13
            suffixSize: 9
        }
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topNote.bottom
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        height: 1
        color: root.themeColors.faint
    }

    Item {
        id: centerStage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topNote.bottom
        anchors.bottom: bottomActions.top

        // QR mode
        Column {
            visible: root.mode === "qr"
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 0

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0
                Text {
                    text: "静"
                    color: root.themeColors.ink
                    font.family: root.themeColors.serif
                    font.pixelSize: 34
                    font.weight: Font.ExtraLight
                    horizontalAlignment: Text.AlignHCenter
                    width: 70
                }
                Text {
                    text: "听"
                    color: root.themeColors.ink
                    font.family: root.themeColors.serif
                    font.pixelSize: 34
                    font.weight: Font.ExtraLight
                    horizontalAlignment: Text.AlignHCenter
                    width: 70
                }
            }

            Item { width: 1; height: 26 }
            Item {
                width: 182
                height: 182
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    anchors.fill: parent
                    color: root.themeColors.canvas
                    border.color: root.themeColors.faint
                    border.width: 1
                }
                Canvas {
                    id: qrCanvas
                    anchors.fill: parent
                    anchors.margins: 10
                    visible: root.qrRows.length > 0
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var rows = root.qrRows.split("\n");
                        var n = rows.length;
                        if (n === 0) return;
                        var cell = Math.min(width, height) / n;
                        var ox = (width - cell * n) / 2;
                        var oy = (height - cell * n) / 2;
                        ctx.fillStyle = root.themeColors.ink;
                        for (var y = 0; y < n; y++) {
                            var row = rows[y];
                            for (var x = 0; x < row.length; x++) {
                                if (row.charAt(x) === "1")
                                    ctx.fillRect(ox + x * cell, oy + y * cell, cell + 0.4, cell + 0.4);
                            }
                        }
                    }
                    Connections {
                        target: root
                        function onQrRowsChanged() { qrCanvas.requestPaint() }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: root.qrRows.length === 0
                    text: "正在生成码纹…"
                    color: root.themeColors.secondary
                    font.family: root.themeColors.serif
                    font.pixelSize: 11
                    font.letterSpacing: 1.2
                }
            }

            Text {
                width: parent.width
                text: root.statusText
                color: root.themeColors.ink
                font.family: root.themeColors.serif
                font.pixelSize: 12
                font.letterSpacing: 1.4
                horizontalAlignment: Text.AlignHCenter
                topPadding: 22
            }
            Text {
                width: parent.width
                text: root.statusCopy
                color: root.themeColors.secondary
                font.family: root.themeColors.serif
                font.pixelSize: 10
                lineHeight: 1.65
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
            }
        }

        // SMS mode
        Column {
            visible: root.mode === "sms"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 22

            Text {
                text: "验码入室 · ONE-TIME PASSCODE"
                color: root.themeColors.secondary
                font.family: root.themeColors.serifLatin
                font.pixelSize: 10
                font.letterSpacing: 2.0
                bottomPadding: 6
            }
            Item {
                width: parent.width
                height: 54
                Text {
                    text: "通讯号码 / MOBILE"
                    color: root.themeColors.secondary
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 10
                    font.letterSpacing: 1.6
                }
                TextInput {
                    id: phoneInput
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 30
                    text: root.phone
                    color: root.themeColors.ink
                    selectionColor: root.themeColors.accent
                    selectedTextColor: root.themeColors.canvas
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 16
                    font.letterSpacing: 1.2
                    selectByMouse: true
                    onTextChanged: root.phone = text
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: phoneInput.activeFocus ? root.themeColors.ink : root.themeColors.faint
                }
            }
            Item {
                width: parent.width
                height: 54
                Text {
                    text: "六位验码 / PASSCODE"
                    color: root.themeColors.secondary
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 10
                    font.letterSpacing: 1.6
                }
                TextInput {
                    id: codeInput
                    anchors.left: parent.left
                    anchors.right: sendCode.left
                    anchors.rightMargin: 12
                    anchors.bottom: parent.bottom
                    height: 30
                    text: root.passcode
                    color: root.themeColors.ink
                    selectionColor: root.themeColors.accent
                    selectedTextColor: root.themeColors.canvas
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 16
                    font.letterSpacing: 2.0
                    maximumLength: 6
                    inputMethodHints: Qt.ImhDigitsOnly
                    selectByMouse: true
                    onTextChanged: root.passcode = text
                }
                StilleTextButton {
                    id: sendCode
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    themeColors: root.themeColors
                    fontSize: 10
                    text: "获取验码"
                    horizontalAlignment: Text.AlignRight
                    onClicked: root.sendSms()
                }
                Rectangle {
                    anchors.left: codeInput.left
                    anchors.right: codeInput.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: codeInput.activeFocus ? root.themeColors.ink : root.themeColors.faint
                }
            }
            Text {
                width: parent.width
                text: root.statusCopy
                color: root.themeColors.secondary
                font.family: root.themeColors.serif
                font.pixelSize: 10
                lineHeight: 1.6
                wrapMode: Text.WordWrap
            }
        }

        // Cookie mode
        Column {
            visible: root.mode === "cookie"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 20

            Text {
                text: "SESSION COOKIE · 凭证直入"
                color: root.themeColors.secondary
                font.family: root.themeColors.serifLatin
                font.pixelSize: 10
                font.letterSpacing: 2.0
            }
            Item {
                width: parent.width
                height: 54
                Text { text: "__csrf"; color: root.themeColors.secondary; font.family: root.themeColors.serifLatin; font.pixelSize: 10; font.letterSpacing: 1.4 }
                TextInput {
                    id: csrfInput
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 30
                    text: root.csrf
                    color: root.themeColors.ink
                    selectionColor: root.themeColors.accent
                    selectedTextColor: root.themeColors.canvas
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 14
                    selectByMouse: true
                    onTextChanged: root.csrf = text
                }
                Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: csrfInput.activeFocus ? root.themeColors.ink : root.themeColors.faint }
            }
            Item {
                width: parent.width
                height: 54
                Text { text: "MUSIC_U"; color: root.themeColors.secondary; font.family: root.themeColors.serifLatin; font.pixelSize: 10; font.letterSpacing: 1.4 }
                TextInput {
                    id: musicInput
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 30
                    text: root.musicU
                    color: root.themeColors.ink
                    selectionColor: root.themeColors.accent
                    selectedTextColor: root.themeColors.canvas
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 14
                    echoMode: TextInput.Password
                    selectByMouse: true
                    onTextChanged: root.musicU = text
                }
                Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: musicInput.activeFocus ? root.themeColors.ink : root.themeColors.faint }
            }
            Text {
                width: parent.width
                text: root.statusCopy
                color: root.themeColors.secondary
                font.family: root.themeColors.serif
                font.pixelSize: 10
                lineHeight: 1.6
                wrapMode: Text.WordWrap
            }
        }
    }

    Column {
        id: bottomActions
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 24
        anchors.bottomMargin: 22
        spacing: 0
        Row {
            anchors.right: parent.right
            spacing: 6
            Rectangle { width: 4; height: 4; radius: 2; color: root.themeColors.accent; anchors.verticalCenter: parent.verticalCenter }
            StilleTextButton {
                themeColors: root.themeColors
                text: root.mode === "qr" ? "刷新码纹 —" : (root.mode === "sms" ? "验码入室 —" : "凭证入室 —")
                horizontalAlignment: Text.AlignRight
                active: true
                onClicked: root.submitPrimary()
            }
        }
        Row {
            anchors.right: parent.right
            spacing: 6
            StilleTextButton {
                themeColors: root.themeColors
                fontSize: 10
                text: "扫码"
                horizontalAlignment: Text.AlignRight
                muted: root.mode !== "qr"
                active: root.mode === "qr"
                onClicked: root.setMode("qr")
            }
            Text { text: "·"; color: root.themeColors.faint; anchors.verticalCenter: parent.verticalCenter }
            StilleTextButton {
                themeColors: root.themeColors
                fontSize: 10
                text: "短信"
                horizontalAlignment: Text.AlignRight
                muted: root.mode !== "sms"
                active: root.mode === "sms"
                onClicked: root.setMode("sms")
            }
            Text { text: "·"; color: root.themeColors.faint; anchors.verticalCenter: parent.verticalCenter }
            StilleTextButton {
                themeColors: root.themeColors
                fontSize: 10
                text: "Cookie"
                horizontalAlignment: Text.AlignRight
                muted: root.mode !== "cookie"
                active: root.mode === "cookie"
                onClicked: root.setMode("cookie")
            }
        }
    }
}
