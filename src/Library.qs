namespace Qram{
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Diagnostics;
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



//BUCKET-BRIGADE
///////////////////////////////////////////////////////////////////////////
// PUBLIC API
///////////////////////////////////////////////////////////////////////////
    
     
   /// # Summary
   /// Type representing a generic BBQRAM type.
   /// # Input
   /// ## Lookup
   /// The named operation that will look up data from the BBQRAM. 
   /// ## AddressSize
   /// The size (number of bits) needed to represent an address for the QRAM.
   /// ## DataSize
   /// The size (number of bits) needed to represent a data value for the QRAM.
  newtype BBQRAM = (
   LookupBB : ((LittleEndian, Qubit[], Qubit, Qubit) => Unit is Adj + Ctl), 
   AddressSize : Int, 
   DataSize : Int
   );

  /// # Summary
  /// Creates an instance of an bucket-brigade QRAM given the data it needs to store.
  /// # Input
  /// ## dataValues
  /// An array of tuples of the form (auxaddress, value) where the auxaddress is the address 
  /// of the auxillary register to which the memory register is connected via CNOT gate and 
  /// value is the data stored (either 0 or 1) in the memory register. 
  /// # Output
  /// BBRQRAM type
  function BBQRAMOracle(dataValues : ((Int, Bool)[])) : BBQRAM{   
    let largestAddress = Microsoft.Quantum.Math.Max(
    Microsoft.Quantum.Arrays.Mapped(Fst<Int, Bool>, dataValues));
    let bbqrams = BoundCA(Mapped(BBSingleValueWriter, dataValues)); 

        return Default<BBQRAM>()
            w/ LookupBB <- bbqrams
            w/ AddressSize <- 2
            w/ DataSize <- 1;
  }

  /// # Summary
  /// Returns an operation that represents a BBQRAM with one data value.
  /// # Input
  /// ## auxaddress
  /// The address of auxillary register where the data is non-zero.
  /// ## value
  /// The value (as a Bool) representing the data at `address`
  /// # Output
  ///  An operation that can be used to look up data `value` at `address`
  internal function BBSingleValueWriter(auxaddress : Int, value : Bool)
    : ((LittleEndian, Qubit[], Qubit, Qubit) => Unit is Adj + Ctl) {
        return ApplyBBQRAM(auxaddress, value, _, _, _,_);
    }
    
  /// # Summary
  /// 
  /// # Input
  /// ## auxaddress
  /// 
  /// ## value
  /// 
  /// ## addressRegister
  /// State of the address qubits stored in little endian format.
  /// ## auxillaryRegister
  /// State of the auxilary qubits.
  /// ## memoryRegister
  /// State of a particular memory register qubit.
  /// ## target
  /// State of the target qubit.
  internal operation ApplyBBQRAM(auxaddress : Int, value : Bool, addressRegister : LittleEndian, auxillaryRegister:Qubit[], memoryRegister:Qubit, target : Qubit) : Unit is Adj + Ctl
    {   
        ApplyAddressFanout(addressRegister, auxillaryRegister);  
        Readout(auxaddress, auxillaryRegister, memoryRegister, target);
    }

 /// # Summary
 /// Performs the FANOUT part of the bucket-brigade.
 /// # Input
 /// ## addressRegister
 /// 
 /// ## auxillaryRegister
 /// 
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
    
    /// # Summary
    /// Performs the QUERY part of the bucket-brigade
    /// # Input
    /// ## auxaddress
    /// 
    /// ## auxillaryRegister
    /// 
    /// ## memoryRegister
    /// 
    /// ## target
    /// 
    internal operation Readout(auxaddress:Int, auxillaryRegister : Qubit[], memoryRegister : Qubit, target : Qubit) : Unit
    is Adj + Ctl {
    CNOT(auxillaryRegister[auxaddress], memoryRegister);
    CNOT(memoryRegister, target);
    }
 
}