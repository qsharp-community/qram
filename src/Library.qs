namespace Qram{
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Measurement;

///////////////////////////////////////////////////////////////////////////
// PUBLIC API
///////////////////////////////////////////////////////////////////////////

    /// # Summary
    /// Type representing a generic QRAM type.
    /// # Input
    /// ## Lookup
    /// The named operation that will look up data from the QRAM.
    /// ## AddressSize
    /// The size (number of bits) needed to represent an address for the QRAM.
    /// ## DataSize
    /// The size (number of bits) needed to represent a data value for the QRAM.
    newtype QRAM = (Lookup : ((LittleEndian, Qubit[]) => Unit is Adj + Ctl), 
        AddressSize : Int,
        DataSize : Int);

    /// # Summary
    /// Creates an instance of an implicit QRAM given the data it needs to store.
    /// # Input
    /// ## dataValues
    /// An array of tuples of the form (address, data) where the address and 
    /// data are boolean arrays representing the integer values.
    /// # Output
    /// A `QRAM` type.
    function ImplicitQRAMOracle(dataValues : (Int, Bool[])[]) : QRAM {
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

        let qrams = BoundCA(Mapped(SingleValueWriter, dataValues)); 
        return Default<QRAM>()
            w/ Lookup <- qrams
            w/ AddressSize <- BitSizeI(largestAddress)
            w/ DataSize <- valueSize;
    }

///////////////////////////////////////////////////////////////////////////
// INTERNAL IMPLEMENTATION
///////////////////////////////////////////////////////////////////////////
    
    /// # Summary
    /// Returns an operation that represents a qRAM with one non-zero data value.
    /// # Input
    /// ## address
    /// The address where the data is non-zero.
    /// ## value
    /// The value (as a Bool[]) representing the data at `address`
    /// # Output
    /// An operation that can be used to look up data `value` at `address`.
    internal function SingleValueWriter(address : Int, value : Bool[])
    : ((LittleEndian, Qubit[]) => Unit is Adj + Ctl) {
        return WriteSingleValue(address, value, _, _);
    }

    /// # Summary
    /// 
    /// # Input
    /// ## address
    /// 
    /// ## value
    /// 
    /// ## addressRegister
    /// 
    /// ## targetRegister
    /// 
    internal operation WriteSingleValue(
        address : Int, 
        value : Bool[],
        addressRegister : LittleEndian,
        targetRegister : Qubit[]
    )
    : Unit is Adj + Ctl {
        (ControlledOnInt(address, ApplyPauliFromBitString(PauliX, true, value,_)))
            (addressRegister!, targetRegister);
    }

///////////////////////////////////////////////////////////////////////////
// UTILITY FUNCTIONS
///////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////

//BB
    
   

    //operation ApplyAddressFanout(addressRegister : Qubit[], auxillaryRegister : Qubit[]) : Unit
    //is Adj + Ctl {
    //   let n = Length(addressRegister);      
    //   using (aux = Qubit[2^n]){
    //       X(aux[2^n - 1]);
    //        for (i in 0..(n-1)){
    //            for (j in 0..2^(n-i)..((2^n)-1))
    //            {
    //             CCNOT(addressRegister[i], aux[j], aux[j + 2^(n-i-1)]);
    //             CNOT(aux[j + 2^(n-i-1)], aux[j]); 
    //            }
    //          }
    //   }
    // }
        
    //}

  function BBQRAMOracle(dataValues : ((Int, Bool)[])) : BBQRAM{   
    let largestAddress = Microsoft.Quantum.Math.Max(
    Microsoft.Quantum.Arrays.Mapped(Fst<Int, Bool>, dataValues));
  
    //let largestData = Max((Mapped(BoolArrayAsInt,Mapped(Snd<Int, (Bool[])>), dataValues))));

    let bbqrams = BoundCA(Mapped(BBSingleValueWriter, dataValues)); 

        return Default<BBQRAM>()
            w/ LookupBB <- bbqrams
            w/ AddressSize <- BitSizeI(largestAddress)
            w/ DataSize <- 1;
  }

  internal function BBSingleValueWriter(address : Int, value : Bool)
    : ((LittleEndian, Qubit) => Unit is Adj + Ctl) {
        return ApplyBBQRAM(address, value, _, _);
    }
internal operation ApplyBBQRAM(address : Int, value : Bool, addressRegister : LittleEndian, target : Qubit) : Unit is Adj + Ctl
    {   
        ApplyPauliFromBitString(PauliX, true, IntAsBoolArray(address, 2),addressRegister!);
        let auxillaryRegister = addressRegister!;
        ApplyPauliFromBitString(PauliX, true, IntAsBoolArray(address, 2),auxillaryRegister);
        let memoryRegister = auxillaryRegister;
        ApplyAddressFanout(addressRegister, auxillaryRegister);
        Readout(auxillaryRegister, memoryRegister, target);
    }

 internal operation ApplyAddressFanout(addressRegister : LittleEndian, auxillaryRegister : Qubit[]) : Unit is Adj + Ctl
    {
       let n = Length(addressRegister!);      
       X(auxillaryRegister[0]);
       for (i in 0..(n-1)){
            for (j in 0..2^(n-i)..((2^n)-1))
            {
               CCNOT(addressRegister![i], auxillaryRegister[j], auxillaryRegister[j + 2^(n-i-1)]);
               CNOT(auxillaryRegister[j + 2^(n-i-1)], auxillaryRegister[j]); 
                }
            }    
    }
    operation Readout(auxillaryRegister : Qubit[], memoryRegister : Qubit[], target : Qubit) : Unit
    is Adj + Ctl {
  
    let n = Length(auxillaryRegister);
      for (i in 0..(n-1)){
        CNOT (auxillaryRegister[i],memoryRegister[i]);
        CNOT (memoryRegister[i], target);
    }
 
        //CCNOT(auxillaryRegister[i, memoryRegister[], target);
        //let controlPairs = TupleArrayAsNestedArray(Zip(auxillaryRegister, memoryRegister));
        //Mapped(Toffoli(_,target), controlPairs);
    }
   newtype BBQRAM = (
   LookupBB : ((LittleEndian, Qubit) => Unit is Adj + Ctl), 
   AddressSize : Int, 
   DataSize : Int
  );
}