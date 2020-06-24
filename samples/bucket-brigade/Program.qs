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
 operation TestBBQRAM(queryAddress : Int) : Int{
    let data = ExplicitMemoryData();
    let memory = BBQRAMOracle(data);
    
    //using ((addressRegister, targetRegister) = (Qubit[Length(queryAddress)], Qubit[memory::DataSize])) 
    //let aux = ApplyAddressFanout(
    //let n = Length(queryAddress); 
   // mutable resulti = new Result[n];
     return QueryAndMeasureBBQRAM(memory, queryAddress);
    //ApplyPauliFromBitString(PauliX, true, queryAddress, qe); 
    
    //set resulti = ApplyAddressFanout(qe);
    //ResetAll(qe);
    }
   
   
 operation QueryAndMeasureBBQRAM(memory : BBQRAM, queryAddress : Int) : Int {
    mutable value = 0;
        using ((addressRegister, target) = (Qubit[memory::AddressSize], Qubit())) {
            ApplyPauliFromBitString (PauliX, true, IntAsBoolArray(queryAddress, memory::AddressSize), addressRegister);
            memory::LookupBB(LittleEndian(addressRegister), target);
            ResetAll(addressRegister);
            if (M(target)==One){
                set value = 1;
            }
         return value;
        }
    }
  
 function ExplicitMemoryData() : (Int,Bool)[] {
        let m0 = (3, true);
        let m1 = (1, false);
        let m2 = (2, true);
        let m3 = (0, false);
        
        return [m0, m1, m2, m3];
    }


}

