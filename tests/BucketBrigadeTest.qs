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
    @Test("QuantumSimulator")
    operation BucketBrigadeOracleSingleLookupMatchResults() : Unit {
        let bank = SingleBitData();
        for (address in 0..bank::AddressSize-1) {
            // Get the data value you expect to find at queryAddress
            let expectedValue = DataAtAddress(bank, address);
            let result = CreateQueryMeasureOneAddressQRAM(bank, address);
            AllEqualityFactB(result, expectedValue, 
            $"Expecting value {expectedValue} at address {address}, got {result}."); 
        }
    }

    // Basic lookup where a new value is written right before with all addresses checked
    @Test("QuantumSimulator")
    operation BucketBrigadeOracleSingleWriteLookupMatchResults() : Unit {
        let bank = SingleBitData();
        for (address in 0..bank::AddressSize-1) {
            // Get the data value you expect to find at queryAddress
            let expectedValue = DataAtAddress(bank, address);
            let result = CreateWriteQueryMeasureOneAddressQRAM(bank, MemoryCell(address, [true]));
            AllEqualityFactB(result, [true], 
            $"Expecting value {expectedValue} at address {address}, got {result}."); 
        }
    }

    // Verify empty qRAMs are empty
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleEmptyMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = ConstantArray(2^addressSize, false);
            let data = EmptyQRAM(addressSize);
            let result = CreateQueryMeasureAllQRAM(data);
            AllEqualityFactB(result, expectedValue, 
            $"Expecting memory contents {expectedValue}, got {result}."); 
        }
    }

    // Verify full qRAMs are full
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = ConstantArray(2^addressSize, true);
            let data = FullQRAM(addressSize);
            let result = CreateQueryMeasureAllQRAM(data);
            AllEqualityFactB(result, expectedValue, 
            $"Expecting memory contents {expectedValue}, got {result}."); 
        }
    }

    // Verify things work when only the first cell is full
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleFirstCellFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = [true] + ConstantArray(2^addressSize-1, false);
            let data = FirstCellFullQRAM();
            let result = CreateQueryMeasureAllQRAM(data);
            AllEqualityFactB(result, expectedValue, 
            $"Expecting memory contents {expectedValue}, got {result}."); 
        }
    }

    // Verify things work when only the second cell is full
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleSecondCellFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = [false, true] + ConstantArray(2^addressSize-2, false);
            let data = SecondCellFullQRAM();
            let result = CreateQueryMeasureAllQRAM(data);
            AllEqualityFactB(result, expectedValue, 
            $"Expecting memory contents {expectedValue}, got {result}."); 
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
        mutable result = new Bool[][0];

        using ((addressRegister, memoryRegister, targetRegister) =
            (Qubit[bank::AddressSize], 
            Qubit[bank::AddressSize * bank::DataSize], 
            Qubit[bank::DataSize])
        ) 
        {
            let memory = BucketBrigadeQRAMOracle(bank::DataSet, MemoryRegister(memoryRegister));

            // Query each address sequentially and store in results array
            for (queryAddress in 0..bank::AddressSize-1) {
                // Prepare the address register for the lookup
                PrepareIntAddressRegister(queryAddress, addressRegister);
                // Read out the memory at that address
                memory::Read(AddressRegister(addressRegister), MemoryRegister(memoryRegister), targetRegister);
                // Measure the target register and log the results
                set result w/= queryAddress <- ResultArrayAsBoolArray(MultiM(targetRegister));
                ResetAll(addressRegister + targetRegister);
            }
            // Done with the memory register now
            ResetAll(memoryRegister);
        }
        return result;
    }

    internal operation CreateQueryMeasureOneAddressQRAM(
        bank : MemoryBank, 
        queryAddress : Int
    ) 
    : Bool[] {
        using ((addressRegister, memoryRegister, targetRegister) =
            (Qubit[bank::AddressSize], 
            Qubit[bank::AddressSize * bank::DataSize], 
            Qubit[bank::DataSize])
        ) 
        {
            let memory = BucketBrigadeQRAMOracle(bank::DataSet, MemoryRegister(memoryRegister));
            // Prepare the address register for the lookup
            PrepareIntAddressRegister(queryAddress, addressRegister);
            // Read out the memory at that address
            memory::Read(AddressRegister(addressRegister), MemoryRegister(memoryRegister), targetRegister);
            // Measure the target register and log the results
            let result = ResultArrayAsBoolArray(MultiM(targetRegister));
            ResetAll(addressRegister + memoryRegister + targetRegister);

            return result;
        }
    }

    internal operation CreateWriteQueryMeasureOneAddressQRAM(
        bank : MemoryBank, 
        newData : MemoryCell
    ) 
    : Bool[] {
        using ((addressRegister, memoryRegister, targetRegister) =
            (Qubit[bank::AddressSize], 
            Qubit[bank::AddressSize * bank::DataSize], 
            Qubit[bank::DataSize])
        ) 
        {
            let memory = BucketBrigadeQRAMOracle(bank::DataSet, MemoryRegister(memoryRegister));
            memory::Write(MemoryRegister(memoryRegister), newData);
            
            // Prepare the address register for the lookup
            PrepareIntAddressRegister(newData::Address, addressRegister);
            // Read out the memory at that address
            memory::Read(AddressRegister(addressRegister), MemoryRegister(memoryRegister), targetRegister);
            // Measure the target register and log the results
            let result = ResultArrayAsBoolArray(MultiM(targetRegister));
            ResetAll(addressRegister + memoryRegister + targetRegister);

            return result;
        }
    }

}