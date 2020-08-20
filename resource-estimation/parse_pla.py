from mpmct_resources import *

def qrom_to_pla(n, ones_addresses, filename):
	"""
	Translate an n-bit qROM that contains a 1 at multiple addresses to a .pla file.

	Parameters:
		n (int): Number of address bits
		ones_addresses (list(int))): Locations of 1s in the memory
		filename (str): Name prefix for the output file

	Outputs:
		A .pla file of the circuit representation of the specified qROM. 
	"""

	with open(f"{filename}.pla", "w") as pla_file:
		# Preamble - specify number of bits, and type
		pla_file.write(f".i {n}\n")
		pla_file.write(f".o 1\n")
		pla_file.write(".type esop\n")

		for address in ones_addresses:
			# Get n-bit binary representation
			binary_rep = format(address, f"0{n}b")
			pla_file.write(f"{binary_rep} 1\n")

		pla_file.write(".e\n")


def pla_to_resource_counts(filename):
	mpmct_tally = {}

	resources = {
		"WIDTH" : 0, # TODO
		"D" : 0,
		"TC" : 0,
		"TD" : 0,
		"H" : 0,
		"CNOT" : 0
	}

	num_total_controls = -1

	# Use the output PLA file to determine how many MPMCTs with each
	# different number of possible controls
	with open(filename, "r") as exorcised_file:
		gate_lines = exorcised_file.readlines()[11:-1]

		for line in gate_lines:
			control_string = line.strip().split(" ")[0]
			num_controls = len(control_string) - control_string.count("-")

			if num_total_controls == -1:
				num_total_controls = num_controls

			if num_controls not in resources:
				mpmct_tally[num_controls] = 1
			else:
				mpmct_tally[num_controls] += 1


	# Number of aux qubits needed; it is at most n - 1, but depends on the
	# largest MPMCT after optimization. Suppose that has c controls, then we can 
	# use the idle n - c as aux qubits as well, so total is 2*c - n - 1
	largest_num_controls = max(list(mpmct_tally.keys()))
	num_aux_required = max(0, 2 * largest_num_controls - num_total_controls - 1)

	# Total qubits required is n + 1 + aux
	resources["WIDTH"] = num_total_controls + 1 + num_aux_required 

	# Go through the dictionary now and get resource counts for everything
	for num_controls, num_occs in mpmct_tally.items():
		# Special case: CNOT
		if num_controls == 1:
			resources["D"] += 1
			resources["CNOT"] += num_occs
		# Special case: Toffoli; use the one in the primer
		# TODO: update to add T-depth 1 version
		elif num_controls == 2:
			resources["D"] += num_occs * 10
			resources["TC"] += num_occs * 7
			resources["TD"] += num_occs * 3
			resources["H"] += num_occs * 2
			resources["CNOT"] += num_occs * 7
		# For k >= 4, can use the formulas from 1902.01329
		# TODO: add explicit resource counts for 3 controls; also look into whether
		# we can do the larger ones without any aux qubits 
		else:
			resources["D"] += num_occs * mpmct_depth(num_controls)
			resources["TC"] += num_occs * mpmct_t_c(num_controls)
			resources["TD"] += num_occs * mpmct_t_d(num_controls)
			resources["H"] += num_occs * mpmct_h_c(num_controls)
			resources["CNOT"] += num_occs * mpmct_cnot_c(num_controls)

	return resources