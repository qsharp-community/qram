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
    let data = ExplicitMemoryData8();
    let memory = BBQRAMOracle(data);
    return QueryAndMeasureBBQRAM(data, memory, queryAddress);
    } 
   
 operation QueryAndMeasureBBQRAM(data:(Int, Bool)[], memory : BBQRAM, queryAddress : Int) : Int {
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

 function ExplicitMemoryData2() : (Int,Bool)[] {
        let m0 = (1, true);
        let m1 = (0, true);
     
        mutable Array = [m0, m1];
        mutable y = Mapped(Fst<Int,Bool>, Array);
        mutable x = Mapped(Snd<Int,Bool>, Array);
        mutable c = x;
        for (i in 0..(Length(Array)-1)){
           set c w/= y[i] <- x[i];
           set Array w/= y[i] <- (y[i], c[y[i]]);
        }  

        return Array;
    }
 function ExplicitMemoryData4() : (Int,Bool)[] {
        let m0 = (3, true);
        let m1 = (2, false);
        let m2 = (0, false);
        let m3 = (1, true);
        mutable Array = [m0, m1, m2, m3];
        mutable y = Mapped(Fst<Int,Bool>, Array);
        mutable x = Mapped(Snd<Int,Bool>, Array);
        mutable c = x;
        for (i in 0..(Length(Array)-1)){
           set c w/= y[i] <- x[i];
           set Array w/= y[i] <- (y[i], c[y[i]]);
        }  

        return Array;
    }

 function ExplicitMemoryData8() : (Int,Bool)[] {
        let m0 = (4, false);
        let m1 = (5, true);
        let m2 = (1, true);
        let m3 = (3, false); 
        let m4 = (6, false);
        let m5 = (2, false);
        let m6 = (7, true);
        let m7 = (0, false);  
        mutable Array = [m0, m1, m2, m3, m4, m5, m6, m7];
        mutable y = Mapped(Fst<Int,Bool>, Array);
        mutable x = Mapped(Snd<Int,Bool>, Array);
        mutable c = x;
        for (i in 0..(Length(Array)-1)){
           set c w/= y[i] <- x[i];
           set Array w/= y[i] <- (y[i], c[y[i]]);
        }  

        return Array;
    }

   // let op = memory::LookupBB[queryAddress];
   //op(LittleEndian(addressRegister), auxillaryRegister, memoryRegister, target);




}

