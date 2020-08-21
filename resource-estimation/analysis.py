#/usr/bin/python

import numpy as np
import os

from parse_pla import *
from mpmct_resources import *

# How many random qROMs to generate?
n_random_qroms = 1000

# Number of address bits
n_min = 5
n_max = 33

header = ["n", "q", "width", "depth", "tc", "td", "h", "cnot"]

guessed_filename = "guessed_resources.csv"
exorcised_filename = "exorcised_resources.csv"


with open(guessed_filename, "w") as guess_file:
	guess_file.write(",".join(header) + "\n")
	for n in range(n_min, n_max+1):
		# For now
		q = n - 1

		guess_resources = [
			n,
			q,
			2*n, # width
			(2**q) * mpmct_depth(n),
			(2**q) * mpmct_t_c(n),
			(2**q) * mpmct_t_d(n),
			(2**q) * mpmct_h_c(n),
			(2**q) * mpmct_cnot_c(n)
		]

		guess_file.write(",".join([str(x) for x in guess_resources]) + "\n")


with open(exorcised_filename, "w") as exorcised_file:
	exorcised_file.write(",".join(header) + "\n")
	for n in range(n_min, n_max+1):
		print(f"Working on n={n}")
		q = n - 1
		for qrom_idx in range(n_random_qroms):
			file_string = f"n{n}-q{q}-qrom_idx{qrom_idx}"
			addresses = np.random.choice(2 ** n, 2 ** q, replace=False)
			qrom_to_pla(n, addresses, file_string)

			# Run through EXORCISM-4
			cli_string = f"./abc -q \"read_pla -x {file_string}.pla; &get; &exorcism /dev/stdout\" >> {file_string}.exorcised"
			os.system(cli_string)

			resources = pla_to_resource_counts(f"{file_string}.exorcised")

	
			combined_resources = [
				n,
				q,
				resources["WIDTH"], # width
				resources["D"],
				resources["TC"],
				resources["TD"],
				resources["H"],
				resources["CNOT"]
			]

			exorcised_file.write(",".join([str(x) for x in combined_resources]) + "\n")

	# print("Guess for resources: ")
	# print(guess_resources)
	# print("Resources after optimization")
	# print(resources)
	# print()
