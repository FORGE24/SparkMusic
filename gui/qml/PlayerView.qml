import QtQuick
import QtQuick.Layouts

// View 3 — 沉浸播放页: transport on the left, timed lyrics in the centre,
// read-only metadata on the right.
Item {
    id: player
    property var pal
    property string serif
    property string serifLatin
    property var track
    property string coverUrl: ""
    property int trackNumber: 1
    property bool playing: false
    property int position: 0
    property var lyrics: []
    property int activeIndex: 0
    property string playbackNote: ""
    property bool favorited: false
    property real volume: 0.68
    property real titleReveal: 1
    property real artistReveal: 1
    property real specReveal: 1
    property string coverShown: ""

    signal togglePlay()
    signal next()
    signal prev()
    signal back()
    signal favoriteToggled()
    signal volumeRequested(real value)

    function clock(seconds) {
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function activeLine() {
        var lines = player.lyrics ? player.lyrics : [];
        var active = 0;
        for (var i = 0; i < lines.length; i++)
            if (lines[i].time <= position) active = i;
        return active;
    }

    // Keep the line being sung at the vertical centre of the lyric stage.
    function centerActive() {
        if (activeIndex >= 0 && activeIndex < lyricsView.count)
            lyricsView.positionViewAtIndex(activeIndex, ListView.Center);
    }

    function refreshActive() {
        var next = activeLine();
        if (next === activeIndex) return;
        activeIndex = next;
        centerActive();
    }

    Component.onCompleted: {
        activeIndex = activeLine();
        Qt.callLater(centerActive);
        primeCover();
        if (track) metaReveal.start();
    }
    onLyricsChanged: {
        refreshActive();
        Qt.callLater(centerActive);
    }
    onHeightChanged: Qt.callLater(centerActive)
    onTrackChanged: {
        if (!track) return;
        titleReveal = 0;
        artistReveal = 0;
        specReveal = 0;
        metaReveal.restart();
    }
    onCoverUrlChanged: swapCover(coverUrl)

    // Archive transition: the old cover steps back, the new one enters from
    // the right; titles re-set with a short letter-spacing settle.
    function primeCover() {
        coverShown = coverUrl;
        coverIn.source = coverUrl;
        coverIn.x = 0;
        coverIn.opacity = coverUrl.length > 0 ? 1 : 0;
    }

    function swapCover(url) {
        if (!coverIn || !coverOut || url === coverShown) return;
        if (coverSwap.running) {
            coverSwap.stop();
            coverOut.source = coverIn.source;
            coverOut.opacity = coverIn.opacity;
        }
        coverOut.source = coverShown;
        coverOut.opacity = coverShown.length > 0 ? 1 : 0;
        coverOut.x = 0;
        coverIn.source = url;
        coverIn.opacity = 0;
        coverIn.x = 14;
        coverShown = url;
        coverSwap.restart();
    }

    ParallelAnimation {
        id: coverSwap
        NumberAnimation {
            target: coverOut
            property: "x"
            to: -14
            duration: 650
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: coverOut
            property: "opacity"
            to: 0
            duration: 650
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: coverIn
            property: "x"
            from: 14; to: 0
            duration: 650
            easing.type: Easing.OutQuart
        }
        NumberAnimation {
            target: coverIn
            property: "opacity"
            to: 1
            duration: 650
            easing.type: Easing.OutQuart
        }
        onFinished: {
            coverOut.source = "";
            coverOut.opacity = 0;
        }
    }

    SequentialAnimation {
        id: favoritePulse
        NumberAnimation {
            target: favoriteButton
            property: "extraLetterSpacing"
            from: 0; to: 1.8
            duration: 180
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: favoriteButton
            property: "extraLetterSpacing"
            from: 1.8; to: 0
            duration: 340
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: metaReveal
        NumberAnimation {
            target: player
            property: "titleReveal"
            from: 0; to: 1
            duration: 450
            easing.type: Easing.OutCubic
        }
        SequentialAnimation {
            PauseAnimation { duration: 70 }
            NumberAnimation {
                target: player
                property: "artistReveal"
                from: 0; to: 1
                duration: 550
                easing.type: Easing.OutCubic
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 150 }
            NumberAnimation {
                target: player
                property: "specReveal"
                from: 0; to: 1
                duration: 750
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        anchors.fill: parent
        spacing: 40

        // ------------------------------------------------------ transport
        Column {
            width: parent.width * 0.22
            spacing: 42

            Column {
                width: parent.width
                spacing: 12
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: "TRANSPORT / 播控"
                    color: player.pal.ink3
                    font.family: player.serif
                    font.pixelSize: 10
                    font.letterSpacing: 2.2
                }
                SwissButton {
                    width: parent.width
                    pal: player.pal; serif: player.serif
                    latin: player.playing ? "Pause" : "Play"
                    zh: player.playing ? "暂停" : "播放"
                    active: true
                    onClicked: player.togglePlay()
                }
                SwissButton {
                    width: parent.width
                    pal: player.pal; serif: player.serif
                    latin: "Next"; zh: "下一曲"
                    onClicked: player.next()
                }
                SwissButton {
                    width: parent.width
                    pal: player.pal; serif: player.serif
                    latin: "Prev"; zh: "上一曲"
                    onClicked: player.prev()
                }
                SwissButton {
                    id: favoriteButton
                    width: parent.width
                    pal: player.pal; serif: player.serif
                    latin: "Favorite"
                    zh: player.favorited ? "已收藏" : "收藏"
                    active: player.favorited
                    onClicked: {
                        player.favoriteToggled();
                        favoritePulse.restart();
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 20
                SwissButton {
                    width: parent.width
                    pal: player.pal; serif: player.serif
                    latin: "Loop"
                    zh: "列表循环"
                    onClicked: {}
                }
                Item {
                    id: volumeControl
                    width: parent.width
                    height: 58

                    property real shownVolume: player.volume * 100
                    Behavior on shownVolume {
                        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                    }

                    Column {
                        id: volumeLabels
                        width: parent.width
                        spacing: 3

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignRight
                            text: "VOLUME"
                            color: player.pal.ink3
                            font.family: player.serifLatin
                            font.pixelSize: 10
                            font.letterSpacing: 2.1
                        }

                        Item {
                            width: parent.width
                            height: 20

                            Text {
                                anchors.right: volumeValue.left
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "音量"
                                color: player.pal.ink2
                                font.family: player.serif
                                font.pixelSize: 15
                            }
                            Text {
                                id: volumeValue
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 42
                                horizontalAlignment: Text.AlignRight
                                text: Math.round(volumeControl.shownVolume) + "%"
                                color: player.pal.ink2
                                font.family: player.serifLatin
                                font.pixelSize: 11
                                font.letterSpacing: 0.4
                            }
                        }
                    }

                    Item {
                        id: volumeTrack
                        anchors.right: parent.right
                        anchors.top: volumeLabels.bottom
                        anchors.topMargin: 8
                        width: 110
                        height: 14

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 1
                            color: player.pal.faint
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * player.volume
                            height: 1
                            color: player.pal.ink
                            Behavior on width {
                                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                            }
                        }
                        Rectangle {
                            width: 5; height: 5; radius: 2.5
                            color: player.pal.accent
                            anchors.verticalCenter: parent.verticalCenter
                            x: (parent.width - 5) * player.volume
                            Behavior on x {
                                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function setVolume(px) {
                                var ratio = Math.max(0, Math.min(1, px / width));
                                player.volumeRequested(ratio);
                            }
                            onPressed: (mouse) => setVolume(mouse.x)
                            onPositionChanged: (mouse) => {
                                if (pressed) setVolume(mouse.x);
                            }
                        }
                    }
                }
                SwissButton {
                    width: parent.width
                    pal: player.pal; serif: player.serif
                    latin: "Index"; zh: "返回目录"
                    onClicked: player.back()
                }
            }
        }

        // --------------------------------------------------------- lyrics
        Item {
            width: parent.width * 0.52
            height: parent.height

            ListView {
                id: lyricsView
                anchors.fill: parent
                anchors.topMargin: 40
                anchors.bottomMargin: 40
                clip: true
                model: player.lyrics
                spacing: 26
                // Space above/below lets the first and last lines reach the
                // centre instead of being pinned to the viewport edge.
                topMargin: height * 0.5
                bottomMargin: height * 0.5
                boundsBehavior: Flickable.StopAtBounds
                Behavior on contentY {
                    enabled: !lyricsView.dragging && !lyricsView.flicking
                    NumberAnimation { duration: 460; easing.type: Easing.OutCubic }
                }
                onCountChanged: Qt.callLater(player.centerActive)
                delegate: LyricLine {
                    width: lyricsView.width
                    pal: player.pal
                    serif: player.serif
                    serifLatin: player.serifLatin
                    text: modelData.text
                    sub: modelData.sub
                    active: index === player.activeIndex
                    distance: index - player.activeIndex
                }
            }

            Connections {
                target: player
                function onPositionChanged() {
                    player.refreshActive();
                }
            }

            // Paper-coloured fades at both edges so the lyric column never
            // shows a hard cut through a line's descenders.
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 76
                gradient: Gradient {
                    GradientStop { position: 0.0; color: player.pal.canvas }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 76
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: player.pal.canvas }
                }
            }
        }

        // ------------------------------------------------------ metadata
        Column {
            width: parent.width * 0.22
            spacing: 26

            Item {
                width: 88; height: 88

                Rectangle {
                    anchors.fill: parent
                    border.color: player.pal.faint
                    border.width: 1
                    color: "transparent"
                }

                // Album cover, cropped to the Swiss square. Two layers let the
                // old archive card step back while the new one enters.
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: player.pal.canvas
                    clip: true

                    Image {
                        id: coverOut
                        anchors.fill: parent
                        sourceSize.width: 176
                        sourceSize.height: 176
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        opacity: 0
                        visible: status === Image.Ready && opacity > 0.001
                    }
                    Image {
                        id: coverIn
                        anchors.fill: parent
                        sourceSize.width: 176
                        sourceSize.height: 176
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        opacity: 0
                        visible: status === Image.Ready && opacity > 0.001
                    }
                }
                // A 1px low-opacity ink line sits inside the paper matte so a
                // saturated cover still belongs to the sheet.
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: "transparent"
                    border.color: player.pal.ink2
                    border.width: 1
                    opacity: 0.24
                }

                Rectangle {
                    width: 46; height: 46; radius: 23
                    anchors.centerIn: parent
                    color: "transparent"
                    border.color: player.pal.ink2
                    border.width: 1
                    visible: coverOut.status !== Image.Ready && coverIn.status !== Image.Ready
                }
                Rectangle {
                    width: 4; height: 4
                    anchors.centerIn: parent
                    color: player.pal.accent
                    visible: coverOut.status !== Image.Ready && coverIn.status !== Image.Ready
                }
            }

            Column {
                width: parent.width
                spacing: 5
                Text {
                    text: "NOW PLAYING · NO. " + ("0" + player.trackNumber).slice(-2)
                    color: player.pal.ink3
                    font.family: player.serifLatin
                    font.pixelSize: 10
                    font.letterSpacing: 1.7
                    opacity: player.titleReveal
                }
                Text {
                    width: parent.width
                    text: player.track ? player.track.title : ""
                    color: player.pal.ink
                    font.family: player.serif
                    font.pixelSize: 21
                    wrapMode: Text.WordWrap
                    opacity: player.titleReveal
                    transform: Translate { y: (1 - player.titleReveal) * 8 }
                    font.letterSpacing: 1.0 + 2.4 * (1 - player.titleReveal)
                }
                Text {
                    width: parent.width
                    text: player.track ? player.track.artist : ""
                    color: player.pal.ink2
                    font.family: player.serif
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    opacity: player.artistReveal
                    transform: Translate { y: (1 - player.artistReveal) * 6 }
                    font.letterSpacing: 0.2 + 1.2 * (1 - player.artistReveal)
                }
                Text {
                    width: parent.width
                    text: player.track ? (player.track.year.length > 0
                        ? player.track.album + " (" + player.track.year + ")"
                        : player.track.album) : ""
                    color: player.pal.ink3
                    font.family: player.serif
                    font.pixelSize: 11
                    opacity: player.specReveal
                    transform: Translate { y: (1 - player.specReveal) * 6 }
                }
            }

            Column {
                width: parent.width
                spacing: 10
                opacity: player.specReveal
                transform: Translate { y: (1 - player.specReveal) * 6 }
                Text {
                    text: player.clock(player.position) + " / "
                          + player.clock(player.track ? player.track.duration : 0)
                    color: player.pal.ink2
                    font.family: player.serifLatin
                    font.pixelSize: 11
                    font.letterSpacing: 1
                }
                Repeater {
                    model: [["规格", "FLAC 24-bit · 96kHz"], ["输出", "CoreAudio 独占模式"]]
                    Row {
                        width: parent.width
                        spacing: 12
                        Text {
                            text: modelData[0]
                            color: player.pal.ink3
                            font.family: player.serif
                            font.pixelSize: 10
                        }
                        Text {
                            text: modelData[1]
                            color: player.pal.ink2
                            font.family: player.serif
                            font.pixelSize: 10
                        }
                    }
                }
                Text {
                    width: parent.width
                    visible: player.playbackNote.length > 0
                    text: player.playbackNote
                    color: player.pal.accent
                    font.family: player.serif
                    font.pixelSize: 11
                    lineHeight: 1.8
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: player.track ? player.track.note : ""
                    color: player.pal.ink3
                    font.family: player.serif
                    font.pixelSize: 12
                    lineHeight: 1.9
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
