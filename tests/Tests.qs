namespace tests {
    
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Intrinsic;

    //TODO: load an measure out classical memory
    //TODO: One qubit address one output store bell state, query in super position, then unprepare bell and assert 00
    
    @Test("QuantumSimulator")
    operation AllocateQubit () : Unit {
        
        using (q = Qubit()) {
            Assert([PauliZ], [q], Zero, "Newly allocated qubit must be in |0> state.");
        }
        
        Message("Test passed.");
    }




}