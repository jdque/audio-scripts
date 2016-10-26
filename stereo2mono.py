import sys
import os
import subprocess

def process_folder(folder):
	filenames = os.listdir(folder)

	for filename in filenames:
		in_file = os.path.join(folder, filename)
		out_file = os.path.join(folder, "temp.wav")
		subprocess.call("sox" + " " + in_file + " " + out_file + " remix -")
		os.remove(in_file)
		os.rename(out_file, in_file)
		print in_file

if len(sys.argv) > 1:
	for folder in sys.argv[1:]:
		process_folder(folder)
else:
	process_folder(os.getcwd())
