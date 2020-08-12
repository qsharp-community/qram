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
        let bank = GeneratedMemoryBank(dataValues);
        // Replace
        let selectSwapQuery = selectSwap(bank, tradeoffParameter); 
        
        return Default<QROM>()
            w/ Read <- selectSwapQuery //Replace
            w/ AddressSize <- bank::AddressSize
            w/ DataSize <- bank::DataSize;
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
    internal operation selectSwap(bank : MemoryBank, tradeoffParameter : Int) 
    : ((LittleEndian, Qubit[]) => Unit is Adj + Ctl) {
        // Create qubit register
        // Call select + swap as per fig 1c of the paper; for data of non-power-2 
        // sizes we will have to also implement fig 1d.
        
        // A tradeoff parameter controls the relative size of an aux register 
        let num_auxiliary_qubits = bank::DataSize * tradeoffParameter;

        using ((addressRegister, auxiliaryRegister) = (Qubit[bank::AddressSize], Qubit[num_auxiliary_qubits])) {
            Select(addressRegister[0..tradeoffParameter-1], auxiliaryRegister, bank, tradeoffParameter);
            SwapNetwork(addressRegister[tradeoffParameter-1...], auxiliaryRegister);
        }
    }

    /// # Summary
    /// Select operation
    /// # Input
    /// 
    /// # Output
    /// 
    internal operation Select(addressSubregister : Qubit[], auxiliaryRegister: Qubit[], bank : MemoryBank, tradeoffParameter : Int) 
    : Unit is Adj + Ctl {
        // Divide the memory into tradeoffParameter sets of addresses; 
        let unitaries = new operation[];

        // for (memoryPartitionIndex in RangeAsIntArray(0..tradeoffParameter-1) {
        //     // For each mixed-polarity gate, need to apply a different chunk of Paulis to the aux register
        //     ApplyToEach(ApplyPauliFromBitString(PauliX, true, bank::DataSet[stuff], auxiliaryRegister[memoryPartition]);
        // }

        // Apply multiplexing operation
        MultiplexOperations(unitaries, LittleEndian(addressSubregister), auxiliaryRegister);
    }

    /// # Summary
    /// SwapNetwork 
    /// # Input
    /// 
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
            let registerPairIndices = Partitioned(ConstantArray(2, 2^addressQubitIndex), swapIndices);

            // Perform the controlled swaps
            for (pair in registerPairIndices) {   
                Controlled SwapFullRegisters(
                    [addressSubregister[addressQubitIndex]],
                    (partitionedAuxiliaryRegister[pair[0]], partitionedAuxiliaryRegister[pair[1]]));
            }
        }
    }
}