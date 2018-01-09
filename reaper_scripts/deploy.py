import os
import sys
import shutil

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
TOGGLE_FILE_NAME = 'Electribe - Toggle.lua'
TOGGLE_FILE = SCRIPT_DIR + os.path.sep + TOGGLE_FILE_NAME
PAD_FILE_NAME = 'Electribe - Pad.lua'
PAD_FILE = SCRIPT_DIR + os.path.sep + PAD_FILE_NAME
ENCODER_FILE_NAME = 'Electribe - Encoder.lua'
ENCODER_FILE = SCRIPT_DIR + os.path.sep + ENCODER_FILE_NAME
MODALS = [
    'mute_modal',
    'erase_modal',
    'copy_modal',
    'edit_modal'
]
ENCODER_ACTIONS = [
    'transpose',
    'program_change',
    'select_chord',
    'select_voicing'
]
TRACKS = map(str, range(1, 16 + 1))

def run(out_dir):
    #create modal actions
    for modal in MODALS:
        out_file_name = TOGGLE_FILE_NAME.replace('.lua', ' ({0}).lua'.format(modal))
        out_file = out_dir + os.path.sep + out_file_name
        shutil.copy2(TOGGLE_FILE, out_file)

    #create track actions
    for track in TRACKS:
        out_file_name = PAD_FILE_NAME.replace('.lua', ' ({0}).lua'.format(track))
        out_file = out_dir + os.path.sep + out_file_name
        shutil.copy2(PAD_FILE, out_file)

    #create encoder actions
    for action in ENCODER_ACTIONS:
        out_file_name = ENCODER_FILE_NAME.replace('.lua', ' ({0}).lua'.format(action))
        out_file = out_dir + os.path.sep + out_file_name
        shutil.copy2(ENCODER_FILE, out_file)

run(os.path.abspath(sys.argv[1]))
