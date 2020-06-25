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
    /// Creates an instance of an implicit QROM given the data it needs to store.
    /// # Input
    /// ## dataValues
    /// An array of tuples of the form (address, data) where the address and 
    /// data are boolean arrays representing the integer values.
    /// # Output
    /// A `QROM` type.
    function QromOracle(dataValues : (Int, Bool[])[]) : QROM {
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

        let qroms = BoundCA(Mapped(SingleValueWriter, dataValues)); 
        
        return Default<QROM>()
            w/ Read <- qroms
            w/ AddressSize <- BitSizeI(largestAddress)
            w/ DataSize <- valueSize;
    }

///////////////////////////////////////////////////////////////////////////
// INTERNAL IMPLEMENTATION
///////////////////////////////////////////////////////////////////////////
    
    /// # Summary
    /// Returns an operation that represents a QROM with one non-zero data value.
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
        (ControlledOnInt(address, ApplyPauliFromBitString(PauliX, true, value, _)))
            (addressRegister!, targetRegister);
    }
}