{ config, pkgs, ... }:

let
  quick-ask-deepseek = pkgs.writeShellApplication {
    name = "quick-ask-deepseek";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      curl
      jq
    ];
    text = ''
      set -euo pipefail

      deepseek_key_file="${config.age.secrets.deepseek-api-key.path or "$HOME/.config/opencode/deepseek-api-key"}"

      if [ "$#" -lt 1 ]; then
        printf 'Usage: quick-ask-deepseek <question>\n' >&2
        exit 2
      fi

      if [ ! -r "$deepseek_key_file" ]; then
        printf 'Missing DeepSeek API key: %s\n' "$deepseek_key_file" >&2
        exit 1
      fi

      question="$*"

      answer="$(
        jq -n \
          --arg question "$question" \
          '{
            model: "deepseek-v4-flash",
            messages: [
              {role: "system", content: "Answer directly and concisely."},
              {role: "user", content: $question}
            ],
            stream: false
          }' |
          curl -fsS "https://api.deepseek.com/chat/completions" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $(tr -d '\n' < "$deepseek_key_file")" \
            -d @- |
          jq -r '.choices[0].message.content // .error.message // "No response text found."'
      )"

      printf '%s\n' "$answer"
    '';
  };

  quick-ask-qml = pkgs.writeText "quick-ask-shell.qml" ''
    import Quickshell
    import Quickshell.Io
    import Quickshell.Wayland
    import QtQuick

    ShellRoot {
      PanelWindow {
        id: window
        visible: true
        focusable: true
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quick-ask"
        width: 720
        height: shell.windowHeight
        color: "transparent"

        anchors.top: true
        margins.top: screen.height * 0.18

        property int innerMargin: 13

        Rectangle {
          anchors.fill: parent
          color: "#fdf6e3"
          radius: 10
          border.width: 1
          border.color: "#002b36"

          Item {
            anchors.fill: parent
            anchors.margins: window.innerMargin

            Text {
              id: prompt
              x: 0
              y: (54 - window.innerMargin * 2 - height) / 2
              width: implicitWidth
              color: "#586e75"
              font.family: "JetBrains Mono"
              font.pixelSize: 16
              text: shell.showingAnswer ? "DeepSeek:" : "Ask:"
            }

            TextInput {
              id: question
              visible: !shell.showingAnswer && !query.running && !shell.measuring
              anchors.left: prompt.right
              anchors.leftMargin: 10
              anchors.right: parent.right
              y: prompt.y
              color: "#657b83"
              selectionColor: "#eee8d5"
              selectedTextColor: "#586e75"
              font.family: "JetBrains Mono"
              font.pixelSize: 16
              focus: true
              clip: true
              selectByMouse: true
              horizontalAlignment: TextInput.AlignLeft

              Keys.onReturnPressed: shell.ask()
              Keys.onEnterPressed: shell.ask()
              Keys.onEscapePressed: Qt.quit()

              Text {
                visible: question.text.length === 0 && !query.running
                anchors.fill: parent
                color: "#93a1a1"
                font: question.font
                text: "DeepSeek Flash..."
              }
            }

            Flickable {
              visible: shell.showingAnswer
              anchors.left: prompt.right
              anchors.leftMargin: 10
              anchors.right: parent.right
              height: parent.height - prompt.y
              y: prompt.y
              contentWidth: width
              contentHeight: answer.paintedHeight
              clip: true

              TextEdit {
                id: answer
                width: parent.width
                height: paintedHeight
                y: 0
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                color: "#657b83"
                selectedTextColor: "#586e75"
                selectionColor: "#eee8d5"
                font.family: "JetBrains Mono"
                font.pixelSize: 16
                horizontalAlignment: TextEdit.AlignLeft

                Keys.onEscapePressed: Qt.quit()
              }
            }

            Text {
              visible: query.running || shell.measuring
              anchors.left: prompt.right
              anchors.leftMargin: 10
              y: prompt.y
              color: "#93a1a1"
              font.family: "JetBrains Mono"
              font.pixelSize: 16
              text: "asking..."
            }

            TextEdit {
              id: measureAnswer
              opacity: 0
              enabled: false
              x: prompt.width + 10
              y: -10000
              width: parent.width - x
              text: shell.pendingAnswer
              wrapMode: TextEdit.Wrap
              font.family: "JetBrains Mono"
              font.pixelSize: 16
            }
          }
        }

        Item {
          id: shell
          property bool showingAnswer: false
          property bool measuring: false
          property real windowHeight: 54
          property string pendingAnswer: ""

          function ask() {
            const text = question.text.trim();
            if (text.length === 0 || query.running) return;
            shell.showingAnswer = false;
            shell.measuring = false;
            shell.windowHeight = 54;
            query.exec(["${quick-ask-deepseek}/bin/quick-ask-deepseek", text]);
          }

          function showAnswer(text) {
            shell.pendingAnswer = text.trim();
            shell.measuring = true;
            measureTimer.restart();
          }
        }

        Timer {
          id: measureTimer
          interval: 16
          repeat: false
          onTriggered: {
            shell.windowHeight = Math.min(420, Math.max(54, window.innerMargin * 2 + prompt.y + measureAnswer.paintedHeight));
            answer.text = shell.pendingAnswer;
            shell.showingAnswer = true;
            shell.measuring = false;
            answer.forceActiveFocus();
          }
        }

        Shortcut {
          sequence: "Esc"
          onActivated: Qt.quit()
        }

        Process {
          id: query
          stdout: StdioCollector {
            onStreamFinished: {
              shell.showAnswer(this.text);
            }
          }
          stderr: StdioCollector {
            onStreamFinished: {
              if (this.text.trim().length > 0) {
                shell.showAnswer(this.text);
              }
            }
          }
        }
      }
    }
  '';

  quick-ask = pkgs.writeShellApplication {
    name = "quick-ask";
    runtimeInputs = with pkgs; [
      quickshell
    ];
    text = ''
      set -euo pipefail

      exec quickshell --path ${quick-ask-qml}
    '';
  };
in
{
  home.packages = [
    quick-ask
    quick-ask-deepseek
  ];
}
