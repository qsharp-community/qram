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
    let data = GenerateBBMemoryData();
    let memory = BBQRAMOracle(data);

     return QueryAndMeasureBBQRAM(memory, queryAddress);
   
    }
   
   
 operation QueryAndMeasureBBQRAM(memory : BBQRAM, queryAddress : Int) : Int {
    mutable value = 0;
        using ((addressRegister, auxillaryRegister, memoryRegister, target) = (Qubit[memory::AddressSize], Qubit[2^(memory::AddressSize)], Qubit[2^(memory::AddressSize)], Qubit())) {
            ApplyPauliFromBitString (PauliX, true, IntAsBoolArray(queryAddress, memory::AddressSize), addressRegister);
            memory::LookupBB(LittleEndian(addressRegister), auxillaryRegister, memoryRegister,  target);
            ResetAll(addressRegister);
            ResetAll(auxillaryRegister);
            ResetAll(memoryRegister);
            if (MResetZ(target)==One){
                set value = 1;
            }
         return value;
        }
    }
  
 function GenerateBBMemoryData() : (Int,Bool)[] {
        let m0 = (3, true);
        let m1 = (1, false);
        let m2 = (2, true);
        let m3 = (0, true);
        
        return [m0, m1, m2, m3];
    }


}

