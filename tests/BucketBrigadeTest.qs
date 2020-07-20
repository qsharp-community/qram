namespace Tests {
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Logical;
    open Qram;    

    // NB: Much better extensible approach
    // AssertOperationEqualsReferenced(Memory that prepares bell state, BellState)

    // Make sure that the query portion of the qRAM gives the same output when expressed as a
    // sequence of Toffolis or sequence of CCZ with target conjugated by H.
    // @Test("ResourcesEstimator")
    // operation CompareBBReadouts() : Unit {
    //     for ((addressSize, targetSize) in Zip(RangeAsIntArray(1..2), RangeAsIntArray(1..2))) {
    //         using ((memoryRegister, targetRegister) = (Qubit[2^addressSize*targetSize], Qubit[targetSize])) {
    //             AssertOperationsEqualInPlace(
    //                 2^addressSize, 
    //                 ReadoutMemory(MemoryRegister(memoryRegister), _, targetRegister),  
    //                 ReadoutMemoryCCZ(MemoryRegister(memoryRegister), _, targetRegister)
    //             );
    //             ResetAll(memoryRegister + targetRegister);
    //         }
    //     }
    // }

    // Verify empty qRAMs are empty
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleEmptyMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = ConstantArray(2^addressSize, [false]);
            let data = EmptyQRAM(addressSize);
            let result = CreateQueryMeasureAllQRAM(data);
            let pairs = Zip(result, expectedValue);
            Ignore(Mapped(
                AllEqualityFactB(_, _, $"Expecting memory contents {expectedValue}, got {result}."), 
                pairs
            ));
        }
    }

    // Verify full qRAMs are full
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = ConstantArray(2^addressSize, [true]);
            let data = FullQRAM(addressSize);
            let result = CreateQueryMeasureAllQRAM(data);
            let pairs = Zip(result, expectedValue);
            Ignore(Mapped(
                AllEqualityFactB(_, _, $"Expecting memory contents {expectedValue}, got {result}."), 
                pairs
            ));
        }
    }

    // Verify things work when only the first cell is full
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleFirstCellFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = [[true]] + ConstantArray(2^addressSize-1, [false]);
            let data = FirstCellFullQRAM();
            let result = CreateQueryMeasureAllQRAM(data);
            let pairs = Zip(result, expectedValue);
            Ignore(Mapped(
                AllEqualityFactB(_, _, $"Expecting memory contents {expectedValue}, got {result}."), 
                pairs
            ));
        }
    }

    // Verify things work when only the second cell is full
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleSecondCellFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = [[false], [true]] + ConstantArray(2^addressSize-2, [false]);
            let data = SecondCellFullQRAM();
            let result = CreateQueryMeasureAllQRAM(data);
            let pairs = Zip(result, expectedValue);
            Ignore(Mapped(
                AllEqualityFactB(_, _, $"Expecting memory contents {expectedValue}, got {result}."), 
                pairs
            ));
        }
    }

    // Verify things work when only the last cell is full
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleLastCellFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = ConstantArray(2^addressSize-1, [false]) + [[true]];
            let data = LastCellFullQRAM(addressSize);
            let result = CreateQueryMeasureAllQRAM(data);
            let pairs = Zip(result, expectedValue);
            Ignore(Mapped(
                AllEqualityFactB(_, _, $"Expecting memory contents {expectedValue}, got {result}."), 
                pairs
            ));
        }
    }

    // Operation that creates a qRAM, and returns the contents for
    // each address queried individually
    internal operation CreateQueryMeasureAllQRAM(bank : MemoryBank) : Bool[][] {
        mutable result = new Bool[][2^bank::AddressSize];

        using ((addressRegister, flatMemoryRegister, targetRegister) =
            (Qubit[bank::AddressSize], 
            Qubit[bank::DataSize*(2^bank::AddressSize)], 
            Qubit[bank::DataSize])
        ) 
        {
            let memoryRegister = Most(Partitioned(ConstantArray(2^bank::AddressSize, bank::DataSize), flatMemoryRegister));
            let memory = BucketBrigadeQRAMOracle(bank::DataSet, MemoryRegister(memoryRegister));

            // Query each address sequentially and store in results array
            for (queryAddress in 0..2^bank::AddressSize-1) {
                // Prepare the address register for the lookup
                PrepareIntAddressRegister(queryAddress, addressRegister);
                // Read out the memory at that address
                memory::QueryBit(AddressRegister(addressRegister), MemoryRegister(memoryRegister), targetRegister);
                // Measure the target register and log the results
                set result w/= queryAddress <- ResultArrayAsBoolArray(MultiM(targetRegister));
                ResetAll(addressRegister + targetRegister);
            }
            // Done with the memory register now
            ResetAll(flatMemoryRegister);
        }
        return result;
    }

}