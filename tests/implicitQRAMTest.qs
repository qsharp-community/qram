namespace ImplicitQram.Tests {
    
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

    // TODO: Possible syntax for test naming
    // <Function><Situation><Act><Result><Expect>
    

    // Basic lookup with all addresses checked
    @Test("QuantumSimulator")
    operation ImplicitQRAMOracleSingleLookupMatchResults() : Unit {
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
        let memory = ImplicitQRAMOracle(data);

        using((addressRegister, targetRegister) = 
            (Qubit[memory::AddressSize], Qubit[memory::DataSize])
        ){
            // Convert the address Int to a Bool[]
            let queryAddressAsBool = IntAsBoolArray(queryAddress, BitSizeI(queryAddress));
            // Prepare the address register 
            ApplyPauliFromBitString (PauliX, true, queryAddressAsBool, addressRegister);
            // Perform the lookup
            memory::Lookup(LittleEndian(addressRegister), targetRegister);
            // Get results and make sure its the same format as the data provided i.e. Bool[].
            set result = ResultArrayAsBoolArray(MultiM(targetRegister));
            // Reset all the qubits before returning them
            ResetAll(addressRegister+targetRegister);
        }
        AllEqualityFactB(result, expectedValue, 
            $"Expecting value {expectedValue} at address {queryAddress}, got {result}."); 
    }

    internal function DataAtAddress(
        data : (Int, Bool[])[],
        queryAddress : Int 
    ) 
    : Bool[] {
        // Find the index in the original dataset with a particular address
        let addressIndex = Where(MatchedAddress(_, queryAddress), data);
        // The address you are looking for may not have been explicitly given
        if (IsEmpty(addressIndex)){
            // Need to pad out the bool array for 0 to the right length
            let dataLength = Length(Snd(data[0]));
            return ConstantArray(dataLength, false);
        }
        else {
            // Look up the actual data value at the correct address index
            return Snd(data[Head(addressIndex)]);
        }
    }

    /// # Summary
    /// Work around for lambda functions, checks if first element in a tuple
    /// is a particular integer.
    /// # Input
    /// ## dataTuple
    /// Represents a single address and data value pair in the memory.
    /// ## queryAddress
    /// The address you are looking to find.
    /// # Output
    /// Bool representing if that tuple has the address you are looking for.
    internal function MatchedAddress(
        dataTuple : (Int, Bool[]), 
        queryAddress : Int
    ) 
    : Bool {
        return EqualI(Fst(dataTuple), queryAddress);
    }

    // Hardcoded data set
    internal function GenerateData() : (Int, Bool[])[] {
        let numDataBits = 3;
        let fiveHasThree = (5, IntAsBoolArray(3, numDataBits));
        let fourHasTwo = (4, IntAsBoolArray(2, numDataBits));
        let oneHasZero = (0, IntAsBoolArray(0, numDataBits));
        let twoHasFive = (2, IntAsBoolArray(5, numDataBits));
        return [fiveHasThree, fourHasTwo, oneHasZero, twoHasFive];
    }
}