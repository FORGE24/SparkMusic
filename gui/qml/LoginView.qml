import QtQuick
import QtQuick.Layouts

// View 1 — 登录扉页: 扫码 / 凭证 / 访客. QR login is real: the matrix encodes
// https://music.163.com/login?codekey=<unikey> and the poll captures MUSIC_U.
Item {
    id: login
    property var pal
    property string serif
    property string serifLatin: "Noto Serif"

    signal loggedIn(string nickname)
    signal guestEntered()
    signal sessionCleared()

    property bool sessionActive: false
    property bool darkTheme: false

    property string mode: typeof launchLoginMode !== "undefined" && launchLoginMode.length > 0
        ? "credential" : "qr"
    property string credMode: {
        var requested = (typeof launchLoginMode !== "undefined") ? launchLoginMode : "";
        return (requested === "cookie") ? "cookie" : "sms";
    }
    property string qrRows: ""
    property string qrKey: ""
    property string qrUrl: ""
    property string qrState: "idle"
    property string statusText: "链路就绪 · Tokyo"
    property string statusCopy: "请开启移动端「网易云音乐」，\n对准中央码纹轻扫授权。"
    property string errorMsg: ""
    property string nickname: ""
    property int autoRefreshes: 0
    property int pollErrors: 0
    property string lastCode: ""

    Component.onCompleted: {
        if (!visible) return;
        if (mode === "qr") {
            refreshQr();
        } else if (mode === "credential") {
            statusText = "凭证入室 · 待校验";
            statusCopy = credMode === "cookie"
                ? "分别粘贴 __csrf 与 MUSIC_U 后点击确认。"
                : "输入手机号获取验码，或切换 Cookie 登入。";
        } else {
            statusText = "访客通行 · 只读";
            statusCopy = "以访客身份进入策展与检索。";
        }
    }
    onVisibleChanged: {
        if (!visible) {
            pollTimer.stop();
            return;
        }
        // Entering the page for the first time (or after an expired code)
        // must request a fresh unikey; otherwise the plate stays blank.
        if (qrState === "idle" || qrState === "expired" || qrState === "error"
                || qrRows.length === 0) {
            refreshQr();
        } else if (qrState === "waiting") {
            pollTimer.start();
        }
    }

    // ------------------------------------------------------------- QR login
    function refreshQr() {
        errorMsg = "";
        qrState = "waiting";
        pollErrors = 0;
        statusText = "正在申请码纹 · QR";
        statusCopy = "码纹每两分钟轮换，扫描后请在掌端确认。";

        var raw = core.loginQrKey();
        try {
            var data = JSON.parse(raw);
            if (!data.unikey) {
                qrState = "error";
                errorMsg = raw;
                statusText = "码纹申请失败";
                return;
            }
            qrKey = data.unikey;
            qrUrl = "https://music.163.com/login?codekey=" + qrKey;
            qrRows = core.qrMatrix(qrUrl);
            qrState = "waiting";
            statusText = "链路就绪 · WEB QR";
            statusCopy = "与 music.163.com/st/webplayer 同源登录，\n扫码确认后自动写入 Cookies。";
            pollTimer.start();
        } catch (e) {
            qrState = "error";
            errorMsg = raw;
            statusText = "码纹解析失败";
        }
    }

    function pollQr() {
        if (qrKey.length === 0) return;
        if (qrState === "ok" || qrState === "expired") {
            pollTimer.stop();
            return;
        }

        var raw = core.loginQrCheck(qrKey);
        try {
            var data = JSON.parse(raw);
            var code = data.code;
            login.lastCode = String(code);
            console.log("qr check ->", code, (data.message || data.msg || ""));
            if (code === 800) {
                pollTimer.stop();
                // Like YesPlayMusic: an expired code is silently re-issued a
                // couple of times before asking the user to intervene.
                if (autoRefreshes < 2) {
                    autoRefreshes += 1;
                    statusText = "码纹已逾时 · 正在重新获取";
                    refreshQr();
                } else {
                    qrState = "expired";
                    statusText = "码纹已逾时";
                    statusCopy = "当前动态码纹已自动失效，\n请点击「刷新码纹」重新扫码。";
                }
            } else if (code === 801) {
                qrState = "waiting";
                login.pollErrors = 0;
                statusText = "等待扫码 · 801";
            } else if (code === 802) {
                qrState = "scanned";
                login.pollErrors = 0;
                statusText = "已扫描 · 802";
                statusCopy = "掌端已识别码纹，\n请在手机上点击「确认登录」。";
            } else if (code === 803) {
                qrState = "ok";
                pollTimer.stop();
                var ra = core.account();
                var profile = {};
                try {
                    profile = JSON.parse(ra);
                } catch (e) {}
                if (profile.code !== 200 || !(profile.account && profile.account.id)) {
                    statusText = "已授权 · 会话无效";
                    statusCopy = "扫码已确认，但账户接口返回空会话（code "
                            + (profile.code || "?") + "，account 为 null）。"
                            + "通常表示 cookie 未写入，请点「刷新码纹」重试。";
                    qrState = "expired";
                    return;
                }
                nickname = (profile.profile || {}).nickname || "";
                statusText = "已入室 · 803";
                statusCopy = "凭证已写入本地会话。";
                login.loggedIn(nickname);
            } else if (code === 8821) {
                // Confirmation was rejected by risk control. Retrying only
                // makes it worse; keep the matrix visible and point the user
                // at the two paths that work.
                pollTimer.stop();
                qrState = "waiting";
                statusText = "风控拦截 · 8821";
                statusCopy = "扫码已确认，但服务端以风险控制拒绝了本次授权。"
                        + "\n请改用「凭证登入」的手机号或 Cookie 方式。";
            } else {
                // Risk control / transient errors must NOT cover the matrix or
                // kill polling: the code on screen is still valid.
                login.pollErrors += 1;
                qrState = "waiting";
                statusText = "接口繁忙 · " + (data.code !== undefined ? data.code : "?")
                        + " · 重试 " + login.pollErrors + "/5";
                statusCopy = (data.message || data.msg || "服务端未返回原因")
                        + "\n码纹仍有效，继续等待扫码。";
                if (login.pollErrors >= 5) {
                    pollTimer.stop();
                    statusText = "多次失败 · 请刷新码纹";
                    statusCopy = "服务端持续拒绝，请刷新码纹或改用 Cookie 登入。";
                }
            }
        } catch (e) {
            statusText = "轮询异常";
            errorMsg = raw;
        }
    }

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: login.pollQr()
    }

    // ------------------------------------------------------- credential login
    function cookieField(raw, key) {
        var text = String(raw || "").trim();
        if (text.indexOf(key + "=") === 0)
            text = text.substring(key.length + 1);
        var semi = text.indexOf(";");
        if (semi >= 0)
            text = text.substring(0, semi);
        return text.trim();
    }

    function submitCredential() {
        errorMsg = "";
        statusText = "正在校验凭证…";
        if (credMode === "cookie") {
            var csrf = cookieField(csrfInput.text, "__csrf");
            var musicU = cookieField(musicInput.text, "MUSIC_U");
            if (musicU.length < 8) {
                statusText = "MUSIC_U 无效";
                statusCopy = "请从浏览器 Cookies 里复制完整的 MUSIC_U 值。";
                return;
            }
            var cookie = "MUSIC_U=" + musicU
                    + (csrf.length > 0 ? "; __csrf=" + csrf : "");
            core.setCookie(cookie);
            var rawAccount = core.account();
            try {
                var account = JSON.parse(rawAccount);
                if (account.code === 200 && account.account && account.account.id) {
                    var nick = (account.profile || {}).nickname || "";
                    nickname = nick;
                    statusText = "已入室 · Cookie";
                    statusCopy = "凭证已写入本地会话。";
                    login.loggedIn(nick);
                } else {
                    statusText = "Cookie 未通过 · " + (account.code !== undefined ? account.code : "?")
                            + "（account 为空）";
                    statusCopy = "请确认复制的是完整的 MUSIC_U Cookie。";
                    errorMsg = rawAccount;
                }
            } catch (e) {
                errorMsg = rawAccount;
            }
            return;
        }
        var phone = phoneInput.text.replace(/[^0-9]/g, "");
        var payload = '{"phone":"' + phone + '","countrycode":"86","captcha":"'
                + smsInput.text + '"}';
        handleLoginResponse(core.callWithMode("login/cellphone", payload, "weapi"));
    }

    function handleLoginResponse(raw) {
        try {
            var data = JSON.parse(raw);
            if (data.code === 200) {
                var me = JSON.parse(core.account()).account || null;
                if (!me || !me.id) {
                    statusText = "会话未建立";
                    statusCopy = "登录接口返回 200，但账户接口仍为空。"
                            + "请稍后重试，或改用 Cookie 登录。";
                    errorMsg = "";
                    return;
                }
                var nick = (data.profile || {}).nickname || "";
                nickname = nick;
                statusText = "已入室 · 凭证";
                statusCopy = "凭证已写入本地会话。";
                login.loggedIn(nick);
            } else {
                statusText = "校验失败 · " + (data.code !== undefined ? data.code : "?");
                statusCopy = data.message || data.msg || "凭证未通过，请检查后重试。";
                errorMsg = raw;
            }
        } catch (e) {
            statusText = "响应解析失败";
            errorMsg = raw;
        }
    }

    function sendCode() {
        var phone = phoneInput.text.replace(/[^0-9]/g, "");
        if (phone.length < 6) {
            statusText = "号码无效";
            return;
        }
        var raw = core.sendSmsCode(phone);
        try {
            var data = JSON.parse(raw);
            statusText = data.code === 200 ? "验码已发送" : ("发送失败 · " + data.code);
            if (data.code !== 200) errorMsg = raw;
        } catch (e) {
            errorMsg = raw;
        }
    }

    // ------------------------------------------------------------------ layout
    Row {
        anchors.fill: parent
        spacing: 40

        // ------------------------------------------------ left: controls
        Column {
            width: parent.width * 0.22
            spacing: 40

            Column {
                width: parent.width
                spacing: 14

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: "MODE / 认证方式"
                    color: login.pal.ink3
                    font.family: login.serif
                    font.pixelSize: 10
                    font.letterSpacing: 2.2
                }
                SwissButton {
                    width: parent.width
                    pal: login.pal; serif: login.serif
                    zh: "扫码登入"
                    active: login.mode === "qr"
                    onClicked: login.mode = "qr"
                }
                SwissButton {
                    width: parent.width
                    pal: login.pal; serif: login.serif
                    zh: "凭证登入"
                    active: login.mode === "credential"
                    onClicked: login.mode = "credential"
                }
                SwissButton {
                    width: parent.width
                    pal: login.pal; serif: login.serif
                    zh: "访客聆听"
                    active: login.mode === "guest"
                    onClicked: login.mode = "guest"
                }
            }

            Column {
                width: parent.width
                spacing: 16
                visible: login.mode === "qr"
                SwissButton {
                    width: parent.width
                    pal: login.pal; serif: login.serif
                    zh: "刷新码纹"
                    zhSize: 13
                    onClicked: {
                        login.autoRefreshes = 0;
                        login.refreshQr();
                    }
                }
                SwissButton {
                    width: parent.width
                    pal: login.pal; serif: login.serif
                    visible: login.sessionActive
                    zh: "清除会话后扫码"
                    zhSize: 13
                    danger: true
                    onClicked: {
                        core.clearCookies();
                        login.sessionCleared();
                        login.statusText = "会话已清除";
                        login.statusCopy = "现在是访客状态，可以扫描其他账号。";
                        login.refreshQr();
                    }
                }
                SwissButton {
                    width: parent.width
                    pal: login.pal; serif: login.serif
                    zh: "复制登录链接"
                    zhSize: 13
                    onClicked: {
                        clip.text = login.qrUrl;
                        clip.selectAll();
                        clip.copy();
                        login.statusCopy = "登录链接已复制，可在手机浏览器打开后由网易云 App 接管。";
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 16
                visible: login.mode === "credential"
                SwissButton {
                    width: parent.width
                    pal: login.pal; serif: login.serif
                    zh: "确认入室"
                    zhSize: 13
                    onClicked: login.submitCredential()
                }
                SwissButton {
                    width: parent.width
                    pal: login.pal; serif: login.serif
                    zh: login.credMode === "sms" ? "切换 Cookie 登入" : "切换短信登入"
                    zhSize: 13
                    onClicked: login.credMode = login.credMode === "sms" ? "cookie" : "sms"
                }
            }

            Column {
                width: parent.width
                spacing: 16
                visible: login.mode === "guest"
                SwissButton {
                    width: parent.width
                    pal: login.pal; serif: login.serif
                    zh: "直接入室"
                    zhSize: 13
                    onClicked: login.guestEntered()
                }
            }
        }

        // ------------------------------------------------ centre: panels
        Item {
            width: parent.width * 0.52
            height: parent.height

            // -------- QR panel
            Item {
                anchors.fill: parent
                visible: login.mode === "qr"

                Item {
                    id: qrStage
                    width: Math.min(parent.width * 0.72, parent.height * 0.72)
                    height: width
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -16

                    // The plate stays paper-white in both themes: light modules
                    // on a dark plate are often rejected by phone scanners.
                    Rectangle {
                        anchors.fill: parent
                        color: "#F2F1ED"
                        border.color: login.pal.faint
                        border.width: 1
                    }

                    Canvas {
                        id: qrCanvas
                        anchors.fill: parent
                        anchors.margins: 22
                        antialiasing: false
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var rows = login.qrRows.split("\n");
                            var n = rows.length;
                            if (n < 8) return;
                            var cell = Math.floor(Math.min(width, height) / n);
                            var ox = Math.floor((width - cell * n) / 2);
                            var oy = Math.floor((height - cell * n) / 2);
                            ctx.fillStyle = "#141414";
                            for (var y = 0; y < n; y++) {
                                var row = rows[y];
                                for (var x = 0; x < row.length; x++) {
                                    if (row.charAt(x) === "1")
                                        ctx.fillRect(ox + x * cell, oy + y * cell, cell, cell);
                                }
                            }
                        }
                        Connections {
                            target: login
                            function onQrRowsChanged() { qrCanvas.requestPaint(); }
                        }
                    }

                    Rectangle {
                        width: parent.width * 0.12
                        height: width
                        anchors.centerIn: parent
                        color: "#F2F1ED"
                        Text {
                            anchors.centerIn: parent
                            text: "静"
                            color: "#141414"
                            font.family: login.serif
                            font.pixelSize: Math.round(parent.width * 0.6)
                        }
                        Rectangle {
                            width: 3; height: 3
                            color: login.pal.accent
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: parent.height * 0.08
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: login.qrState === "scanned" || login.qrState === "expired"
                        color: "#F2F1ED"
                        opacity: 0.94
                        Column {
                            anchors.centerIn: parent
                            width: parent.width * 0.72
                            spacing: 10
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: login.qrState === "scanned" ? "请于掌端确认"
                                    : login.qrState === "expired" ? "码纹已逾时" : "码纹不可用"
                                color: "#141414"
                                font.family: login.serif
                                font.pixelSize: 22
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: login.qrState === "scanned" ? "确认后即自动入室"
                                    : "点击左侧「刷新码纹」重新获取"
                                color: "#5C141414"
                                font.family: login.serif
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                Column {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 176
                        height: 34
                        source: login.darkTheme
                            ? "qrc:/branding/wordmark-ink.png"
                            : "qrc:/branding/wordmark.png"
                        sourceSize.width: 312
                        sourceSize.height: 60
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "STILLE ARCHIVE · 2026"
                        color: login.pal.ink3
                        font.family: login.serifLatin
                        font.pixelSize: 9
                        font.letterSpacing: 2
                    }
                }
            }

            // -------- credential panel
            Column {
                anchors.centerIn: parent
                width: parent.width * 0.8
                spacing: 26
                visible: login.mode === "credential"

                Text {
                    text: "凭 证 入 室"
                    color: login.pal.ink
                    font.family: login.serif
                    font.pixelSize: 34
                    font.weight: Font.ExtraLight
                }
                Text {
                    text: login.credMode === "sms" ? "SMS Verification · TLS 1.3"
                        : "Session Cookie · TLS 1.3"
                    color: login.pal.ink3
                    font.family: login.serifLatin
                    font.pixelSize: 10
                    font.letterSpacing: 1.8
                }

                Column {
                    width: parent.width
                    spacing: 26
                    visible: login.credMode === "sms"

                    Item {
                        width: parent.width
                        height: 36
                        Text {
                            text: "通讯号码"
                            color: login.pal.ink3
                            font.family: login.serif
                            font.pixelSize: 10
                            font.letterSpacing: 1.8
                        }
                        TextInput {
                            id: phoneInput
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            color: login.pal.ink
                            selectionColor: login.pal.accent
                            font.family: login.serif
                            font.pixelSize: 16
                            clip: true
                        }
                        Ghost { target: phoneInput; label: "+86 138 0000 0000" }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: login.pal.faint
                        }
                    }

                    Item {
                        width: parent.width
                        height: 36
                        Text {
                            text: "六位验码"
                            color: login.pal.ink3
                            font.family: login.serif
                            font.pixelSize: 10
                            font.letterSpacing: 1.8
                        }
                        TextInput {
                            id: smsInput
                            anchors.left: parent.left
                            anchors.right: sendBtn.left
                            anchors.bottom: parent.bottom
                            color: login.pal.ink
                            selectionColor: login.pal.accent
                            font.family: login.serif
                            font.pixelSize: 16
                            clip: true
                        }
                        Text {
                            id: sendBtn
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            text: "获取验码"
                            color: login.pal.ink2
                            font.family: login.serif
                            font.pixelSize: 12
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: login.sendCode()
                            }
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: login.pal.faint
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10
                    visible: login.credMode === "cookie"

                    Item {
                        width: parent.width
                        height: 36
                        Text {
                            text: "__csrf"
                            color: login.pal.ink3
                            font.family: login.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 1.8
                        }
                        TextInput {
                            id: csrfInput
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            color: login.pal.ink
                            selectionColor: login.pal.accent
                            font.family: login.serifLatin
                            font.pixelSize: 14
                            clip: true
                        }
                        Ghost { target: csrfInput; label: "复制 __csrf 的值" }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: login.pal.faint
                        }
                    }

                    Item {
                        width: parent.width
                        height: 36
                        Text {
                            text: "MUSIC_U"
                            color: login.pal.ink3
                            font.family: login.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 1.8
                        }
                        TextInput {
                            id: musicInput
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            echoMode: TextInput.Password
                            color: login.pal.ink
                            selectionColor: login.pal.accent
                            font.family: login.serifLatin
                            font.pixelSize: 14
                            clip: true
                        }
                        Ghost { target: musicInput; label: "复制 MUSIC_U 的值" }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: login.pal.faint
                        }
                    }

                    Text {
                        width: parent.width
                        text: "两个值分别从浏览器 Cookies 复制；仅写入本地 session 表（0600）。"
                        color: login.pal.ink3
                        font.family: login.serif
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                }

                Item {
                    width: parent.width
                    height: 20
                    Text {
                        text: "确认入室 →"
                        color: login.pal.ink
                        font.family: login.serif
                        font.pixelSize: 14
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: login.submitCredential()
                    }
                }

                Text {
                    width: parent.width
                    visible: login.errorMsg.length > 0
                    text: login.errorMsg.substring(0, 160)
                    color: login.pal.accent
                    font.family: login.serif
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }

            // -------- guest panel
            Column {
                anchors.centerIn: parent
                width: parent.width * 0.72
                spacing: 24
                visible: login.mode === "guest"

                Text {
                    text: "暂借片刻静默"
                    color: login.pal.ink
                    font.family: login.serif
                    font.pixelSize: 34
                    font.weight: Font.ExtraLight
                }
                Text {
                    width: parent.width
                    text: "无需通行凭证，以访客身份阅览今日策展、检索曲目并试听可用音源。"
                    color: login.pal.ink2
                    font.family: login.serif
                    font.pixelSize: 13
                    lineHeight: 1.9
                    wrapMode: Text.WordWrap
                }
                Item {
                    width: parent.width
                    height: 20
                    Text {
                        text: "由此入室 →"
                        color: login.pal.ink
                        font.family: login.serif
                        font.pixelSize: 14
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: login.guestEntered()
                    }
                }
            }
        }

        // ------------------------------------------------ right: placard
        Column {
            width: parent.width * 0.22
            spacing: 28

            Row {
                spacing: 8
                Rectangle {
                    width: 5; height: 5; radius: 2.5
                    color: login.pal.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: login.statusText
                    color: login.pal.ink2
                    font.family: login.serif
                    font.pixelSize: 11
                }
            }

            Text {
                visible: login.nickname.length > 0
                text: login.nickname + " · 正式通行"
                color: login.pal.ink
                font.family: login.serif
                font.pixelSize: 15
            }

            Text {
                width: parent.width
                text: login.statusCopy
                color: login.pal.ink3
                font.family: login.serif
                font.pixelSize: 11
                lineHeight: 1.9
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                visible: login.lastCode.length > 0
                text: "最近状态码 · " + login.lastCode
                color: login.pal.ink3
                font.family: login.serifLatin
                font.pixelSize: 9
                font.letterSpacing: 1
            }

            Text {
                width: parent.width
                visible: login.errorMsg.length > 0
                text: login.errorMsg.substring(0, 120)
                color: login.pal.accent
                font.family: login.serif
                font.pixelSize: 9
                wrapMode: Text.WordWrap
            }

            Item { width: 1; height: 24 }

            Column {
                width: parent.width
                spacing: 6
                Text {
                    text: "版本：v2.6 / Lossless"
                    color: login.pal.ink3
                    font.family: login.serifLatin
                    font.pixelSize: 10
                }
                Text {
                    text: "协议：端到端加密认证"
                    color: login.pal.ink3
                    font.family: login.serif
                    font.pixelSize: 10
                }
                Text {
                    text: "编目：NO. 11 / 2026"
                    color: login.pal.ink3
                    font.family: login.serifLatin
                    font.pixelSize: 10
                }
            }
        }
    }

    TextEdit {
        id: clip
        visible: false
    }

    component Ghost: Text {
        property var target
        property string label
        anchors.left: target.left
        anchors.bottom: target.bottom
        anchors.bottomMargin: 3
        visible: target.text.length === 0
        text: label
        color: login.pal.ink3
        font.family: login.serif
        font.pixelSize: 15
    }
}
