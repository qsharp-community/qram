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


def count_mpmcts(filename):
    """
    Given a .pla file with a list of MPMCT gates, tally up the number
    of gates with each different number of controls

    Parameters:
        filename (str): Name of a .pla-formatted file

    Outputs:
        num_total_controls (int): the maximum number of control bits
        mpmct_tally (dict[int, int])): A dictionary with keys as the number of control bits
            and values as the number of occurences of that many controls in the .pla file. 
    """

    mpmct_tally = {}
    num_total_controls = -1

    # Use the output PLA file to determine how many MPMCTs with each
    # different number of possible controls
    with open(filename, "r") as exorcised_file:
        gate_lines = exorcised_file.readlines()[11:-1]

        for line in gate_lines:
            control_string = line.strip().split(" ")[0]
            num_controls = len(control_string) - control_string.count("-")

            if num_total_controls == -1:
                num_total_controls = len(control_string)

            if num_controls not in mpmct_tally:
                mpmct_tally[num_controls] = 1
            else:
                mpmct_tally[num_controls] += 1

    return num_total_controls, mpmct_tally


def pla_to_resource_counts(filename):
    """
    Given a .pla file, determine the amount of Clifford+T resources required. 

    Resources are a worst-case estimate obtained by counting the number of MPMCTs with
    each different number of controls, and adding the number of resources required for each.
    (No further simplification is done.)

    Parameters:
        filename (str): Name prefix for the output file

    Outputs:
        resources (dict[string, int]): A dictionary indicating estimated resources and their 
            quantity for the Boolean circuit in the input file. 
            "WIDTH" -> number of qubits
            "D" -> circuit depth
            "TC" -> T-count (includes both T and its inverse)
            "TD" -> T-depth (number of layers of depth containing T and/or its inverse)
            "H" -> Hadamard count
            "CNOT" -> CNOT count  
    """

    resources = {
        "WIDTH" : 0, # TODO
        "D" : 0,
        "TC" : 0,
        "TD" : 0,
        "H" : 0,
        "CNOT" : 0
    }

    num_total_controls, mpmct_tally = count_mpmcts(filename)

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
        # TODO: get a more optimized version of this circuit that's not just
        # the three Toffolis stacked together 
        elif num_controls == 3:
            resources["D"] += num_occs * 27
            resources["TC"] += num_occs * 21
            resources["TD"] += num_occs * 9
            resources["H"] += num_occs * 6 
            resources["CNOT"] += num_occs * 21
        # For k >= 4, can use the formulas from 1902.01329O
        # TODO: add explicit resource counts for 3 controls; also look into whether
        # we can do the larger ones without any aux qubits 
        else:
            resources["D"] += num_occs * mpmct_depth(num_controls)
            resources["TC"] += num_occs * mpmct_t_c(num_controls)
            resources["TD"] += num_occs * mpmct_t_d(num_controls)
            resources["H"] += num_occs * mpmct_h_c(num_controls)
            resources["CNOT"] += num_occs * mpmct_cnot_c(num_controls)

    return resources