import time
import subprocess, platform
import ctypes

# Windows log event.
import win32api
import win32con
import win32evtlog
import win32security
import win32evtlogutil

DEBUG = False

# Settings and data for ping testing.
class Tester:
    hostPing        = '192.168.1.2'     # The hostname or IP to ping.
    maxFailures     = 2                 # How many ping failures before considered unreachable.
    maxSuccess      = 1                 # How many ping successes before considered reachable.
    waitTry         = 2                 # Time in seconds to wait before next ping test.

    pingResult      = ''                # Last return from ping.
    failed          = 0                 # How many times ping has failed.
    successes       = 0                 # How many times ping has succeded.
    away            = False             # Device is away - can't be reached. Must become away first, to be considered "back".
# Instance.
tester = Tester()

# Returns ping verbosity.
def ping(host):
    # res = subprocess.check_output(['ping', '-n', '1', host])
    process = subprocess.Popen(['ping', '-n', '1', host],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT)
    returncode = process.wait()
    res = process.stdout.read()
    return str(res)

# Creates a log event in Windows.
# e - Default 1 reachable.
def logEvent(e=1):
    ph = win32api.GetCurrentProcess()
    th = win32security.OpenProcessToken(ph, win32con.TOKEN_READ)
    my_sid = win32security.GetTokenInformation(th, win32security.TokenUser)[0]
    
    applicationName = 'iSpy Phone on Network Checker'
    eventID     = e                                             # 0 - Away. 1 - Reachable.
    category    = 7	                                            # Network
    myType      = win32evtlog.EVENTLOG_INFORMATION_TYPE
    descr       = None                                          # ['A warning', 'An even more dire warning']
    data        = None                                          # 'Application\0Data'.encode('ascii')

    win32evtlogutil.ReportEvent(
        applicationName,
        eventID,
        eventCategory=category,
        eventType=myType,
        strings=descr,
        data=data,
        sid=my_sid
    )

# Check for Windows station locked.
user32 = ctypes.windll.User32
# Another option to check this:
# OpenDesktop = user32.OpenDesktopA
# SwitchDesktop = user32.SwitchDesktop
# DESKTOP_SWITCHDESKTOP = 0x0100
def isLocked():
    first = user32.GetForegroundWindow() in {0, 919676}
    time.sleep(1)
    second = user32.GetForegroundWindow() in {0, 919676}
    DEBUG and print('isLocked:', user32.GetForegroundWindow(), 'first & second:', first, second)
    return first and second
    # hDesktop = OpenDesktop("default", 0, False, DESKTOP_SWITCHDESKTOP)
    # unlocked = SwitchDesktop(hDesktop)
    # return not unlocked

# Check if process is running.
def isRunning(name):
    s = subprocess.check_output('tasklist', shell=True)
    return name in str(s)

# Main loop.
print("Running Proximity Pinger...")
while True:
    result = ping(tester.hostPing) # Device IP or hostname.

    oldState = tester.away

    # Router can't see the device.
    if 'Destination host unreachable.' in result:
        tester.failed       += 1
        tester.successes    = 0
        DEBUG and tester.failed <= 6 and print('Unreachable:', tester.failed)
    # Reachable.
    else:
        tester.failed       = 0
        tester.successes    += 1
        DEBUG and tester.successes <= 6 and print('Reachable:', tester.successes)
    
    # Device considered reachable.
    if tester.successes == tester.maxSuccess:
        tester.away = False
        # Log Kill to windows, if changed from away to reachable,
        # and iSpy is running.
        DEBUG and print('oldState:', oldState, 'isLocked:', isLocked(), 'isRunning:', isRunning('iSpy.exe'))
        if oldState is not tester.away and isRunning('iSpy.exe'):
            logEvent()
    
    # Device considered away.
    if tester.failed == tester.maxFailures:
        tester.away = True
        # Log Start to windows, if changed from reachable to away,
        # and station locked, and iSpy is running.
        DEBUG and print('oldState:', oldState, 'isLocked:', isLocked(), 'isRunning:', isRunning('iSpy.exe'))
        if oldState is not tester.away and isLocked() and not isRunning('iSpy.exe'):
            logEvent(0)
    
    # Wait until next ping test.
    time.sleep(tester.waitTry)
