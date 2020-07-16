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

    // Basic lookup with all addresses checked


    // Verify empty qRAMs are empty
    @Test("QuantumSimulator") 
    operation BucketBrigadeCCZOracleEmptyMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = ConstantArray(2^addressSize, [false]);
            let data = EmptyQRAM(addressSize);
            let result = CreateQueryMeasureAllCCZQRAM(data);
            let pairs = Zip(result, expectedValue);
            Ignore(Mapped(
                AllEqualityFactB(_, _, $"Expecting memory contents {expectedValue}, got {result}."), 
                pairs
            ));
        }
    }

    // Verify full qRAMs are full
    @Test("QuantumSimulator") 
    operation BucketBrigadeCCZOracleFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = ConstantArray(2^addressSize, [true]);
            let data = FullQRAM(addressSize);
            let result = CreateQueryMeasureAllCCZQRAM(data);
            let pairs = Zip(result, expectedValue);
            Ignore(Mapped(
                AllEqualityFactB(_, _, $"Expecting memory contents {expectedValue}, got {result}."), 
                pairs
            ));
        }
    }

    // Verify things work when only the first cell is full
    @Test("QuantumSimulator") 
    operation BucketBrigadeCCZOracleFirstCellFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = [[true]] + ConstantArray(2^addressSize-1, [false]);
            let data = FirstCellFullQRAM();
            let result = CreateQueryMeasureAllCCZQRAM(data);
            let pairs = Zip(result, expectedValue);
            Ignore(Mapped(
                AllEqualityFactB(_, _, $"Expecting memory contents {expectedValue}, got {result}."), 
                pairs
            ));
        }
    }

    // Verify things work when only the second cell is full
    @Test("QuantumSimulator") 
    operation BucketBrigadeCCZOracleSecondCellFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = [[false], [true]] + ConstantArray(2^addressSize-2, [false]);
            let data = SecondCellFullQRAM();
            let result = CreateQueryMeasureAllCCZQRAM(data);
            let pairs = Zip(result, expectedValue);
            Ignore(Mapped(
                AllEqualityFactB(_, _, $"Expecting memory contents {expectedValue}, got {result}."), 
                pairs
            ));
        }
    }

    // Verify things work when only the last cell is full
    @Test("QuantumSimulator") 
    operation BucketBrigadeCCZOracleLastCellFullMatchResults() : Unit {
        for (addressSize in 2..3) {
            let expectedValue = ConstantArray(2^addressSize-1, [false]) + [[true]];
            let data = LastCellFullQRAM(addressSize);
            let result = CreateQueryMeasureAllCCZQRAM(data);
            let pairs = Zip(result, expectedValue);
            Ignore(Mapped(
                AllEqualityFactB(_, _, $"Expecting memory contents {expectedValue}, got {result}."), 
                pairs
            ));
        }
    }

    // Make sure the fanout operation with parallelized CCZ is the same as the one using only Toffolis.
    @Test("QuantumSimulator")
    operation CompareBBAddressFanouts() : Unit {
        for (addressSize in 1..3) {
            using (addressRegister = Qubit[addressSize]) {
                // TODO: make sure this line-splitting is style-guide compliant 
                AssertOperationsEqualReferenced(
                    2^addressSize, 
                    ApplyAddressFanout(AddressRegister(addressRegister), _), 
                    ApplyAddressFanoutCCZ(AddressRegister(addressRegister), _
                ));
                ResetAll(addressRegister);
            } 
        }
    }

    // Make sure that the query portion of the qRAM gives the same output when expressed as a
    // sequence of Toffolis or sequence of CCZ with target conjugated by H.
    @Test("ResourcesEstimator")
    operation CompareBBReadouts() : Unit {
        for ((addressSize, targetSize) in Zip(RangeAsIntArray(1..2), RangeAsIntArray(1..2))) {
            using ((flatMemoryRegister, targetRegister) = (Qubit[2^addressSize*targetSize], Qubit[targetSize])) {
                let memoryRegister = MemoryRegister(Most(Partitioned(ConstantArray(targetSize, 2^addressSize), flatMemoryRegister)));
                AssertOperationsEqualInPlace(
                    2^addressSize, 
                    ReadoutMemory(memoryRegister, _, targetRegister),  
                    ReadoutMemoryCCZ(memoryRegister, _, targetRegister)
                );
                ResetAll(flatMemoryRegister + targetRegister);
            }
        }
    }


    // Operation that creates a qRAM, and returns the contents for
    // each address queried individually
    internal operation CreateQueryMeasureAllCCZQRAM(bank : MemoryBank) : Bool[][] {
        mutable result = new Bool[][2^bank::AddressSize];

        using ((addressRegister, flatMemoryRegister, targetRegister) =
            (Qubit[bank::AddressSize], 
            Qubit[(2^bank::AddressSize) * bank::DataSize], 
            Qubit[bank::DataSize])
        ) 
        {
            let memoryRegister = MemoryRegister(Most(Partitioned(ConstantArray(2^bank::AddressSize, bank::DataSize), flatMemoryRegister)));
            let memory = BucketBrigadeCCZQRAMOracle(bank::DataSet, memoryRegister);
            // Query each address sequentially and store in results array
            
            for (queryAddress in 0..2^bank::AddressSize-1) {
                // Prepare the address register for the lookup
                PrepareIntAddressRegister(queryAddress, addressRegister);
                // Read out the memory at that address
                memory::Read(AddressRegister(addressRegister), memoryRegister, targetRegister);
                // Measure the target register and log the results
                set result w/= queryAddress <- ResultArrayAsBoolArray(MultiM(targetRegister));
                ResetAll(addressRegister + targetRegister);
            }
            // Done with the memory register now
            ResetAll(flatMemoryRegister);
        }
        return result;
    }

    internal operation CreateQueryMeasureOneAddressCCZQRAM(
        bank : MemoryBank, 
        queryAddress : Int
    ) 
    : Bool[] {
        using ((addressRegister, flatMemoryRegister, targetRegister) =
            (Qubit[bank::AddressSize], 
            Qubit[(2^bank::AddressSize) * bank::DataSize], 
            Qubit[bank::DataSize])
        ) 
        {
            let memoryRegister = MemoryRegister(Most(Partitioned(ConstantArray(2^bank::AddressSize, bank::DataSize), flatMemoryRegister)));
            let memory = BucketBrigadeCCZQRAMOracle(bank::DataSet, memoryRegister);
            // Prepare the address register for the lookup
            PrepareIntAddressRegister(queryAddress, addressRegister);
            // Read out the memory at that address
            memory::Read(AddressRegister(addressRegister), memoryRegister, targetRegister);
            // Measure the target register and log the results
            let result = ResultArrayAsBoolArray(MultiM(targetRegister));
            ResetAll(addressRegister + flatMemoryRegister + targetRegister);

            return result;
        }
    }

    internal operation CreateWriteQueryMeasureOneAddressCCZQRAM(
        bank : MemoryBank, 
        newData : MemoryCell
    ) 
    : Bool[] {
        using ((addressRegister, flatMemoryRegister, targetRegister) =
            (Qubit[bank::AddressSize], 
            Qubit[(2^bank::AddressSize) * bank::DataSize], 
            Qubit[bank::DataSize])
        ) 
        {
            let memoryRegister = MemoryRegister(Most(Partitioned(ConstantArray(2^bank::AddressSize, bank::DataSize), flatMemoryRegister)));
            let memory = BucketBrigadeCCZQRAMOracle(bank::DataSet, memoryRegister);
            memory::Write(memoryRegister, newData);
            
            // Prepare the address register for the lookup
            PrepareIntAddressRegister(newData::Address, addressRegister);
            // Read out the memory at that address
            memory::Read(AddressRegister(addressRegister), memoryRegister, targetRegister);
            // Measure the target register and log the results
            let result = ResultArrayAsBoolArray(MultiM(targetRegister));
            ResetAll(addressRegister + flatMemoryRegister + targetRegister);

            return result;
        }
    }

}