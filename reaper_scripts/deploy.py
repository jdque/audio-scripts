import os
import sys
import shutil

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
TOGGLE_FILENAME = 'Electribe - Toggle.lua'
PAD_FILENAME = 'Electribe - Pad.lua'

out_path = os.path.abspath(sys.argv[1])

#create modal actions
modals = [
    'edit_track_modal',
    'mute_track_modal',
    'erase_track_modal'
]
for modal in modals:
    out_filename = TOGGLE_FILENAME.replace('Toggle', 'Toggle ({0})'.format(modal))
    shutil.copy2(SCRIPT_DIR + os.path.sep + TOGGLE_FILENAME, out_path + os.path.sep + out_filename)

#create track actions
track_nums = range(1, 16 + 1)
for track in track_nums:
    out_filename = PAD_FILENAME.replace('Pad', 'Pad ({0})'.format(str(track)))
    shutil.copy2(SCRIPT_DIR + os.path.sep + PAD_FILENAME, out_path + os.path.sep + out_filename)
