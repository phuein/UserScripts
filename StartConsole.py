"""
This script idles in the background,
listening to gamepad (XBox One Controller) button presses,
to activate or bring-to-front RetroArch in Windows 10.
"""

import inputs
from time import sleep, time
import os
import win32gui

DEBUG = False

delay = 5  # Don't repeat anything faster than this in seconds.
t = 0

# Press down all four front buttons to activate.
toggles = {
    "BTN_TR":   0,
    "BTN_TL":   0,
    "ABS_RZ":   0,
    "ABS_Z":    0,
}

windowName = "RetroArch"
processName = "retroarch.exe"
handle = None
activated = False

if DEBUG:
    windowName = "Untitled - Notepad"
    processName = "notepad.exe"


# Return hwnd or None.
def enumHandler(hwnd, lParam):
    global handle

    if "RetroArch" in win32gui.GetWindowText(hwnd):
        handle = hwnd

# Load or bring process forward.


def getProcess():
    global processName, handle

    # Check if RetroArch isn't running.
    # Long string of all procs.
    lst = os.popen("tasklist").read()

    if processName not in lst:
        os.startfile(processName)
    else:
        try:
            # Find window.
            win32gui.EnumWindows(enumHandler, None)
            # Bring to front.
            if handle:
                win32gui.SetForegroundWindow(handle)
            # Reset hwnd.
            handle = None
        except Exception as e:
            print(e)

# Check if the corrent button combination is pressed on a gamepad,
# and start or bring the process forward.


def checkGamepads(events):
    for e in events:
        if e.code in toggles:
            print(e.code, e.state)
            toggles[e.code] = e.state

    # Check if all 4 are down.
    if all(v != 0 for v in toggles.values()):
        # Avoid repetition by resetting the tracker.
        for k, v in toggles.items():
            toggles[k] = 0
        print('starting!')
        getProcess()


# Track pressed gamepad buttons.
# Refresh tracker every interval.
while True:
    # No gamepads connected. Wait and retry.
    if len(inputs.devices.gamepads) == 0:
        DEBUG and print('No gamepads connected.')
        sleep(delay)
        inputs.devices._detect_gamepads()
        continue

    # Reduce CPU usage.
    sleep(0.01)

    # Check every gamepad.
    for gamepad in inputs.devices.gamepads:
        try:
            events = gamepad.read()
        except Exception as e:
            DEBUG and print(e)
            # Reset detected gamepads.
            inputs.devices.gamepads = []
            break

        checkGamepads(events)
