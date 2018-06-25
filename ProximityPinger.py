import time
import subprocess, platform

# Windows log event.
import win32api
import win32con
import win32evtlog
import win32security
import win32evtlogutil

# Settings and data for ping testing.
class Tester:
    hostPing        = '192.168.1.2'     # The hostname or IP to ping.
    maxFailures     = 4                 # How many ping failures before considered unreachable.
    maxSuccess      = 4                 # How many ping successes before considered reachable.
    waitTry         = 5                 # Time in seconds to wait before next ping test.

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

# Main loop.
print("Running Proximity Pinger...")
while True:
    result = ping(tester.hostPing) # Device IP or hostname.

    oldState = tester.away

    # Router can't see the device.
    if 'Destination host unreachable.' in result:
        tester.failed       += 1
        tester.successes    = 0
    # Reachable.
    else:
        tester.failed       = 0
        tester.successes    += 1
        state               = tester.away        
    
    # Device considered reachable.
    if tester.successes == tester.maxSuccess:
        tester.away = False
        # Log to windows, if changed from away to reachable.
        if oldState == True:
            logEvent()
    
    # Device considered away.
    if tester.failed == tester.maxFailures:
        tester.away = True
        # Log to windows, if changed from reachable to away.
        # if oldState == False:
        #     logEvent(0)
    
    # Wait until next ping test.
    time.sleep(tester.waitTry)