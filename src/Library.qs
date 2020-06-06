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
        let largestAddress = Microsoft.Quantum.Math.Max(Microsoft.Quantum.Arrays.Mapped(Fst<Int, Bool[]>, dataValues));
        mutable valueSize = 0;
        
        // Determine largest size of stored value to set output qubit register size
        for ((address, value) in dataValues){
            if(Length(value) > valueSize){
                set valueSize = Length(value);
            }
        }

        let qrams = Mapped(SingleImplicitQRAMOracle, dataValues); 
        return Default<QRAM>()
            w/ Lookup <- ApplyImplicitQRAMOracle(qrams, _, _)
            w/ AddressSize <- BitSizeI(largestAddress)
            w/ DataSize <- valueSize;
    }

///////////////////////////////////////////////////////////////////////////
// INTERNAL IMPLEMENTATION
///////////////////////////////////////////////////////////////////////////

    /// # Summary
    /// Internal QRam type for a single QRAM Bit (is composed to form a 
    /// full memory block).
    /// # Input
    /// ## Lookup
    /// The named element that represents a call to the QRAM type.
    internal newtype SingleBitQRAM = (
        Lookup : ((LittleEndian, Qubit[]) => Unit is Adj + Ctl)
    );
    
    internal function SingleImplicitQRAMOracle(
        address : Int, 
        value : Bool[]
    ) 
    : SingleBitQRAM {
        return Default<SingleBitQRAM>()
            w/ Lookup <- ApplySingleImplicitQRAMOracleValues(address, value, _, _);
    }

    internal operation ApplySingleImplicitQRAMOracleValues(
        address: Int, 
        values: Bool[],
        addressRegister : LittleEndian,
        targetRegister : Qubit[]
    )
    : Unit is Adj + Ctl {
        (ControlledOnBitString(IntAsBoolArray(address, BitSizeI(address)), ApplyPauliFromBitString(PauliX, true, _, _)))
            (addressRegister!, (values, targetRegister));
        //for((idx,value) in Enumerated(values)){
        //    if(value)
        //    {
        //        (ControlledOnBitString(address, X))(addressRegister, targetRegister[idx]);
        //    }
        //}
    }

    /// # Summary
    /// Takes a mutivalue QRAM exposed in the public API and maps a lookup 
    /// across an array of `SingleBitQRAM`.
    ///
    /// # Input
    /// ## qrams
    /// Array of `SingleBitQRAM`s that store all the data values.
    /// ## addressRegister
    /// The address that the user wants to lookup.
    /// ## targetRegister
    /// The register that the lookup will place the data into.
    internal operation ApplyImplicitQRAMOracle(
        qrams: SingleBitQRAM[], 
        addressRegister : LittleEndian,
        targetRegister : Qubit[]
    )
    : Unit is Adj + Ctl {
        for (qram in qrams) {
            qram::Lookup(addressRegister, targetRegister) ;
        }
    }

///////////////////////////////////////////////////////////////////////////
// UTILITY FUNCTIONS
///////////////////////////////////////////////////////////////////////////

    /// # Summary
    /// Takes the Boolean array representation of an Int and converts to the 
    /// list of ones addresses needed to represent that Int.
    /// # Input
    /// ## dataArray
    /// A data value in the form of a
    /// # Output
    /// 
    internal function OnesAddressesFromDataValue(dataArray : Bool[]) : Bool[][] {
        mutable onesAddresses = new Bool[][0];
        let nAddressBits = BitSizeI(Length(dataArray));
        for ((idx, bitValue) in Enumerated(dataArray)) {
            if (bitValue) {
                set onesAddresses += [IntAsBoolArray(idx, nAddressBits)];
            }
        }
        return onesAddresses;
    }

    /// # Summary
    /// Takes a tuple of nested arrays and returns the $idx^{th}$ item from 
    /// each array.
    ///
    /// # Input
    /// ## dataArrayArray
    /// Array of arrays that you want to take the $idx^{th}$ item from.
    ///
    /// # Output
    /// An array of the $idx^{th}$ item from each nested array in dataArrayArray.
    internal function ElementsAt<'T>(dataArrayArray : 'T[][], idx : Int) : 'T[] {
        return Mapped(ElementAt<'T>(_, idx), dataArrayArray);
    }

    /// # Summary
    /// Returns the $n^{th}$ item of an array. Basically a workaround for not 
    /// having lambdas yet in Q#.
    /// # Input
    /// ## array
    /// An array of type `'T`
    /// # Output
    /// The $idx^{th}$ item from `array`.
    internal function ElementAt<'T>(array : 'T[], idx : Int) : 'T {
        return array[idx];
    }
}
