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