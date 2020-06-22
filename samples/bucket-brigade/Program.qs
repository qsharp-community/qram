namespace bucket_brigade {

    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Measurement;
    open Qram;

@EntryPoint()
 operation TestBBQRAM(queryAddress : Bool[]) : Result[]{
    let n = Length(queryAddress); 
    mutable resulti = new Result[n];
    using (qe = Qubit[n]) {
    ApplyPauliFromBitString(PauliX, true, queryAddress, qe); 
    
    set resulti = ApplyAddressFanout(qe);
    ResetAll(qe);
    }
   return resulti;
   }
}

