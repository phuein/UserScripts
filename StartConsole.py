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

delay = 3  # Don't repeat anything faster than this in seconds.
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

if DEBUG:
    windowName = "Untitled - Notepad"
    processName = "notepad.exe"


# Return hwnd or None.
def enumHandler(hwnd, lParam):
    global handle

    if "RetroArch" in win32gui.GetWindowText(hwnd):
        handle = hwnd


while True:
    # No gamepads connected. Must have one.
    if len(inputs.devices.gamepads) == 0:
        DEBUG and print('No gamepads connected.')
        sleep(delay)
        inputs.devices._detect_gamepads()
        continue

    # Only the first gamepad to register will catch.
    try:
        gamepad = inputs.devices.gamepads[0]
        events = gamepad.read()
    except Exception as e:
        DEBUG and print(e)
        # Try again.
        continue

    for e in events:
        if e.code in toggles:
            toggles[e.code] = e.state

        # Check if all 4 are down.
        if all(v != 0 for v in toggles.values()):
            # Don't retry too fast.
            if time() - t < 3:
                continue

            # Check if RetroArch isn't running.
            lst = os.popen("tasklist").read()  # Long string of all procs.

            if processName not in lst:
                os.startfile(processName)
            else:
                # Find window.
                win32gui.EnumWindows(enumHandler, None)
                # Bring to front.
                if handle:
                    win32gui.SetForegroundWindow(handle)
                # Reset hwnd.
                handle = None

            # Reset timer.
            t = time()
