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

    // Basic lookup with all addresses checked, all valid tradeoff parameters tested.
    @Test("QuantumSimulator")
    operation SelectSwapOracleSingleLookupMatchResults() : Unit {
        let data = MultiBitData();
        for (i in 0..2^data::AddressSize-1) {
            for (t in 1..data::AddressSize) {
                CreateQueryMeasureOneAddressSelectSwap(data, i, t);
            }
        }
    }

    internal operation CreateQueryMeasureOneAddressSelectSwap(
        data : MemoryBank, 
        queryAddress : Int,
        tradeoffParameter : Int
    ) 
    : Unit {
        // Get the data value you expect to find at queryAddress
        let expectedValue = DataAtAddress(data, queryAddress);

        // Create the new Qrom oracle
        let memory = SelectSwapQromOracle(data::DataSet, tradeoffParameter);

        using((addressRegister, targetRegister) = 
            (Qubit[memory::AddressSize], Qubit[memory::DataSize])
        ){
            // Convert the address Int to a Bool[]
            let queryAddressAsBool = IntAsBoolArray(queryAddress, BitSizeI(queryAddress));
            // Prepare the address register 
            ApplyPauliFromBitString (PauliX, true, queryAddressAsBool, addressRegister);
            // Perform the lookup
            memory::Read(LittleEndian(addressRegister), targetRegister);
            // Get results and make sure its the same format as the data provided i.e. Bool[].
            let result = ResultArrayAsBoolArray(MultiM(targetRegister));
            // Reset all the qubits before returning them
            ResetAll(addressRegister+targetRegister);
            AllEqualityFactB(result, expectedValue, 
                $"Expecting value {expectedValue} at address {queryAddress}, got {result}."); 
        }
    }

}