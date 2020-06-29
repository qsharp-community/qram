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

    @Test("QuantumSimulator")
    operation BBQRAMforTwoMemoryRegistersUnshuffled() : Unit {
        let m0 = (0, true);
        let m1 = (1, false);
        let queryAddress = 0;
        mutable Array = [m0, m1];
        mutable y = Mapped(Fst<Int,Bool>, Array);
        mutable x = Mapped(Snd<Int,Bool>, Array);
        mutable c = x;
        for (i in 0..(Length(Array)-1)){
           set c w/= y[i] <- x[i];
           set Array w/= y[i] <- (y[i], c[y[i]]);
        }  
        let data = Array; 
        let result = CreateQueryAndMeasureBBQRAM(data, queryAddress);
        EqualityFactI(result, 1, "Expecting 1 for sequential one-to-one mapping of two auxillary and memory registers"); 
        Message("Test passed.");
    }

      @Test("QuantumSimulator")
    operation BBQRAMforTwoMemoryRegistersShuffled() : Unit {
        let m0 = (1, true);
        let m1 = (0, false);
        let queryAddress = 0;
        mutable Array = [m0, m1];
        mutable y = Mapped(Fst<Int,Bool>, Array);
        mutable x = Mapped(Snd<Int,Bool>, Array);
        mutable c = x;
        for (i in 0..(Length(Array)-1)){
           set c w/= y[i] <- x[i];
           set Array w/= y[i] <- (y[i], c[y[i]]);
        }  
        let data = Array; 
        let result = CreateQueryAndMeasureBBQRAM(data, queryAddress);
        EqualityFactI(result, 0, "Expecting 0 for shuffled mapping of two auxillary and memory registers"); 
        Message("Test passed.");
    }
      @Test("QuantumSimulator")
      operation BBQRAMforFourMemoryRegistersUnshuffled() : Unit {
        let m0 = (0, true);
        let m1 = (1, false);
        let m2 = (2, true);
        let m3 = (3, true);
        let queryAddress = 1;
        mutable Array = [m0, m1, m2 ,m3];
        mutable y = Mapped(Fst<Int,Bool>, Array);
        mutable x = Mapped(Snd<Int,Bool>, Array);
        mutable c = x;
        for (i in 0..(Length(Array)-1)){
           set c w/= y[i] <- x[i];
           set Array w/= y[i] <- (y[i], c[y[i]]);
        }  
        let data = Array; 
        let result = CreateQueryAndMeasureBBQRAM(data, queryAddress);
        EqualityFactI(result, 0, "Expecting 0 for sequential one-to-one mapping of four auxillary and memory registers"); 
        Message("Test passed.");
    }
    @Test("QuantumSimulator")
    operation BBQRAMforFourMemoryRegistersShuffled() : Unit {
        let m0 = (3, false);
        let m1 = (1, false);
        let m2 = (2, true);
        let m3 = (0, false);
        let queryAddress = 2;
        mutable Array = [m0, m1, m2, m3];
        mutable y = Mapped(Fst<Int,Bool>, Array);
        mutable x = Mapped(Snd<Int,Bool>, Array);
        mutable c = x;
        for (i in 0..(Length(Array)-1)){
           set c w/= y[i] <- x[i];
           set Array w/= y[i] <- (y[i], c[y[i]]);
        }  
        let data = Array; 
        let result = CreateQueryAndMeasureBBQRAM(data, queryAddress);
        EqualityFactI(result, 1, "Expecting 1 for shuffled mapping of four auxillary and memory registers"); 
        Message("Test passed.");
    }
     @Test("QuantumSimulator")
     operation BBQRAMforEightMemoryRegistersUnshuffled() : Unit {
        let m0 = (0, false);
        let m1 = (1, true);
        let m2 = (2, true);
        let m3 = (3, false); 
        let m4 = (4, false);
        let m5 = (5, false);
        let m6 = (6, true);
        let m7 = (7, false);  
        let queryAddress = 6;
        mutable Array = [m0, m1, m2 ,m3, m4 ,m5 , m6 ,m7];
        mutable y = Mapped(Fst<Int,Bool>, Array);
        mutable x = Mapped(Snd<Int,Bool>, Array);
        mutable c = x;
        for (i in 0..(Length(Array)-1)){
           set c w/= y[i] <- x[i];
           set Array w/= y[i] <- (y[i], c[y[i]]);
        }  
        let data = Array; 
        let result = CreateQueryAndMeasureBBQRAM(data, queryAddress);
        EqualityFactI(result, 1, "Expecting 1 for sequential one-to-one mapping of eight auxillary and memory registers"); 
        Message("Test passed.");
    }
    @Test("QuantumSimulator")
    operation BBQRAMforEightMemoryRegistersShuffled() : Unit {
        let m0 = (4, false);
        let m1 = (5, true);
        let m2 = (1, true);
        let m3 = (3, false); 
        let m4 = (6, false);
        let m5 = (2, false);
        let m6 = (7, true);
        let m7 = (0, false);   
        let queryAddress = 5;
        mutable Array = [m0, m1, m2 ,m3, m4 ,m5 , m6 ,m7];
        mutable y = Mapped(Fst<Int,Bool>, Array);
        mutable x = Mapped(Snd<Int,Bool>, Array);
        mutable c = x;
        for (i in 0..(Length(Array)-1)){
           set c w/= y[i] <- x[i];
           set Array w/= y[i] <- (y[i], c[y[i]]);
        }  
        let data = Array; 
        let result = CreateQueryAndMeasureBBQRAM(data, queryAddress);
        EqualityFactI(result, 1, "Expecting 1 for shuffled mapping of eight auxillary and memory registers"); 
        Message("Test passed.");
    }


   
 internal operation CreateQueryAndMeasureBBQRAM(data: (Int, Bool)[], queryAddress : Int) : Int {
        let memory = BBQRAMOracle(data);
        mutable value = 0;
        using ((addressRegister, auxillaryRegister, memoryRegister, target) = (Qubit[memory::AddressSize], Qubit[2^(memory::AddressSize)], Qubit[2^(memory::AddressSize)], Qubit())) {
            ApplyPauliFromBitString (PauliX, true, Reversed(IntAsBoolArray(queryAddress, memory::AddressSize)), addressRegister);
            ApplyPauliFromBitString(PauliX, true, Mapped(Snd<Int,Bool>, data), memoryRegister);
            ApplyBBQRAM(addressRegister, auxillaryRegister, memoryRegister, target);
            ResetAll(addressRegister);
            ResetAll(auxillaryRegister);
            ResetAll(memoryRegister);
            if (MResetZ(target)==One){
                set value = 1;
            }
         return value;
        }
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