namespace Qram{
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;

///////////////////////////////////////////////////////////////////////////
// PUBLIC API
///////////////////////////////////////////////////////////////////////////



    /// # Summary
    /// Creates an instance of a SelectSWAP QROM given the data it needs to store.
    /// Source: https://arxiv.org/abs/1812.00954
    /// # Input
    /// ## dataValues
    /// An array of memory cells where the address is an Int and the 
    /// data is a boolean array representing the user data.
    /// ## tradeoffFraction (TODO: RENAME)
    /// An array of memory cells where the address is an Int and the 
    /// data is a boolean array representing the user data.
    /// # Output
    /// A `QROM` type.
    function SelectSwapQromOracle(dataValues : MemoryCell[], tradeoffParameter : Int) : QROM {
        let memoryBank = GeneratedMemoryBank(dataValues);

        return Default<QROM>()
            w/ Read <- selectSwap(memoryBank, tradeoffParameter, _, _)
            w/ AddressSize <- memoryBank::AddressSize
            w/ DataSize <- memoryBank::DataSize;
            // Add tradeoffFraction?
    }

///////////////////////////////////////////////////////////////////////////
// INTERNAL IMPLEMENTATION
///////////////////////////////////////////////////////////////////////////

    /// # Summary
    /// Creates circuitry for SelectSWAP qROM in two parts. 
    /// # Input
    /// ## dataValues
    /// A MemoryBank contained the addresses and contents of the memory
    /// # Output
    /// An operation that can be used to look up data `value` at `address`.
    internal operation selectSwap(
        memoryBank : MemoryBank, 
        tradeoffParameter : Int,
        addressRegister : LittleEndian,
        targetRegister : Qubit[]
    ) 
    :  Unit is Adj + Ctl {
        // A tradeoff parameter controls the relative size of an aux register 
        let numAuxQubits = memoryBank::DataSize * tradeoffParameter;

        // Partition the auxiliary register into chunks of the right size; can't use
        // the PartitionMemoryBank operation because aux register size depends on the tradeoffParameter
        using (auxRegister = Qubit[numAuxQubits]) {
            let partitionedAuxRegister = Chunks(memoryBank::DataSize, auxRegister);
            // Perform the select operation that "writes" memory contents to the aux register using the first address bits
            within {
                Select(addressRegister![0..tradeoffParameter-1], partitionedAuxRegister, memoryBank);
                // Apply the swap network controlled on the remaining address qubits
                SwapNetwork(addressRegister![tradeoffParameter-1...], partitionedAuxRegister);
            }
            apply {
                ApplyToEachCA(CNOT,Zip(partitionedAuxRegister[0],targetRegister));
            }

        }
        
    }

    /// # Summary
    /// 
    /// # Input
    /// ## addressRegister
    /// 
    /// ## auxRegister
    /// 
    /// ## bank
    /// 
    internal operation Select(addressSubRegister : Qubit[], auxRegister : Qubit[][], bank : MemoryBank) 
    : Unit is Adj + Ctl {
        for (subAddress in 0..2^Length(addressSubRegister)-1) {
            ApplyControlledOnInt(
                subAddress, 
                FanoutMemoryContents(bank, _, subAddress), 
                addressSubRegister, 
                auxRegister
            );
        }
    }

    internal operation FanoutMemoryContents(
        bank : MemoryBank, 
        auxRegister : Qubit[][], 
        subAddress : Int
    ) 
    : Unit is Adj + Ctl {
        let multiplexSize = Length(auxRegister);
        let addressSubspace = (Chunks(multiplexSize, RangeAsIntArray(0..2^bank::AddressSize-1)))[subAddress];
        let dataSubspace = Mapped<Int,Bool[]>(DataAtAddress(bank, _), addressSubspace);
    
        for((value, aux) in Zip(dataSubspace, auxRegister)) {
            ApplyPauliFromBitString(PauliX, true, value, aux);
        }
    }


    /// # Summary
    /// SwapNetwork 
    /// # Input
    /// ## addressSubregister
    /// A (sub)register of address bits that will be used to control a swap network.
    /// ## partitionedAuxiliaryRegister
    /// A register of qubits, organized into memory chunks, that will be swapped.
    /// # Output
    /// 
    internal operation SwapNetwork(addressSubregister : Qubit[], partitionedAuxiliaryRegister : Qubit[][]) 
    : Unit is Adj + Ctl {
        // For convenience
        let numAddressBits = Length(addressSubregister);

        // Determine how many full registers we have to swap (should be 2^(Length(addressSubregister)))
        let auxCopies = Length(partitionedAuxiliaryRegister);

        // Loop through address qubits from the bottom up, and apply pairs of controlled swaps
        // e.g. for 3 address qubits and 8 aux subregisters, address qubit 2 controls swaps of registers
        // (0,1), (2,3), (4, 5), (6, 7), then address qubit 1 controls swaps of (0, 2), and (4, 6), finally
        // address qubit 0 swaps (0, 4).
        for (addressQubitIndex in RangeAsIntArray(numAddressBits-1..0)) {
             // Get the indices of the subregister pairs we have to swap this round
            let swapOffset = 2^(numAddressBits - addressQubitIndex -1);
            let swapIndices = RangeAsIntArray(0..swapOffset..auxCopies-1);

            // Organize into pairs
            let registerPairIndices = Most(Partitioned(ConstantArray(2^addressQubitIndex, 2), swapIndices));

            // Perform the controlled swaps from the address bit in question to the set of aux registers
            for (pair in registerPairIndices) {   
                Controlled SwapFullRegisters(
                    [addressSubregister[addressQubitIndex]],
                    (partitionedAuxiliaryRegister[pair[0]], partitionedAuxiliaryRegister[pair[1]]));
            }
        }
    }
}