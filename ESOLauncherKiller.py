import os
from time import sleep

while True:
    foundGame = os.popen('tasklist /FI "IMAGENAME eq eso64.exe" 2>NUL | \
        find /I /N "eso64.exe"').read()

    foundLauncher = os.popen('tasklist /FI "IMAGENAME eq Bethesda.net_Launcher.exe" 2>NUL | \
        find /I /N "Bethesda.net_Launcher.exe"').read()

    if foundGame and foundLauncher:
        # k = os.popen('taskkill /IM Bethesda.net_Launcher.exe').read()
        os.popen('taskkill /F /IM Bethesda.net_Launcher.exe')

    sleep(60 * 1)  # Minutes.
