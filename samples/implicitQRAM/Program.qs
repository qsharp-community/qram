namespace implicitQRAM {

    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Qram;
    
/// dotnet run -- --query-address false false
    @EntryPoint()
    operation TestQRAM(queryAddress : Bool[]) : Int {
        //
        let data = GenerateMemoryData();
        let blackBox = ImplicitQRAMOracle(data);
        return QueryAndMeasureQRAM(blackBox, queryAddress);

    }

    operation QueryAndMeasureQRAM(memory : QRAM, queryAddress : Bool[]) : Int {
        using((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])){
            ApplyPauliFromBitString (PauliX, true, queryAddress, addressRegister);
            memory::Lookup(addressRegister, targetRegister);
            ResetAll(addressRegister);
            return MeasureInteger(LittleEndian(targetRegister));
        }
    }

//    operation TestSingleQRAM(queryAddress : Bool[]) : Result {
//        let data = GenerateMemoryData();
//        let blackBox = SingleImplicitQRAMOracle(data);
//        return QueryAndMeasureQRAM(blackBox, queryAddress);
//
//    }
//
//    operation QueryAndMeasureQRAM(memory : QRAM, queryAddress : Bool[]) : Result {
//        using( (register, target) = (Qubit[memory::AddressSize], Qubit())){
//            ApplyPauliFromBitString (PauliX, true, queryAddress, register);
//            memory::Lookup(register, target);
//            ResetAll(register);
//            return MResetZ(target);
//        }
//    }

    //Generates binary representation of [5,4,1]=>[3,2,1]
    function GenerateMemoryData() : (Bool[],Bool[])[] {
        let fiveGivesThree = (IntAsBoolArray(5,3),IntAsBoolArray(3,2));
        let fourGivesTwo = (IntAsBoolArray(4,3),IntAsBoolArray(2,2));
        let oneGivesOne = (IntAsBoolArray(1,3),IntAsBoolArray(1,2));
        return [fiveGivesThree, fourGivesTwo, oneGivesOne];
    }
}

