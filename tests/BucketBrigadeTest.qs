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

    // Basic lookup with all addresses checked
    @Test("QuantumSimulator")
    operation BucketBrigadeOracleSingleLookupMatchResults() : Unit {
        let data = GenerateSingleBitData();
        for (i in 0..7) {
            CreateQueryMeasureOneAddressQRAM(data, i);
        }
    }

    // Basic lookup with all addresses checked
    @Test("QuantumSimulator")
    operation BucketBrigadeOracleSingleWriteLookupMatchResults() : Unit {
        let data = GenerateSingleBitData();
        for (i in 0..7) {
            CreateWriteQueryMeasureOneAddressQRAM(data, (i, [true]));
        }
    }

    // Verify empty qRAMs are empty
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleEmptyMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = ConstantArray(2^addressSize, false);
            let data = GenerateEmptyQRAM(addressSize);
            let result = CreateQueryMeasureQRAM(data, addressSize);
            AllEqualityFactB(result, expectedValue, 
            $"Expecting memory contents {expectedValue}, got {result}."); 
        }
    }

    // Verify full qRAMs are full
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = ConstantArray(2^addressSize, true);
            let data = GenerateFullQRAM(addressSize);
            let result = CreateQueryMeasureQRAM(data, addressSize);
            AllEqualityFactB(result, expectedValue, 
            $"Expecting memory contents {expectedValue}, got {result}."); 
        }
    }

    // Verify things work when only the first cell is full
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleFirstCellFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = [true] + ConstantArray(2^addressSize-1, false);
            let data = GenerateFirstCellFullQRAM();
            let result = CreateQueryMeasureQRAM(data, addressSize);
            AllEqualityFactB(result, expectedValue, 
            $"Expecting memory contents {expectedValue}, got {result}."); 
        }
    }

    // Verify things work when only the second cell is full
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleSecondCellFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = [false, true] + ConstantArray(2^addressSize-2, false);
            let data = GenerateSecondCellFullQRAM();
            let result = CreateQueryMeasureQRAM(data, addressSize);
            AllEqualityFactB(result, expectedValue, 
            $"Expecting memory contents {expectedValue}, got {result}."); 
        }
    }

    // Verify things work when only the last cell is full
    @Test("QuantumSimulator") 
    operation BucketBrigadeOracleLastCellFullMatchResults() : Unit {
        for (addressSize in 1..3) {
            let expectedValue = ConstantArray(2^addressSize-1, false) + [true];
            let data = GenerateLastCellFullQRAM(addressSize);
            let result = CreateQueryMeasureQRAM(data, addressSize);
            AllEqualityFactB(result, expectedValue, 
            $"Expecting memory contents {expectedValue}, got {result}."); 
        }
    }

    // Operation that creates a single output-bit qRAM, and returns the contents for
    // each address queried individually
    internal operation CreateQueryMeasureQRAM(data : (Int, Bool[])[], addressSize : Int) : Bool[] {
        mutable result = new Bool[2^addressSize];

        using ((addressRegister, memoryRegister, target) =
            (Qubit[addressSize], Qubit[2^addressSize], Qubit())
        ) {
            let memory = BucketBrigadeQRAMOracle(data, MemoryRegister(memoryRegister));

            // Query each address sequentially and store in results array
            for (queryAddress in 0..2^addressSize-1) {
                let queryAddressAsBool = IntAsBoolArray(queryAddress, addressSize);
                ApplyPauliFromBitString(PauliX, true, queryAddressAsBool, addressRegister);
                memory::Read(AddressRegister(addressRegister), MemoryRegister(memoryRegister), target);
                set result w/= queryAddress <- ResultAsBool(MResetZ(target));
                ResetAll(addressRegister + [target]);
            }
            ResetAll(memoryRegister);
        }
        return result;
    }

    internal operation CreateQueryMeasureOneAddressQRAM(
        data : (Int, Bool[])[], 
        queryAddress : Int
    ) 
    : Unit {
        // Get the data value you expect to find at queryAddress
        let expectedValue = DataAtAddress(data, queryAddress);
        // Setup the var to hold the result of the measurement
        mutable result = new Bool[0];

        // Create the new Bucket Brigade QRAM oracle
        
        using ((addressRegister, memoryRegister, target) = 
            (Qubit[3], Qubit[8], Qubit())
        ){
            let memory = BucketBrigadeQRAMOracle(data, MemoryRegister(memoryRegister));
            // Convert the address Int to a Bool[]
            let queryAddressAsBool = IntAsBoolArray(queryAddress, memory::AddressSize);
            // Prepare the address register 
            ApplyPauliFromBitString(PauliX, true, queryAddressAsBool, addressRegister);
            // Perform the lookup
            memory::Read(AddressRegister(addressRegister), MemoryRegister(memoryRegister), target);
            // Get results and make sure its the same format as the data provided i.e. Bool[].
            set result = ResultArrayAsBoolArray([MResetZ(target)]);
            // Reset all the qubits before returning them
            ResetAll(addressRegister + memoryRegister);
        }
        AllEqualityFactB(result, expectedValue, $"Expecting value {expectedValue} at address {queryAddress}, got {result}."); 
    }

    internal operation CreateWriteQueryMeasureOneAddressQRAM(
        data : (Int, Bool[])[], 
        newData : (Int, Bool[])
    ) 
    : Unit {
        // Setup the var to hold the result of the measurement
        mutable result = new Bool[0];

        using ((addressRegister, memoryRegister, target) = 
            (Qubit[3], Qubit[8], Qubit())
        ){
            let memory = BucketBrigadeQRAMOracle(data, MemoryRegister(memoryRegister));
            memory::Write(MemoryRegister(memoryRegister), newData);
            
            let queryAddressAsBool = IntAsBoolArray(Fst(newData), memory::AddressSize);
            // Prepare the address register 
            ApplyPauliFromBitString(PauliX, true, queryAddressAsBool, addressRegister);
            // Perform the lookup
            memory::Read(AddressRegister(addressRegister), MemoryRegister(memoryRegister), target);
            // Get results and make sure it's the same format as the data provided i.e. Bool[].
            set result = ResultArrayAsBoolArray([MResetZ(target)]);
            // Reset all the qubits before returning them
            ResetAll(addressRegister + memoryRegister);
        }
        AllEqualityFactB(result, Snd(newData), 
            $"Expecting value {Snd(newData)} at address {Fst(newData)}, got {result}."); 
    }

}