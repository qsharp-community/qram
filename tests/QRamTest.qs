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
        let five = IntAsBoolArray(5,3);
        let fiveHasThree = (five,IntAsBoolArray(3,2));
        let sevenHasOne = (IntAsBoolArray(7,3),IntAsBoolArray(1,2));
        let data = [fiveHasThree,sevenHasOne];
        let queryAddress = five;        
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 3, "Expecting item number 5, which is 3 when matched"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramUnEvenMatchResultsTrue() : Unit {
        let five = IntAsBoolArray(5,3);
        let fiveHasThree = (five,IntAsBoolArray(3,2));
        let sevenHasOne = ([true,true,true], [false,true]); 
        let data = [fiveHasThree,sevenHasOne];
        let queryAddress = five;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 3, "Expecting 3 when matched"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramMismatchResultsFalse() : Unit {
        let fiveHasThree = (IntAsBoolArray(5,3),IntAsBoolArray(3,2));
        let sevenHasOne = (IntAsBoolArray(7,3),IntAsBoolArray(1,2));
        let data = [fiveHasThree,sevenHasOne];
        let two = IntAsBoolArray(2,3);
        let queryAddress = two;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 0, "Expecting False when no match"); 
        Message("Test passed.");
    }

   @Test("QuantumSimulator")
    operation RetrieveImplicitQramResultsEndianPreservance() : Unit {
        let four = IntAsBoolArray(4,3);
        let fourHasThree = (four,IntAsBoolArray(1,2));
        let data = [fourHasThree];
        let queryAddress = four;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 1, "Expecting 1 when matched. If you see 0 Enidan error is in the address or 2 that means Endian broke in the value"); 
        Message("Test passed.");
    }

    internal operation CreateQueryAndMeasureQRAM(data: (Bool[],Bool[])[], queryAddress : Bool[]) : Int {
        let memory = ImplicitQRAMOracle(data);
        using((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])){
            ApplyPauliFromBitString (PauliX, true, queryAddress, addressRegister);
            memory::Lookup(LittleEndian(addressRegister), targetRegister);
            ResetAll(addressRegister);
            return MeasureInteger(LittleEndian(targetRegister));
        }
    }
}