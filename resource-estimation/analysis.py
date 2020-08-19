#/usr/bin/python

import numpy as np
import os

from parse_pla import *
from mpmct_resources import *

# How many random qROMs to generate?
n_random_qroms = 2

# Number of address bits
n = 5
q = 3

for qrom_idx in range(n_random_qroms):
	file_string = f"n{n}-q{q}-qrom_idx{qrom_idx}"
	addresses = np.random.choice(2 ** n, 2 ** q, replace=False)
	qrom_to_pla(n, addresses, file_string)

	# Run through EXORCISM-4
	cli_string = f"./abc -q \"read_pla -x {file_string}.pla; &get; &exorcism /dev/stdout\" >> {file_string}.exorcised"
	os.system(cli_string)

	resources = pla_to_resource_counts(f"{file_string}.exorcised")

	guess_resources = {
		"WIDTH" : 0, # TODO
		"D" : (2**q) * mpmct_depth(n),
		"TC" : (2**q) * mpmct_t_c(n),
		"TD" : (2**q) * mpmct_t_d(n),
		"H" : (2**q) * mpmct_h_c(n),
		"CNOT" : (2**q) * mpmct_cnot_c(n)
	}


	print("Guess for resources: ")
	print(guess_resources)
	print("Resources after optimization")
	print(resources)
	print()