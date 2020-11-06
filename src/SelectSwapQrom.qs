namespace QsharpCommunity.Qram{
    
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
    /// Source: https://arxiv.org/abs/1812.00954.
    /// SelectSWAP qROMs consist of two parts: 
    /// 1) a "select" part in which the memory contents are specified and written 
    ///    out to auxiliary registers
    /// 2) a "SWAP" part, where the memory contents at the queried address are
    ///    transferred to the target register.
    /// A tradeoff can be made between the sizes of the two parts.
    /// # Input
    /// ## dataValues
    /// An array of memory cells where the address is an Int and the 
    /// data is a boolean array representing the user data.
    /// ## tradeoffParameter 
    /// An integer representing the number of address bits that will be "split off"
    /// to perform the mixed-polarity gates that detail the memory contents. This also
    /// affects the size of the auxiliary registers, making 2^(addressBits - tradeoffParameter). 
    /// copies. Valid tradeoff parameters are integers from 1 to addressBits - 1.
    ///   Example 1:
    ///   A memory has 4 address bits. Rather than doing mixed-polarity gates with 4 controls,
    ///   and holding a single copy of the target register, we can make a tradeoff. Setting
    ///   tradeoffParameter = 1 will "splinter off" 1 address bit from the rest, and make 
    ///   2^(4-1) = 8 copies of the auxiliary register. The select portion will be controlled on 
    ///   that first address bits, whereas the swap network is controlled on the remaining 3.
    ///   Example 2: (as shown in the paper)
    ///   Setting tradeoffParameter = 2 partitions the address space such 2^(4-2) = 4 copies
    ///   of the auxiliary register are created. The select portion uses the first 2 address bits 
    ///   as controls, and the swap network uses the remaining 2.
    /// (Note: the original paper uses a different definition of the tradeoffParameter in which
    ///  the number of auxiliary copies does not need to be a power of 2, however this complicates
    ///  the implementation. Here we consider only the more straightforward case.)
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
    /// ## memoryBank
    /// A MemoryBank contained the addresses and contents of the memory
    /// ## tradeoffParameter
    /// An integer representing the number of address bits that will be "split off"
    /// to perform the mixed-polarity gates that detail the memory contents. This also
    /// affects the size of the auxiliary registers, making 2^(addressBits - tradeoffParameter). 
    /// copies. Valid tradeoff parameters are integers from 1 to addressBits - 1.
    ///   Example 1:
    ///   A memory has 4 address bits. Rather than doing mixed-polarity gates with 4 controls,
    ///   and holding a single copy of the target register, we can make a tradeoff. Setting
    ///   tradeoffParameter = 1 will "splinter off" 1 address bit from the rest, and make 
    ///   2^(4-1) = 8 copies of the auxiliary register. The select portion will be controlled on 
    ///   that first address bits, whereas the swap network is controlled on the remaining 3.
    ///   Example 2: (as shown in the paper)
    ///   Setting tradeoffParameter = 2 partitions the address space such 2^(4-2) = 4 copies
    ///   of the auxiliary register are created. The select portion uses the first 2 address bits 
    ///   as controls, and the swap network uses the remaining 2.
    /// (Note: the original paper uses a different definition of the tradeoffParameter in which
    ///  the number of auxiliary copies does not need to be a power of 2, however this complicates
    ///  the implementation. Here we consider only the more straightforward case.)
    /// ## addressRegister
    /// Memory address that we want to look up.
    /// ## targetRegister
    /// Where we want the data we look up to be transferer to.
    internal operation selectSwap(
        memoryBank : MemoryBank, 
        tradeoffParameter : Int,
        addressRegister : LittleEndian,
        targetRegister : Qubit[]
    ) 
    :  Unit is Adj + Ctl {
        // A tradeoff parameter controls the relative size of an aux register 
        let numAuxQubits = memoryBank::DataSize * 2^(memoryBank::AddressSize - tradeoffParameter);

        // Partition the auxiliary register into chunks of the right size; can't use
        // the PartitionMemoryBank operation because aux register size depends on the tradeoffParameter
        using (auxRegister = Qubit[numAuxQubits]) {
            let partitionedAuxRegister = Chunks(memoryBank::DataSize, auxRegister);
            let partitionedAddressRegister = Partitioned([tradeoffParameter], Reversed(addressRegister!));
            
            within {
                // Perform the select operation that "writes" memory contents to the aux register 
                // using the first tradeoffParameter address bits
                ApplySelect(partitionedAddressRegister[0], partitionedAuxRegister, memoryBank);
                // Apply the swap network controlled on the remaining address qubits
                ApplySwapNetwork(partitionedAddressRegister[1], partitionedAuxRegister);
            }
            apply {
                // Copy the memory contents from the topmost auxiliary register to a target register 
                ApplyToEachCA(CNOT, Zipped(partitionedAuxRegister[0],targetRegister));
            }
        }
    }

    /// # Summary
    /// Applies the `Select` operation. This operation applies specific gates to
    /// a qubit register controlled on the different number state $\ket{j}$.
    ///
    /// $U = \sum^{N-1}_{j=0}\ket{j}\bra{j}\otimes V_j$.
    ///
    /// For the SelectSWAP qROMs, the $V_j$ operations are $X^{a_j}$ where $a_j$ is 
    /// the bit string of memory contents stored in cell $j$.
    ///
    /// # Input
    /// ## addressSubRegister
    /// A qubit register holding the part of the address to be queried, as 
    /// determined by the algorithm.  
    /// ## auxRegister
    /// A qubit register on which the contents of the memory will be written to
    /// enable further processing.
    /// ## bank
    /// A `MemoryBank` that comprises a qROM.
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

    /// # Summary
    /// Copy memory contents onto an auxiliary register in appropriately 
    /// sized chunks, based on the SelectSWAP tradeoffParameter.
    /// # Input
    /// ## bank
    /// A memory bank with the contents of the qROM.
    /// ## auxRegister
    /// The auxiliary register of the qROM onto which the data will be "written".
    /// ## subAddress
    /// Indexes which chunk of memory to write to the `auxRegister`. This will be 
    /// a contiguous subset of the memory, the size of which depends on the initial
    /// tradeoffParameter. 
    ///    Example:
    ///    For a 4-bit address and tradeoffParameter = 2, we create an auxRegister with
    ///    4 chunks. For each subaddress controlled on the first two address bits, we write
    ///    4 consecutive memory cells to the auxRegister. For subAddress = 0, this is memory 
    ///    elements stored at cells 0-3, for subAddress = 1, this is cells 4-7, and so on.
    internal operation FanoutMemoryContents(
        bank : MemoryBank, 
        auxRegister : Qubit[][], 
        subAddress : Int
    ) 
    : Unit is Adj + Ctl {
        let multiplexSize = Length(auxRegister);
        let addressSubspace = (Chunks(multiplexSize, RangeAsIntArray(0..2^bank::AddressSize-1)))[subAddress];
        let dataSubspace = Mapped(DataAtAddress(bank, _), addressSubspace);

        for((value, aux) in Zipped(dataSubspace, auxRegister)) {
            ApplyPauliFromBitString(PauliX, true, value, aux);
        }
    }


    /// # Summary
    /// SwapNetwork 
    /// # Input
    /// ## addressSubregister
    /// A (sub)register of address bits that will be used to control a swap network.
    /// ## auxRegister
    /// A register of qubits, organized into memory chunks, that will be swapped.
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
            
            ApplyToEachCA(SwapRegistersByIndex(addressBit, auxRegister, _), registerPairs);
        }
    }

    /// # Summary
    /// Perform a controlled-SWAP on the full contents of two specified subregisters.   
    /// # Input
    /// ## control
    /// A qubit from which a controlled-SWAP will be performed.
    /// ## auxRegister
    /// A register of qubits, organized into memory chunks, that will be swapped. 
    /// ## swapIndices
    /// An array of 2 integers indexing the two subregisters of `auxRegister` that
    /// will be acted on by the controlled swap.
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