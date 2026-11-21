import QtQuick

// One lyric line with the "Typography Flow" motion:
// - tokens light up in reading order with a small upward displacement
// - the active line starts with a soft-focus halo and sharpens to full ink
// - past and future lines settle into lower contrast
Item {
    id: line
    property var pal
    property string serif: "Noto Serif CJK SC"
    property string serifLatin: "Noto Serif"
    property string text: ""
    property string sub: ""
    property bool active: false
    // index - currently active line; negative is past, positive is upcoming
    property int distance: 0
    property int stagger: 24
    readonly property var tokens: tokenize(text)

    width: parent ? parent.width : 0
    implicitHeight: flow.implicitHeight + (subLabel.visible ? subLabel.implicitHeight + 8 : 0)
    height: implicitHeight

    // 0 -> 1 sharpens the line as it becomes current; the halo uses (1 - sharpen)
    property real sharpen: active ? 0 : 1
    // Delegates are created with opacity 0 so the first frame also flows in.
    property bool revealed: false
    Component.onCompleted: {
        if (active) sharpenAnim.start();
        revealed = true;
    }
    onActiveChanged: {
        if (active) {
            sharpen = 0;
            sharpenAnim.restart();
        }
    }

    NumberAnimation {
        id: sharpenAnim
        target: line
        property: "sharpen"
        to: 1
        duration: 520
        easing.type: Easing.OutQuart
    }

    function tokenize(value) {
        var out = [];
        var source = value || "";
        // CJK characters become individual tokens; Latin words stay whole so
        // we never break a word in the middle. Spaces/punctuation are kept.
        var re = /[\u3400-\u9fff\u3040-\u30ff]|[A-Za-z0-9'’]+|\s+|[^\s]/g;
        var match;
        while ((match = re.exec(source)) !== null)
            out.push(match[0]);
        return out;
    }

    // Soft-focus ghosts: three offset copies of the line at low opacity read
    // as a light blur without depending on a GPU-only effect backend. They
    // fade out as `sharpen` reaches 1.
    Repeater {
        model: 3
        Text {
            width: line.width
            text: line.text
            color: line.pal.ink3
            font.family: line.serif
            font.pixelSize: 30
            wrapMode: Text.WordWrap
            x: index === 0 ? -1 : (index === 1 ? 1 : 0)
            y: index === 2 ? 1 : 0
            scale: 1.012
            opacity: line.active ? 0.075 * (1 - line.sharpen) : 0
            visible: opacity > 0.002
            Behavior on opacity {
                NumberAnimation { duration: 360; easing.type: Easing.OutQuart }
            }
        }
    }

    Flow {
        id: flow
        width: line.width
        spacing: 0

        Repeater {
            model: line.tokens

            Text {
                property int tokenIndex: index
                text: modelData
                color: line.active
                    ? line.pal.ink
                    : (Math.abs(line.distance) <= 1 ? line.pal.ink2 : line.pal.ink3)
                font.family: line.serif
                font.pixelSize: 30
                font.weight: line.active ? Font.Light : Font.ExtraLight

                opacity: !line.revealed ? 0
                    : line.active ? 1
                    : (line.distance < 0 ? 0.60
                    : (line.distance > 0 ? 0.54 : 0.40))
                // Flow owns x/y; use a transform so the stagger never breaks
                // the line's layout.
                property real driftY: !line.revealed ? 4
                    : (line.active ? 0 : (line.distance < 0 ? -2 : 2))
                transform: Translate { y: driftY }

                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: line.active ? tokenIndex * line.stagger : 0 }
                        NumberAnimation {
                            duration: 520
                            easing.type: Easing.OutQuart
                        }
                    }
                }
                Behavior on driftY {
                    SequentialAnimation {
                        PauseAnimation { duration: line.active ? tokenIndex * line.stagger : 0 }
                        NumberAnimation {
                            duration: 620
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                Behavior on color { ColorAnimation { duration: 420; easing.type: Easing.OutCubic } }
            }
        }
    }

    Text {
        id: subLabel
        anchors.top: flow.bottom
        anchors.topMargin: 8
        width: line.width
        text: line.sub
        visible: line.active && line.sub.length > 0
        color: line.pal.ink3
        font.family: line.serifLatin
        font.pixelSize: 12
        font.letterSpacing: 0.4
        font.italic: true
        opacity: line.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
    }
}
