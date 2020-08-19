#/usr/bin/python

import numpy as np
import os

from parse_pla import qrom_to_pla

# How many random qROMs to generate?
n_random_qroms = 5

# Number of address bits
n = 5
q = 4

for qrom_idx in range(n_random_qroms):
	file_string = f"n{n}-q{q}-qrom_idx{qrom_idx}"
	addresses = np.random.choice(2 ** n, 2 ** q, replace=False)
	qrom_to_pla(n, addresses, file_string)

	# Run through EXORCISM-4
	cli_string = f"./abc -q \"read_pla -x {file_string}.pla; &get; &exorcism /dev/stdout\" >> {file_string}.exorcised"
	os.system(cli_string)
