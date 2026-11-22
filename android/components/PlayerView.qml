import QtQuick

Item {
    id: root
    property var app
    readonly property var themeColors: app.pal
    readonly property var track: app.currentTrack

    Item {
        id: meta
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 16
        height: 88

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 14

            Item {
                width: 38
                height: 38
                anchors.top: parent.top
                anchors.topMargin: 2
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: root.themeColors.faint
                    border.width: 1
                }
                Image {
                    id: coverImage
                    anchors.fill: parent
                    anchors.margins: 3
                    source: app.currentCover || ""
                    sourceSize.width: 96
                    sourceSize.height: 96
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: source.toString().length > 0 && status === Image.Ready
                }
                StampArt {
                    anchors.fill: parent
                    visible: !app.currentCover || coverImage.status !== Image.Ready
                    themeColors: root.themeColors
                    trackId: root.track.id
                }
            }

            Column {
                width: parent.width - 52
                spacing: 3

                Text {
                    text: "NO. " + app.padNumber(app.trackIndex + 1) + " · " + (root.track.tag || "网易云音乐")
                    color: root.themeColors.secondary
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 10
                    font.letterSpacing: 2.0
                }
                Text {
                    width: parent.width
                    text: root.track.title
                    color: root.themeColors.ink
                    font.family: root.themeColors.serif
                    font.pixelSize: 18
                    font.weight: Font.Normal
                    font.letterSpacing: 1.6
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: root.track.artist + (root.track.album ? " · " + root.track.album : "")
                          + (root.track.year ? " (" + root.track.year + ")" : "")
                    color: root.themeColors.secondary
                    font.family: root.themeColors.serif
                    font.pixelSize: 12
                    font.letterSpacing: 0.9
                    elide: Text.ElideRight
                }
            }
        }

        Row {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            spacing: 12

            Text {
                text: app.quality
                color: root.themeColors.secondary
                font.family: root.themeColors.serifLatin
                font.pixelSize: 10
                font.letterSpacing: 1.7
            }
            Text {
                text: app.formatTime(app.position) + " / " + app.formatTime(app.duration)
                color: root.themeColors.ink
                opacity: 0.72
                font.family: root.themeColors.serifLatin
                font.pixelSize: 10
                font.letterSpacing: 1.3
            }
        }
    }

    Item {
        id: lyricZone
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: meta.bottom
        anchors.bottom: horizon.top
        anchors.leftMargin: 24
        anchors.rightMargin: 24

        property real pressX: 0
        property real pressY: 0

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 0

            Text {
                width: parent.width
                text: app.previousLyric ? app.previousLyric.text : ""
                color: root.themeColors.ink
                opacity: 0.34
                font.family: root.themeColors.serif
                font.pixelSize: 12
                font.letterSpacing: 1.2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                visible: text.length > 0

            }

            Item { width: 1; height: 18 }

            Text {
                id: activeLyric
                width: parent.width
                text: app.activeLyric ? app.activeLyric.text : ""
                color: root.themeColors.ink
                font.family: root.themeColors.serif
                font.pixelSize: 25
                font.weight: Font.ExtraLight
                font.letterSpacing: 2.2
                lineHeight: 1.5
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                opacity: 1
                onTextChanged: activeReveal.restart()
            }

            SequentialAnimation {
                id: activeReveal
                NumberAnimation {
                    target: activeLyric
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 520
                    easing.type: Easing.OutQuart
                }
            }

            Text {
                width: parent.width
                text: app.activeLyric ? app.activeLyric.sub : ""
                color: root.themeColors.secondary
                opacity: 0.76
                font.family: root.themeColors.serifLatin
                font.pixelSize: 10
                font.italic: true
                font.letterSpacing: 0.4
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: text.length > 0
                height: visible ? implicitHeight + 10 : 0
            }

            Text {
                width: parent.width
                text: app.nextLyric ? app.nextLyric.text : ""
                color: root.themeColors.ink
                opacity: 0.24
                font.family: root.themeColors.serif
                font.pixelSize: 12
                font.letterSpacing: 1.2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                visible: text.length > 0

            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: "左右轻滑 · 切歌"
            color: root.themeColors.secondary
            opacity: 0.35
            font.family: root.themeColors.serif
            font.pixelSize: 10
            font.letterSpacing: 1.8
        }

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                lyricZone.pressX = mouse.x;
                lyricZone.pressY = mouse.y;
            }
            onReleased: (mouse) => {
                var dx = mouse.x - lyricZone.pressX;
                var dy = mouse.y - lyricZone.pressY;
                if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy)) {
                    if (dx > 0) app.previousTrack();
                    else app.nextTrack();
                } else if (dy > 80 && Math.abs(dy) > Math.abs(dx)) {
                    app.setView("home");
                }
            }
            onDoubleClicked: app.togglePlay()
        }
    }

    Horizon {
        id: horizon
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomBar.top
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        height: 44
        themeColors: root.themeColors
        progress: app.progress
        duration: app.duration
        currentSeconds: app.position
        onSeek: (ratio) => app.seek(ratio)
    }

    Item {
        id: bottomBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.bottomMargin: 16
        height: 88

        Column {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            spacing: 0

            StilleTextButton {
                themeColors: root.themeColors
                text: "索引 ↗"
                horizontalAlignment: Text.AlignLeft
                onClicked: app.setView("home")
            }
            StilleTextButton {
                themeColors: root.themeColors
                text: "队列 · QUEUE (" + app.tracks.length + ")"
                horizontalAlignment: Text.AlignLeft
                onClicked: app.queueOpen = true
            }
        }

        Column {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0

            Row {
                spacing: 0
                anchors.right: parent.right
                Rectangle {
                    width: 4; height: 4; radius: 2
                    color: app.playing ? root.themeColors.accent : "transparent"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item { width: 6; height: 1 }
                StilleTextButton {
                    themeColors: root.themeColors
                    text: app.playing ? "暂停" : "播放"
                    horizontalAlignment: Text.AlignRight
                    onClicked: app.togglePlay()
                }
                Text {
                    text: " / "
                    color: root.themeColors.faint
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
                StilleTextButton {
                    themeColors: root.themeColors
                    text: "下一曲"
                    horizontalAlignment: Text.AlignRight
                    onClicked: app.nextTrack()
                }
            }

            Row {
                spacing: 0
                anchors.right: parent.right
                Rectangle {
                    width: 4; height: 4; radius: 2
                    color: app.isFavorite(root.track) ? root.themeColors.accent : "transparent"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item { width: 6; height: 1 }
                StilleTextButton {
                    themeColors: root.themeColors
                    text: app.isFavorite(root.track) ? "已收藏" : "收藏"
                    horizontalAlignment: Text.AlignRight
                    onClicked: app.toggleFavorite(root.track)
                }
                Text {
                    text: " · "
                    color: root.themeColors.faint
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
                StilleTextButton {
                    themeColors: root.themeColors
                    text: app.currentMode.label
                    horizontalAlignment: Text.AlignRight
                    onClicked: app.cycleMode()
                }
            }
        }
    }

    Rectangle {
        id: queue
        anchors.fill: parent
        color: root.themeColors.canvas
        visible: app.queueOpen
        z: 60
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

        Column {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 20
            anchors.bottomMargin: 20

            Item {
                width: parent.width
                height: 44
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "待播队列 · QUEUE (" + app.tracks.length + ")"
                    color: root.themeColors.secondary
                    font.family: root.themeColors.serifLatin
                    font.pixelSize: 12
                    font.letterSpacing: 2.0
                }
                StilleTextButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    themeColors: root.themeColors
                    text: "收起 —"
                    horizontalAlignment: Text.AlignRight
                    onClicked: app.queueOpen = false
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.themeColors.faint }

            Flickable {
                width: parent.width
                height: parent.height - 54
                contentWidth: width
                contentHeight: queueColumn.height
                clip: true

                Column {
                    id: queueColumn
                    width: parent.width
                    Repeater {
                        model: app.tracks
                        delegate: Item {
                            width: queueColumn.width
                            height: 54
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: root.themeColors.ultra
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: app.padNumber(index + 1)
                                color: index === app.trackIndex ? root.themeColors.accent : root.themeColors.secondary
                                font.family: root.themeColors.serifLatin
                                font.pixelSize: 10
                                font.letterSpacing: 1.4
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 36
                                anchors.right: durationText.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title
                                color: root.themeColors.ink
                                font.family: root.themeColors.serif
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                            Text {
                                id: durationText
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: app.formatTime(modelData.duration)
                                color: root.themeColors.secondary
                                font.family: root.themeColors.serifLatin
                                font.pixelSize: 10
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    app.playTrack(index, true);
                                    app.queueOpen = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
