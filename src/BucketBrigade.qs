namespace QsharpCommunity.Qram{
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Diagnostics;

///////////////////////////////////////////////////////////////////////////
// PUBLIC API
///////////////////////////////////////////////////////////////////////////

    /// # Summary
    /// Creates a QRAM type corresponding to a bit encoded Bucket Brigade scheme.
    /// # Input
    /// ## dataValues
    /// The data to be stored in the memory.
    /// ## memoryRegister
    /// The register that you want to be initialized with the provided data.
    /// # Output
    /// An instance of the QRAM type that will allow you to use the memory.
    operation BucketBrigadeQRAMOracle(dataValues : MemoryCell[], memoryRegister : MemoryRegister) : QRAM {
        let bank = GeneratedMemoryBank(dataValues);

        for (cell in bank::DataSet) {
            BucketBrigadeWrite(memoryRegister, cell);
        }

        return Default<QRAM>()
            w/ QueryPhase <- BucketBrigadeReadPhase(_, _, _)
            w/ QueryBit <- BucketBrigadeReadBit(_, _, _)
            w/ Write <- BucketBrigadeWrite(_, _)
            w/ AddressSize <- bank::AddressSize
            w/ DataSize <- bank::DataSize;
    }

    

///////////////////////////////////////////////////////////////////////////
// INTERNAL IMPLEMENTATION
///////////////////////////////////////////////////////////////////////////
    
    /// # Summary
    /// Writes a single bit of data to the memory.
    /// # Input
    /// ## memoryRegister
    /// Register that represents the memory you are writing to.
    /// ## dataCell
    /// The tuple of (address, data) that you want written to the memory.
    operation BucketBrigadeWrite(
        memoryRegister : MemoryRegister, 
        dataCell :  MemoryCell
    ) 
    : Unit {
        let (address, data) = (dataCell::Address, dataCell::Value);

        ResetAll((memoryRegister!)[address]);
        ApplyPauliFromBitString(PauliX, true, data, (memoryRegister!)[address]);
    }

    /// # Summary
    /// Reads out a value from a MemoryRegister to a target qubit given an address.
    /// # Input
    /// ## addressRegister
    /// The qubit register that represents the address to be queried.
    /// ## memoryRegister
    /// The qubit register that represents the memory you are reading from.
    /// ## targetRegister
    /// The register that will have the memory value transferred to.
    operation BucketBrigadeReadBit(
        addressRegister : AddressRegister, 
        memoryRegister : MemoryRegister, 
        targetRegister : Qubit[]
    ) 
    : Unit is Adj + Ctl {
        using (auxRegister = Qubit[2^Length(addressRegister!)]) {
            within {
                X(Head(auxRegister));
                ApplyAddressFanout(addressRegister, auxRegister);
            }
            apply {
                ReadoutMemoryBit(memoryRegister, auxRegister, targetRegister);
            }
        } 
    }


    /// # Summary
    /// Reads out a value from a MemoryRegister to a target qubit given an address.
    /// # Input
    /// ## addressRegister
    /// The qubit register that represents the address to be queried.
    /// ## memoryRegister
    /// The qubit register that represents the memory you are reading from.
    /// ## targetRegister
    /// The register that will have the memory value transferred to.
    operation BucketBrigadeReadPhase(
        addressRegister : AddressRegister, 
        memoryRegister : MemoryRegister, 
        targetRegister : Qubit[]
    ) 
    : Unit is Adj + Ctl {
        using (auxRegister = Qubit[2^Length(addressRegister!)]) {
            within {
                X(Head(auxRegister));
                ApplyAddressFanout(addressRegister, auxRegister);
            }
            apply {
                ReadoutMemoryPhase(memoryRegister, auxRegister, targetRegister);
            }
        } 
    }

    /// # Summary
    /// Takes a register with a binary representation of an address and 
    /// converts it to a one-hot encoding in the aux register.
    /// # Input
    /// ## addressRegister
    /// Qubit register that uses binary encoding.
    /// ## auxRegister
    /// Qubit register that will have the same address as addressRegister, but
    /// as a one-hot encoding.
    operation ApplyAddressFanout(
        addressRegister : AddressRegister, 
        auxRegister : Qubit[]
    ) 
    : Unit is Adj + Ctl {
        for ((idx, addressBit) in Enumerated(addressRegister!)) {
            if (idx == 0) {
                Controlled X([addressRegister![0]],auxRegister[1]);
                Controlled X([auxRegister[1]],auxRegister[0]);
            }
            else {
                for (n in 0..(2^idx-1)) {
                    Controlled X([addressRegister![idx], auxRegister[n]],auxRegister[n+2^idx]);
                    Controlled X([auxRegister[n+2^idx]],auxRegister[n]);
                }
            }
        }
    }

    /// # Summary
    /// Transfers the memory register values onto the target register.
    /// # Input
    /// ## memoryRegister
    /// The qubit register that represents the memory you are reading from.
    /// ## auxRegister
    /// Qubit register that will have the same address as addressRegister, but
    /// as a one-hot encoding.
    /// ## targetRegister
    /// The register that will have the memory value transferred to.
    operation ReadoutMemoryBit(
        memoryRegister : MemoryRegister, 
        auxRegister : Qubit[], 
        targetRegister : Qubit[]
    ) 
    : Unit is Adj + Ctl {
        for ((idx, aux) in Enumerated(auxRegister)) {
            let valuePairs = Zipped((memoryRegister!)[idx], targetRegister);
            ApplyToEachCA(CCNOT(aux, _, _), valuePairs);
        }
        
    }

    /// # Summary
    /// Transfers the memory register values onto the target register.
    /// # Input
    /// ## memoryRegister
    /// The qubit register that represents the memory you are reading from.
    /// ## auxRegister
    /// Qubit register that will have the same address as addressRegister, but
    /// as a one-hot encoding.
    /// ## targetRegister
    /// The register that will have the memory value transferred to.
    operation ReadoutMemoryPhase(
        memoryRegister : MemoryRegister, 
        auxRegister : Qubit[], 
        targetRegister : Qubit[]
    ) 
    : Unit is Adj + Ctl {
        within {
            ApplyToEachCA(X, targetRegister);
            ApplyToEachCA(H, targetRegister);
        }
        apply {
            ReadoutMemoryBit(memoryRegister, auxRegister, targetRegister);
        }
        
    }
}