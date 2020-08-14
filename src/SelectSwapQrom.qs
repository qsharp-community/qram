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
        let numAuxQubits = memoryBank::DataSize * 2^(memoryBank::AddressSize - tradeoffParameter);

        //PermuteQubits(RangeAsIntArray(Length(addressRegister!)-1..-1..0), addressRegister!);

        // Partition the auxiliary register into chunks of the right size; can't use
        // the PartitionMemoryBank operation because aux register size depends on the tradeoffParameter
        using (auxRegister = Qubit[numAuxQubits]) {
            let partitionedAuxRegister = Chunks(memoryBank::DataSize, auxRegister);
            let partitionedAddressRegister = Partitioned([tradeoffParameter], addressRegister!);
            //Message($"{Length(partitionedAddressRegister[0])}|{Length(partitionedAddressRegister[1])}");
            // Perform the select operation that "writes" memory contents to the aux register using the first address bits
            within {
                ApplySelect(partitionedAddressRegister[0], partitionedAuxRegister, memoryBank);
                // Apply the swap network controlled on the remaining address qubits
                ApplySwapNetwork(partitionedAddressRegister[1], partitionedAuxRegister);
            }
            apply {
                ApplyToEachCA(CNOT,Zip(partitionedAuxRegister[0],targetRegister));
            }
        }
                
        //PermuteQubits(RangeAsIntArray(Length(addressRegister!)-1..-1..0), addressRegister!);
        
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
    internal operation ApplySelect(
        addressSubRegister : Qubit[], 
        auxRegister : Qubit[][], 
        bank : MemoryBank
    ) 
    : Unit is Adj + Ctl {
        for (subAddress in 0..2^Length(addressSubRegister)-1) {
            ApplyControlledOnInt(
                subAddress, 
                FanoutMemoryContents(bank, _, subAddress), 
                Reversed(addressSubRegister), 
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
        let dataSubspace = Mapped(DataAtAddress(bank, _), addressSubspace);

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
    internal operation ApplySwapNetwork(
        addressSubregister : Qubit[],
        auxRegister : Qubit[][]
    ) 
    : Unit is Adj + Ctl {
        // For convenience
        let numAddressBits = Length(addressSubregister);

        // Determine how many full registers we have to swap (should be 2^(Length(addressSubregister)))
        let auxCopies = Length(auxRegister);

        for ((idx, addressBit) in Enumerated(Reversed(addressSubregister))) {
            let stride = 2^(idx);
            let registerPairs = Chunks(2, RangeAsIntArray(0..stride..auxCopies-1));
            //Message($"auxCopies: {auxCopies}| numAddressBits: {numAddressBits} | idx: {idx} | stride: {stride} |list: {RangeAsIntArray(0..stride..auxCopies-1)}| regPairs: {registerPairs}");
            ApplyToEachCA(SwapRegistersByIndex(addressBit, auxRegister, _), registerPairs);
        }
    }

    internal operation SwapRegistersByIndex(
        control : Qubit, 
        auxRegister : Qubit[][], 
        swapIndices : Int[]
    ) 
    : Unit is Adj + Ctl {
        Controlled SwapFullRegisters(
            [control], 
            (auxRegister[swapIndices[0]], 
            auxRegister[swapIndices[1]])
        );
    }
}