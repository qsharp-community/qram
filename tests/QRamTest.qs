namespace Qram.Tests {
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Measurement;
    open Qram;

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramEvenMatchResultsTrue() : Unit {
        let fiveHasThree = (5, IntAsBoolArray(3,2));
        let sevenHasOne = (7, IntAsBoolArray(1,2));
        let data = [fiveHasThree,sevenHasOne];
        let queryAddress = 5;        
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 3, "Expecting item number 5, which is 3 when matched"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramUnEvenMatchResultsTrue() : Unit {
        let fiveHasThree = (5, IntAsBoolArray(3,2));
        let sevenHasOne = (7, IntAsBoolArray(1,2)); 
        let data = [fiveHasThree,sevenHasOne];
        let queryAddress = 7;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 1, "Expecting 1 from address 7 when matched"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramLarger1() : Unit {
        let fiveHasThree = (5, IntAsBoolArray(3, 2));
        let fourHasTwo = (4, IntAsBoolArray(2, 2));
        let oneHasOne = (1, IntAsBoolArray(1, 2));
        let data = [fiveHasThree, fourHasTwo, oneHasOne];
        let queryAddress = 1;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 1, "Expecting 1 from address 1 when matched"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramLarger2() : Unit {
        let fiveHasThree = (5, IntAsBoolArray(3, 2));
        let fourHasTwo = (4, IntAsBoolArray(2, 2));
        let oneHasOne = (1, IntAsBoolArray(1, 2));
        let data = [fiveHasThree, fourHasTwo, oneHasOne];
        let queryAddress = 2;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 0, "Expecting 0 from address 2 when matched"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramLarger4() : Unit {
        let fiveHasThree = (5, IntAsBoolArray(3, 2));
        let fourHasTwo = (4, IntAsBoolArray(2, 2));
        let oneHasOne = (1, IntAsBoolArray(1, 2));
        let data = [fiveHasThree, fourHasTwo, oneHasOne];
        let queryAddress = 4;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 2, "Expecting 2 from address 4 when matched"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramLarger5() : Unit {
        let fiveHasThree = (5, IntAsBoolArray(3, 2));
        let fourHasTwo = (4, IntAsBoolArray(2, 2));
        let oneHasOne = (1, IntAsBoolArray(1, 2));
        let data = [fiveHasThree, fourHasTwo, oneHasOne];
        let queryAddress = 5;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 3, "Expecting 3 from address 5 when matched"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramLarger7() : Unit {
        let fiveHasThree = (5, IntAsBoolArray(3, 2));
        let fourHasTwo = (4, IntAsBoolArray(2, 2));
        let oneHasOne = (1, IntAsBoolArray(1, 2));
        let data = [fiveHasThree, fourHasTwo, oneHasOne];
        let queryAddress = 7;
        Message($"data");
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 0, "Expecting 0 from address 7 when matched"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramMismatchResultsFalse() : Unit {
        let fiveHasThree = (5, IntAsBoolArray(3,2));
        let sevenHasOne = (7, IntAsBoolArray(1,2));
        let data = [fiveHasThree,sevenHasOne];
        let queryAddress = 2;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 0, "Expecting False when no match"); 
        Message("Test passed.");
    }

   @Test("QuantumSimulator")
    operation RetrieveImplicitQramResultsEndianPreservance() : Unit {
        let fourHasThree = (4,IntAsBoolArray(1,2));
        let data = [fourHasThree];
        let queryAddress = 4;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 1, "Expecting 1 when matched. If you see 0 Endian error is in the address or 2 that means Endian broke in the value"); 
        Message("Test passed.");
    }

    internal operation CreateQueryAndMeasureQRAM(data: (Int, Bool[])[], queryAddress : Int) : Int {
        let memory = ImplicitQRAMOracle(data);
        using((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])){
            let queryAddressAsBool = IntAsBoolArray(queryAddress, BitSizeI(queryAddress));
            ApplyPauliFromBitString (PauliX, true, queryAddressAsBool, addressRegister);
            memory::Lookup(LittleEndian(addressRegister), targetRegister);
            ResetAll(addressRegister);
            return MeasureInteger(LittleEndian(targetRegister));
        }
    }
}