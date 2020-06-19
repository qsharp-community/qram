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
        let data = GenerateData();
        for (i in 0..7) {
            CreateQueryMeasureOneAddressQRAM(data, i);
        }
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

        // Create the new ImplicitQRAM oracle
        let memory = BucketBrigadeQRAMOracle(data);

        using ((addressRegister, memoryRegister, target) = 
            (Qubit[memory::AddressSize], Qubit[memory::AddressSize], Qubit())
        ){
            // Convert the address Int to a Bool[]
            let queryAddressAsBool = IntAsBoolArray(queryAddress, BitSizeI(queryAddress));
            // Prepare the address register 
            ApplyPauliFromBitString(PauliX, true, queryAddressAsBool, addressRegister);
            // Perform the lookup
            memory::Lookup(addressRegister, memoryRegister, target);
            // Get results and make sure its the same format as the data provided i.e. Bool[].
            set result = ResultArrayAsBoolArray([MResetZ(target)]);
            // Reset all the qubits before returning them
            ResetAll(addressRegister + memoryRegister);
        }
        AllEqualityFactB(result, expectedValue, 
            $"Expecting value {expectedValue} at address {queryAddress}, got {result}."); 
    }

}