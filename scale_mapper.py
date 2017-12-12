import sys
import os

NOTES = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
LOW = 0
HIGH = 127

scales = {
	"Aeolian": [0, 2, 3, 5, 7, 8, 10],
	"Blues": [0, 2, 3, 4, 5, 7, 9, 10, 11],
	"Diatonic Minor": [0, 2, 3, 5, 7, 8, 10],
	"Dorian": [0, 2, 3, 5, 7, 9, 10],
	"Harmonic Minor": [0, 2, 3, 5, 7, 8, 11],
	"Indian": [0, 1, 1, 4, 5, 8, 10],
	"Locrian": [0, 1, 3, 5, 6, 8, 10],
	"Lydian": [0, 2, 4, 6, 7, 9, 10],
	"Major": [0, 2, 4, 5, 7, 9, 11],
	"Melodic Minor": [0, 2, 3, 5, 7, 8, 9, 10, 11],
	"Minor": [0, 2, 3, 5, 7, 8, 10],
	"Mixolydian": [0, 2, 4, 5, 7, 9, 10],
	"Natural Minor": [0, 2, 3, 5, 7, 8, 10],
	"Pentatonic Major": [0, 2, 4, 7, 9],
	"Pentatonic Minor": [0, 3, 5, 7, 10],
	"Phrygian": [0, 1, 3, 5, 7, 8, 10],
	"Turkish": [0, 1, 3, 5, 7, 10, 11]
}

def note_to_midi(note_name, octave):
	return len(NOTES) * (octave + 1) + NOTES.index(note_name)

def generate(root_note, scale):
	notes = range(LOW, HIGH + 1)

	mod_scale = list(scale)
	mod_scale.append(12)
	intervals = []
	for i in range(1, len(mod_scale)):
		intervals.append(mod_scale[i] - mod_scale[i - 1])

	if root_note < HIGH:
		cur_int_idx = 0
		for i in range(notes.index(root_note) + 1, len(notes)):
			new_note = min(notes[i - 1] + intervals[cur_int_idx], HIGH)
			notes[i] = new_note
			cur_int_idx = 0 if cur_int_idx == len(intervals) - 1 else cur_int_idx + 1

	if root_note > LOW:
		cur_int_idx = len(intervals) - 1
		for i in reversed(range(0, notes.index(root_note))):
			new_note = max(notes[i + 1] - intervals[cur_int_idx], LOW)
			notes[i] = new_note
			cur_int_idx = len(intervals) - 1 if cur_int_idx == 0 else cur_int_idx - 1

	return notes

out_path = os.path.abspath(sys.argv[1])

for octave in [3]:
	for scale_name, scale_arr in zip(scales.keys(), scales.values()):
		filename = scale_name + ' - ' + 'C' + str(octave) + '.txt'
		file_path = os.path.join(out_path, filename)
		print('CREATING ' + filename)
		with open(file_path, 'wt') as f:
			notes = generate(note_to_midi('C', octave), scale_arr)
			for note in notes:
				f.write(str(note) + '\n')

#print(generate(note_to_midi('C', 3), scales['major']))