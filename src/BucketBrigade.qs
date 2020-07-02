namespace Qram{
    
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

        for (cell in dataValues) {
            BucketBrigadeWrite(memoryRegister, cell);
        }

        return Default<QRAM>()
            w/ Read <-  BucketBrigadeRead(_, _, _)
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
    /// ## dataValue
    /// The tuple of (address, data) that you want written to the memory.
    operation BucketBrigadeWrite(
        memoryRegister : MemoryRegister, 
        dataCell :  MemoryCell
    ) 
    : Unit {
        let (address, data) = (dataCell::Address, dataCell::Value);
        let range = SequenceI (address * Length(data), (address + 1) * Length(data));
        ResetAll(Subarray(range, memoryRegister!));
        ApplyPauliFromBitString(PauliX, true, data, Subarray(range, memoryRegister!));
    }

    /// # Summary
    /// Reads out a value from a MemoryRegister to a target qubit given an address.
    /// # Input
    /// ## addressRegister
    /// The qubit register that represents the address to be queried.
    /// ## memoryRegister
    /// The qubit register that represents the memory you are reading from.
    /// ## target
    /// The qubit that will have the memory value transferred to.
    operation BucketBrigadeRead(
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
                ReadoutMemory(memoryRegister, auxRegister, targetRegister);
            }
        } 
    }

    operation ReadoutMemory(
        memoryRegister : MemoryRegister, 
        auxRegister : Qubit[], 
        targetRegister : Qubit[]
    ) 
    : Unit is Adj + Ctl {
        for ((index, auxEnable) in Enumerated(auxRegister)) {
            let range = SequenceI (index * Length(targetRegister), (index + 1) * Length(targetRegister));
            let memoryPairs = Zip(Subarray(range, memoryRegister!), targetRegister);
            ApplyToEachCA(CCNOT(auxEnable, _, _), memoryPairs);
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

}