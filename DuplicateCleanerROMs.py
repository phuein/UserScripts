# Clean up ROM duplicates in current folder, such as:
# ['3 Ninjas Kick Back (U).smc', '3 Ninjas Kick Back (E).sfc']
# and
# ['3 Ninjas Kick Back (U).smc', '3 Ninjas Kick Back (USA) [!}.smc']
# Ideally leaving us with only unique (U) versions.
# NOTE: I personally use dupeGuru to remove content identical files and so on.

import os
from glob import glob

# Get all files in current directory.
files = glob('*.*')
# Get the non-unique part, the game name.
files = [f.split(' (')[0] for f in files]
# Remove duplicates.
files = list(set(files))

# Remove all E version duplicates.
[[os.remove(l) for l in glob(f+' (E*.*')] for f in files if len(glob(f + ' (*.*')) > 1]
# Remove all USA version duplicates.
[[os.remove(l) for l in glob(f+' (US*.*')] for f in files if len(glob(f + ' (*).*')) > 1]
