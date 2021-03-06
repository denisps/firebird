import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.1
import Firebird.Emu 1.0
import QtQuick.Controls 1.3

Rectangle {
    id: mobileui
    width: 320
    height: 480
    color: "#AAA"

    Component.onCompleted: {
        // FIXME: The toast might not yet be registered here

        if(Emu.getFlashPath() !== ""
            && Emu.getSnapshotPath() !== ""
            && Emu.getBoot1Path() !== "")
            Emu.resume();
    }

    Connections {
        target: Qt.application
        onStateChanged: {
            switch (Qt.application.state)
            {
                case Qt.ApplicationSuspended:
                case Qt.ApplicationHidden:
                    Emu.setPaused(true);
                break;
                case Qt.ApplicationActive:
                    Emu.setPaused(false);
                break;
            }
        }
    }

    ColumnLayout {
        id: sidebar
        // In landscape mode fit whole framebuffer on screen
        width: parent.width/350 > parent.height/240 ? parent.width-320*parent.height/240 : parent.width*0.15
        onWidthChanged: update()
        anchors.bottom: controls.top
        anchors.bottomMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.left: screen.right
        anchors.leftMargin: 0

        SidebarButton {
            id: restartButton

            title: qsTr("Start")
            icon: "qrc:/icons/resources/icons/edit-bomb.png"

            onClicked: Emu.restart();
        }

        SidebarButton {
            id: resetButton

            title: qsTr("Reset")
            icon: "qrc:/icons/resources/icons/system-reboot.png"

            onClicked: Emu.reset();
        }

        SidebarButton {
            id: resumeButton

            title: qsTr("Resume")
            icon: "qrc:/icons/resources/icons/system-suspend-hibernate.png"

            onClicked: Emu.resume()
        }

        SidebarButton {
            id: saveButton

            title: qsTr("Save")
            icon: "qrc:/icons/resources/icons/media-floppy.png"

            MessageDialog {
                id: saveFailedDialog
                title: qsTr("Error")
                text: qsTr("Failed to save changes!")
                icon: StandardIcon.Warning
            }

            MessageDialog {
                id: snapWarnDialog
                title: qsTr("Warning")
                text: qsTr("Flash saved, but no snapshot location configured.\nYou won't be able to resume.")
                icon: StandardIcon.Warning
            }

            onClicked: {
                var flash_path = Emu.getFlashPath();
                var snap_path = Emu.getSnapshotPath();

                if(flash_path === "" || !Emu.saveFlash())
                    saveFailedDialog.visible = true;
                else
                {
                    if(snap_path)
                        Emu.suspend();
                    else
                        snapWarnDialog.visible = true;
                }
            }
        }

    }

    EmuScreen {
        id: screen
        focus: true
        y: 0
        width: parent.width - sidebar.width
        height: width/320*240
        anchors.left: parent.left
        anchors.leftMargin: 0

        Timer {
            interval: 20
            running: true; repeat: true
            onTriggered: screen.update()
        }
    }

    Flickable {
        id: controls
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalAndVerticalFlick
        contentWidth: controlsRow.width
        contentHeight: controlsRow.height
        clip: true
        anchors.top: screen.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0

        Row {
            id: controlsRow

            Rectangle {
                id: mobilecontrol1
                height: keypad.height*controls.width/keypad.width + iosmargin.height
                width: controls.width
                color: keypad.color

                Keypad {
                    id: keypad
                    transform: Scale { origin.x: 0; origin.y: 0; xScale: controls.width/keypad.width; yScale: controls.width/keypad.width }
                }

                Rectangle {
                    id: iosmargin
                    // This is needed to avoid opening the control center
                    height: Qt.platform.os === "ios" ? 20 : 0
                }
            }

            Rectangle {
                height: mobilecontrol1.height
                width: controls.width
                color: keypad.color

                MobileControl2 {
                    id: control2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    //transform: Scale { origin.x: 0; origin.y: 0; xScale: controls.width/keypad.width; yScale: controls.width/keypad.width }
                }
            }
        }
    }

    Rectangle {
        id: toast
        x: 60
        z: 1
        width: message.width+2*5

        anchors.top: parent.bottom
        anchors.topMargin: -90
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 61
        anchors.horizontalCenter: parent.horizontalCenter

        radius: 5
        color: "#d3c7c7"
        border.color: "#e66e6e6e"
        border.width: 3

        opacity: 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            id: message
            text: "Text"
            anchors.centerIn: parent
            font.pixelSize: parent.height / 2

            Component.onCompleted: Emu.registerToast(this)

            Timer {
                id: timer
                interval: 2000
                onTriggered: parent.parent.opacity = 0;
            }

            onTextChanged: {
                parent.opacity = 1;
                timer.restart();
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                timer.stop();
                parent.opacity = 0;
            }
        }
    }
}

