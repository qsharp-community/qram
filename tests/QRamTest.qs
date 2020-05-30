namespace tests {
    
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
        let five = [true,false,true];
        let seven = [true,true,true]; 
        let data = [seven,five];
        let queryAddress = five;        
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 1, "Expecting True when matched"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramUnEvenMatchResultsTrue() : Unit {
        let three = [false,true,false];
        let five = [true,false,true];
        let seven = [true,true,true]; 
        let data = [seven,five, three];
        let queryAddress = five;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 1, "Expecting True when matched"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramMismatchResultsFalse() : Unit {
        let two = [false,true,false];
        let five = [true,false,true];
        let seven = [true,true,true]; 
        let data = [seven,five];
        let queryAddress = two;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 0, "Expecting False when no match"); 
        Message("Test passed.");
    }

    @Test("QuantumSimulator")
    operation RetrieveImplicitQramEmptyResultFalse() : Unit {
        let two = [false,true,false];
        let data = new Bool[0];
        let queryAddress = two;
        let result = CreateQueryAndMeasureQRAM(data, queryAddress);
        EqualityFactI(result, 0, "Expecting False when no match in empty Qram"); 
        Message("Test passed.");
    }

    internal operation CreateQueryAndMeasureQRAM(data: Bool[][], queryAddress : Bool[]) : Int {
        let memory = ImplicitQRAMOracle(data);
        using((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])){
            ApplyPauliFromBitString (PauliX, true, queryAddress, addressRegister);
            memory::Lookup(addressRegister, targetRegister);
            ResetAll(addressRegister);
            return MeasureInteger(LittleEndian(targetRegister));
        }
    }


}