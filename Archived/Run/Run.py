import wx

app = wx.App(0)
dialog = wx.MessageDialog(None, 'There is nowhere you can run.', 'Warning', wx.OK|wx.ICON_ERROR)
res = dialog.ShowModal()
dialog.Destroy()
app.MainLoop()

### To build the EXE for fun: ###
# mkdir ./venv
# python -m venv ./venv
# python -m pip install pyinstaller wxPython
# pyinstaller Run.py --noconsole -F --clean --icon "running.ico" --upx-dir "C:\upx-3.96-win64" --exclude-module select --exclude-module unicodedata --exclude-module socket --exclude-module decimal --exclude-module overlapped --exclude-module ssl --exclude-module asyncio --exclude-module queue --exclude-module ctypes --exclude-module multiprocessing --exclude-module pyexpat --exclude-module hashlib --exclude-module lzma --exclude-module bz2 --exclude-module libssl-1_1 --exclude-module libcrypto-1_1 --exclude-module libffi-7