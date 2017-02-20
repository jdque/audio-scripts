import os
import re
import random
import argparse
import wave as wave_module
from copy import deepcopy
from lxml import etree
from lxml import objectify

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
NS = '{tx}'
NOTES = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
NOTE_MAP = dict(zip(range(0, len(NOTES)), NOTES))

def midi_to_note(num):
    num_notes = len(NOTES)
    octave = num / num_notes
    note = NOTE_MAP[num % num_notes]
    return note + str(octave)

class ElementFactory:
    def __init__(self):
        self.loop_template = objectify.parse(SCRIPT_DIR + os.path.sep + 'loop.xml').getroot().loop
        self.wave_template = objectify.parse(SCRIPT_DIR + os.path.sep + 'wave.xml').getroot().wave
        self.split_template = objectify.parse(SCRIPT_DIR + os.path.sep + 'split.xml').getroot().split
        self.group_template = objectify.parse(SCRIPT_DIR + os.path.sep + 'group.xml').getroot().group

    def loop(self, name, start, end):
        loop = deepcopy(self.loop_template)
        loop.set(NS + 'name', str(name))
        loop.set(NS + 'start', str(start))
        loop.set(NS + 'end', str(end))

        return loop

    def wave(self, id_, filename, loops):
        wave = deepcopy(self.wave_template)
        wave.set(NS + 'id', str(id_))
        wave.set(NS + 'path', filename)

        for loop in loops:
            wave.append(loop)

        return wave

    def split(self, note_name, wave, opt_loop_idx=-1):
        split = deepcopy(self.split_template)
        split.set(NS + 'key', note_name)
        split.set(NS + 'wave', wave.get(NS + 'id'))
        if opt_loop_idx >= 0:
            split.set(NS + 'loop', str(opt_loop_idx))

        return split

    def group(self, name, splits):
        assert len(splits) > 0

        group = deepcopy(self.group_template)
        group.set(NS + 'name', str(name))
        #TODO - don't assume splits are in order
        group.range.set(NS + 'lowkey', splits[0].get(NS + 'key'))
        group.range.set(NS + 'highkey', splits[-1].get(NS + 'key'))

        for split in splits:
            group.append(split)

        return group

    def simple_group(self, note_name, wave):
        split = self.split(note_name, wave, None)
        name = wave.get(NS + 'path').split('.')[0]
        group = self.group(name, [split])

        return group

class Program:
    def __init__(self):
        self.tree = objectify.parse(SCRIPT_DIR + os.path.sep + 'program.xml')
        self.root = self.tree.getroot()
        self.factory = ElementFactory()
        self.cur_wave_id = 0

    @staticmethod
    def auto_generate(filenames, instr_layout=None, root_note=0, exclude=None):
        program = Program()

        num_rows = len(instr_layout)
        num_cols = len(instr_layout[0])
        note_range = range(root_note, root_note + num_cols * num_rows)
        layout_notes = list(reversed([note_range[i:i+num_rows] for i in xrange(0, len(note_range), num_rows)]))
        used_filenames = set()

        for row in xrange(0, num_rows):
            for col in xrange(0, num_cols):
                instr = instr_layout[row][col]
                note = layout_notes[row][col]
                if instr is None:
                    continue
                file_filters = [
                    lambda file: file not in used_filenames,
                    lambda file: re.search(instr['pattern'], file) is not None,
                    lambda file: exclude is None or re.search(exclude, file) is None
                ]
                matches = filter(lambda file: all(f(file) for f in file_filters), filenames)
                if len(matches) == 0:
                    if instr['required']:
                        raise RuntimeError("Cannot generate complete sample set")
                    else:
                        continue
                random_filename = random.choice(matches)
                used_filenames.add(random_filename)
                program.add_sample_group(random_filename, note)

        return program

    def add_sample_group(self, filename, note):
        self.cur_wave_id += 1
        wave = self.factory.wave(self.cur_wave_id, filename, [])
        self.root.insert(0, wave)

        group = self.factory.simple_group(midi_to_note(note), wave)
        self.root.append(group)

    def add_splice_group(self, file_path, root_note, num_intervals):
        loops = []
        wav = wave_module.open(file_path, 'r')
        interval = wav.getnframes() / num_intervals
        for i in xrange(0, num_intervals):
            start = i * interval
            end = (i + 1) * interval
            loop = self.factory.loop(i + 1, start, end)
            loops.append(loop)
        wav.close()

        self.cur_wave_id += 1
        wave = self.factory.wave(self.cur_wave_id, os.path.basename(file_path), loops)
        self.root.insert(0, wave)

        splits = []
        for i in xrange(0, len(loops)):
            split = self.factory.split(midi_to_note(root_note + i), wave, i)
            splits.append(split)

        group = self.factory.group(wave.get(NS + 'path').split('.')[0], splits)
        self.root.append(group)

    def to_xml_tree(self):
        stripped_root = etree.fromstring(etree.tostring(self.root).replace('xmlns:tx="tx"', ''))
        tree = etree.ElementTree(stripped_root)
        return tree

def generate(path, recursive=False):
    bd = {
        'pattern': re.compile('(kick|kik|bdrum)', flags=re.IGNORECASE),
        'required': True
    }
    sn = {
        'pattern': re.compile('(snare|snr)', flags=re.IGNORECASE),
        'required': True
    }
    rm = {
        'pattern': re.compile('(rim|stick)', flags=re.IGNORECASE),
        'required': False
    }
    ch = {
        'pattern': re.compile('(closed|hat_c|cht)', flags=re.IGNORECASE),
        'required': True
    }
    oh = {
        'pattern': re.compile('(open|hat_o|oht)', flags=re.IGNORECASE),
        'required': True
    }
    to = {
        'pattern': re.compile('(tom)', flags=re.IGNORECASE),
        'required': False
    }
    pc = {
        'pattern': re.compile('(perc|prc|clap|bell|conga|clave|shaker|triangle|snap)', flags=re.IGNORECASE),
        'required': False
    }

    instr_layout = [
        [None, None, None, None],
        [ pc ,  pc ,  pc ,  pc ],
        [ pc ,  pc ,  ch ,  oh ],
        [ bd ,  rm ,  sn , None],
    ]

    exclude = re.compile('MaxV', flags=re.IGNORECASE)

    paths = [root for root, dirs, files in os.walk(path)] if recursive else [path]
    for path in paths:
        dir_name = os.path.basename(path)
        dir_files = os.listdir(path)
        try:
            program = Program.auto_generate(
                filenames=dir_files,
                instr_layout=instr_layout,
                root_note=36,
                exclude=exclude
                )
            out_tree = program.to_xml_tree()
            out_path = path + os.path.sep + dir_name + ".txprog"
            out_tree.write(out_path, pretty_print=True)
            print("Success: " + path)
        except:
            print("Fail: " + path)

def clean(path, recursive=False):
    paths = [root for root, dirs, files in os.walk(path)] if recursive else [path]
    for path in paths:
        for file in os.listdir(path):
            if file.find('.txprog') >= 0:
                file_path = path + os.path.sep + file
                os.remove(file_path)

def splice(file_path):
    program = Program()
    program.add_splice_group(
        file_path=file_path,
        root_note=36,
        num_intervals=16
        )
    out_tree = program.to_xml_tree()
    out_path = file_path.replace('.wav', '.txprog')
    out_tree.write(out_path, pretty_print=True)
    print("Success: " + file_path)

#------------------------------------------------------------------------------

argparser = argparse.ArgumentParser()
argparser.add_argument('command', choices=['generate', 'clean', 'splice'])
argparser.add_argument('path')
argparser.add_argument('--recursive', action='store_true', default=False)

args = argparser.parse_args()
command = args.command
path = os.path.abspath(args.path)
recursive = args.recursive

if command == 'generate':
    generate(path, recursive=recursive)
elif command == 'clean':
    clean(path, recursive=recursive)
elif command == 'splice':
    splice(path)