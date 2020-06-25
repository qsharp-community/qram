namespace Qram{
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Diagnostics;

//

///////////////////////////////////////////////////////////////////////////
// PUBLIC API
///////////////////////////////////////////////////////////////////////////

    function BucketBrigadeQRAMOracle(dataValues : (Int, Bool[])[]) : QRAM {
        let largestAddress = Microsoft.Quantum.Math.Max(
            Microsoft.Quantum.Arrays.Mapped(Fst<Int, Bool[]>, dataValues)
        );
        mutable valueSize = 0;
        
        // Determine largest size of stored value to set output qubit register size
        for ((address, value) in dataValues){
            if(Length(value) > valueSize){
                set valueSize = Length(value);
            }
        }

        return Default<QRAM>()
            w/ Read <-  BucketBrigadeRead(_, _, _)
            w/ Write <- BucketBrigadeWrite(_, _)
            w/ AddressSize <- BitSizeI(largestAddress)
            w/ DataSize <- 1;
    }

///////////////////////////////////////////////////////////////////////////
// INTERNAL IMPLEMENTATION
///////////////////////////////////////////////////////////////////////////
    
    operation BucketBrigadeWrite(
        memoryRegister : MemoryRegister, 
        dataValue :  (Int, Bool[])
    ) 
    : Unit {
        let address = Fst(dataValue);
        let data = Head(Snd(dataValue));
        if (data == false) {
            Reset(memoryRegister![address]);
        }
        else {
            Reset(memoryRegister![address]);
            X(memoryRegister![address]);
        }
    }

    operation BucketBrigadeRead(
        addressRegister : AddressRegister, 
        memoryRegister : MemoryRegister, 
        target : Qubit
    ) 
    : Unit is Adj + Ctl {
        using (auxRegister = Qubit[2^Length(addressRegister!)]) {
            within {
                X(Head(auxRegister));
                ApplyAddressFanout(addressRegister, auxRegister);
            }
            apply {
                ReadoutMemory(memoryRegister, auxRegister, target);
            }
        } 
    }

    operation ReadoutMemory(
        memoryRegister : MemoryRegister, 
        auxRegister : Qubit[], 
        target : Qubit
    ) 
    : Unit is Adj + Ctl {
        let controlPairs = Zip(auxRegister, memoryRegister!);
        ApplyToEachCA(CCNOT(_, _, target), controlPairs);
    }

    operation ApplyAddressFanout(
        addressRegister : AddressRegister, 
        auxRegister : Qubit[]
    ) 
    : Unit is Adj + Ctl {
        for ((idx, addressBit) in Enumerated(addressRegister!)) {
            if (idx == 0) {
                Controlled X([addressRegister![0]],auxRegister[1]);
                Controlled X([auxRegister[1]],auxRegister[0]);
            }
            else {
                for (n in 0..(2^idx-1)) {
                    Controlled X([addressRegister![idx], auxRegister[n]],auxRegister[n+2^idx]);
                    Controlled X([auxRegister[n+2^idx]],auxRegister[n]);
                }
            }
        }
    }

}