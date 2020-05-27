namespace implicitQRAM {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Memory;
    
/// dotnet run -- --query false false false
    @EntryPoint()
    operation TestQRAM(query : Bool[]) : Result {
        let OnesData = [[true, true, true], [false, true, false]];
        let BlackBox = ImplicitQRAMOracle(OnesData);
        using( (register, target) = (Qubit[3], Qubit())){
            ApplyPauliFromBitString (PauliX, true, query, register);
            BlackBox::Lookup(register, target);
            ResetAll(register);
            return MResetZ(target);
        }

    }
}

