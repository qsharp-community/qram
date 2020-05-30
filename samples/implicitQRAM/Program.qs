namespace implicitQRAM {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Qram;
    
/// dotnet run -- --query false false false
    @EntryPoint()
    operation TestQRAM(queryAddress : Bool[]) : Result {
        let data = GenerateMemoryData();
        let blackBox = SingleImplicitQRAMOracle(data);
        return QueryAndMeasureQRAM(blackBox, queryAddress);

    }

    operation QueryAndMeasureQRAM(memory : QRAM, queryAddress : Bool[]) : Result {
        using( (register, target) = (Qubit[memory::AddressSize], Qubit())){
            ApplyPauliFromBitString (PauliX, true, queryAddress, register);
            memory::Lookup(register, target);
            ResetAll(register);
            return MResetZ(target);
        }
    }

    function GenerateMemoryData() : Bool[][] {
        return [[true, false, true],[false, false, true],[false, false, false]];
    }
}

