import time
import subprocess, platform
import ctypes

# Command line arguments.
import sys
import argparse

# Windows log event.
import win32api
import win32con
import win32evtlog
import win32security
import win32evtlogutil

# Parse cmd line args.
parser = argparse.ArgumentParser(description="Track if station is locked, or instead if phone is connected to WiFi, \
                                            and if iSpy isn't running, then run iSpy! \
                                            Otherwise, exit iSpy.")

parser.add_argument('--debug',
                    default = False,
                    choices = ['true', 'false'],
                    metavar = 'false',
                    help = 'Print debug messages.')

parser.add_argument('--ping',
                    default = '',
                    metavar = '192.168.1.2',
                    help = 'IP of the phone to be reachable. \
                            Find yours in your router settings page. Disabled by default.')

parser.add_argument('--away',
                    default = False,
                    choices = ['true', 'false'],
                    metavar = 'false',
                    help = 'Only uses the phone to exit iSpy when returning home, \
                            otherwise uses station lock.')

parser.add_argument('--program',
                    default = 'iSpy.exe',
                    metavar = 'iSpy.exe',
                    help = 'Checks if this program is running or not.')

args = parser.parse_args()

### For the booleans, any arg value will be considered True, such as --debug 3ggww5. ###
# Print more information. Defaults to False.
DEBUG = args.debug and True
# IP / hostname of phone to reach on the network.
IP = args.ping
# Program to find if running. Defaults to iSpy.exe.
PROGRAM = args.program
# Only use phone when returning to exit iSpy.
AWAY = args.away and True

# Settings and data for ping testing.
class Tester:
    waitTry         = 5                 # Time in seconds to wait before next check.
    state           = False             # Station is locked, or device is unreachable. (Must lock/leave first to activate.)
    program         = PROGRAM           # The process filename+extension that's searched for.
    awayMode        = AWAY              # True will not start iSpy when phone is unreachable, only.
    returned        = False             # Avoid starting iSpy when station locked but awayMode phone has returned, until next lock.

    host            = IP                # The hostname or IP to ping.
    maxFailures     = 2                 # How many ping failures before considered unreachable.
    maxSuccess      = 1                 # How many ping successes before considered reachable.

    pingResult      = ''                # Last returned value from ping.
    failed          = 0                 # How many times ping has failed.
    successes       = 0                 # How many times ping has succeded.

# Make an instance.
tester = Tester()

# Returns ping verbosity.
def ping(host):
    # res = subprocess.check_output(['ping', '-n', '1', host])
    process = subprocess.Popen(['ping', '-n', '1', host],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT)
    process.wait() # Returns event code.
    res = process.stdout.read()
    # DEBUG and print('ping result:', res)
    return str(res)

# Creates a log event in Windows.
def logEvent(e, desc=''):
    ph = win32api.GetCurrentProcess()
    th = win32security.OpenProcessToken(ph, win32con.TOKEN_READ)
    my_sid = win32security.GetTokenInformation(th, win32security.TokenUser)[0]
    win32api.CloseHandle(th)

    applicationName = 'Automatic Security Tracker'
    eventID     = e                                             # 0 - Stop. 1 - Start.
    category    = 7	                                            # Network
    myType      = win32evtlog.EVENTLOG_INFORMATION_TYPE
    descr       = [desc]                                        # ['A warning', 'An even more dire warning']
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

    v = 'START' if e else 'STOP'
    print('Logged event', v, e)

# Check if the Windows station is locked.
def isLocked():
    hand = win32evtlog.OpenEventLog(None, "Security")
    flags = win32evtlog.EVENTLOG_BACKWARDS_READ | win32evtlog.EVENTLOG_SEQUENTIAL_READ
    records = win32evtlog.ReadEventLog(hand, flags, 0)
    win32evtlog.CloseEventLog(hand)

    # Find latest lock or unlock event.
    for record in records:
        eid = record.EventID

        # Unlocked.
        if (eid == 4801):
            return False
        # Locked.
        elif (eid == 4800):
            return True

    # Assume state hasn't changed.
    return tester.state

# Check if process is running.
def isRunning(name):
    s = subprocess.check_output('tasklist', shell=True)
    return name in str(s)

### Main loop. ###
print('Running Automatic Security Tracker...')

if tester.host:
    if tester.awayMode:
        mode_msg = 'Station Lock & Phone returning only.'
    else:
        mode_msg = 'Phone Reachability.'
else:
    mode_msg = 'Station Lock.'
print('Tracking for', mode_msg)

# Let task load properly.
while True:
    running = isRunning(tester.program)

    # Remember the previous state.
    # Avoid closing iSpy just because station is unlocked / phone is reachable
    # during normal computer use.
    oldState = tester.state

    # Find phone on network.
    if tester.host:
        result = ping(tester.host) # Device IP or hostname.

        # DEBUG and print('oldState:', oldState, 'isRunning:', running)

        # Router can't see the device.
        if 'Destination host unreachable.' in result:
            tester.failed       += 1
            tester.successes    = 0
            # DEBUG and tester.failed <= 5 and print('Unreachable:', tester.failed)

        # Reachable.
        else:
            tester.failed       = 0
            tester.successes    += 1
            # DEBUG and tester.successes <= 5 and print('Reachable:', tester.successes)

        # Device considered unreachable.
        if tester.failed == tester.maxFailures:
            tester.state = True

            # Log START to windows, if iSpy is not running.
            if not running:
                # Except in away mode.
                if not tester.awayMode:
                    logEvent(1)

        # Device considered reachable.
        elif tester.successes == tester.maxSuccess:
            tester.state = False

            # Log STOP to windows, only if it was previously away,
            # and if iSpy is running.
            if oldState is not tester.state and running:
                logEvent(0)
                # Avoid restarting iSpy on station lock checks, until locked again.
                tester.returned = True

    if not tester.host or tester.awayMode:
        # Or only check for station locked.
        locked = isLocked()

        DEBUG and print('oldState:', oldState, 'isRunning:', running, 'isLocked:', locked)

        # Log START to windows, if station is locked, and iSpy is not running.
        if locked and not running:
            # Unless returned on awayMode.
            if not tester.returned:
                tester.state = True
                logEvent(1)

        # Log STOP to windows, only if it was previously locked,
        # if station is unlocked, and iSpy is running.
        elif not locked:
            tester.state = False
            # Reset returning for next lock in awayMode.
            tester.returned = False

            if oldState is not tester.state:
                logEvent(0)

    # Wait until next check.
    time.sleep(tester.waitTry)
