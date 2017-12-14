import os
import sys
import shutil

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
TOGGLE_FILE_NAME = 'Electribe - Toggle.lua'
TOGGLE_FILE = SCRIPT_DIR + os.path.sep + TOGGLE_FILE_NAME
PAD_FILE_NAME = 'Electribe - Pad.lua'
PAD_FILE = SCRIPT_DIR + os.path.sep + PAD_FILE_NAME
MODALS = [
    'edit_track_modal',
    'mute_track_modal',
    'erase_track_modal'
]
TRACKS = range(1, 16 + 1)

def run(out_dir):
    #create modal actions
    for modal in MODALS:
        out_file_name = TOGGLE_FILE_NAME.replace('Toggle', 'Toggle ({0})'.format(modal))
        out_file = out_dir + os.path.sep + out_file_name
        shutil.copy2(TOGGLE_FILE, out_file)

    #create track actions
    for track in TRACKS:
        out_file_name = PAD_FILE_NAME.replace('Pad', 'Pad ({0})'.format(str(track)))
        out_file = out_dir + os.path.sep + out_file_name
        shutil.copy2(PAD_FILE, out_file)

run(os.path.abspath(sys.argv[1]))
