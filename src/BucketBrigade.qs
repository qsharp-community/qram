namespace Qram{
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;

///////////////////////////////////////////////////////////////////////////
// PUBLIC API
///////////////////////////////////////////////////////////////////////////

    newtype QRAM = (Lookup : ((Qubit[], Qubit[], Qubit) => Unit is Adj + Ctl), 
        AddressSize : Int,
        DataSize : Int);

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
            w/ Lookup <-  Lookup(_,_,_)
            w/ AddressSize <- BitSizeI(largestAddress)
            w/ DataSize <- 1;
    }

///////////////////////////////////////////////////////////////////////////
// INTERNAL IMPLEMENTATION
///////////////////////////////////////////////////////////////////////////
    
    operation Readout(
        memoryRegister : Qubit[], 
        auxRegister : Qubit[], 
        target : Qubit
    ) 
    : Unit is Adj + Ctl {
        let controlPairs = Zip(auxRegister, memoryRegister);
        ApplyToEachCA(CCNOT(_, _, target), controlPairs);
    }

    operation ApplyAddressFanout(
        addressRegister : Qubit[], 
        auxRegister : Qubit[]
    ) 
    : Unit is Adj + Ctl {
        for ((idx, addressBit) in Enumerated(addressRegister)) {
            if (idx == 0){
                Controlled X([addressRegister[0]],auxRegister[1]);
                Controlled X([auxRegister[1]],auxRegister[0]);
            }
            else {
                for (n in 0..(2^idx-1)){
                    Controlled X([addressRegister[idx], auxRegister[n]],auxRegister[n+2^idx]);
                    Controlled X([auxRegister[n+2^idx]],auxRegister[n]);
                }
            }
        }
    }

    operation Lookup(
        addressRegister : Qubit[], 
        memoryRegister : Qubit[], 
        target : Qubit
    ) 
    : Unit is Adj + Ctl {
        using (auxRegister = Qubit[2^Length(addressRegister)]) {
            within {
                X(Head(auxRegister));
                ApplyAddressFanout(addressRegister, auxRegister);
            }
            apply {
                Readout(memoryRegister, auxRegister, target);
            }
        } 
    }
}