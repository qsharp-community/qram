namespace bucket_brigade {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    

    @EntryPoint()
    operation HelloQ(numQubits : Int) : Unit {
        Message("Hello quantum world!");
    }
}

