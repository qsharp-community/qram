namespace QsharpCommunity.Qram{
    
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
    /// An array of memory cells where the address is an Int and the 
    /// data is a boolean array representing the user data.
    /// # Output
    /// A `QROM` type.
    function QromOracle(dataValues : MemoryCell[]) : QROM {
        let bank = GeneratedMemoryBank(dataValues);
        let qroms = BoundCA(Mapped(SingleValueWriter, dataValues)); 
        
        return Default<QROM>()
            w/ Read <- qroms
            w/ AddressSize <- bank::AddressSize
            w/ DataSize <- bank::DataSize;
    }

///////////////////////////////////////////////////////////////////////////
// INTERNAL IMPLEMENTATION
///////////////////////////////////////////////////////////////////////////
        
    /// # Summary
    /// Returns an operation that represents a QROM with one non-zero data value.
    /// # Input
    /// ## cell
    /// A memory cell which contains the data value and the address to write.
    /// # Output
    /// An operation that can be used to look up data `value` at `address`. 
    internal function SingleValueWriter(cell : MemoryCell)
    : ((LittleEndian, Qubit[]) => Unit is Adj + Ctl) {
        return WriteSingleValue(cell::Address, cell::Value, _, _);
    }

    /// # Summary
    /// Constructs an operation that will when given a specific address,
    /// apply a value to a target register.
    /// # Input
    /// ## address
    /// The address where the data is non-zero.
    /// ## value
    /// The value (as a Bool[]) representing the data at `address
    /// ## addressRegister
    /// The qubit register that represents the address you are querying. 
    /// ## targetRegister
    /// The qubit register that will have the QROM value written to.
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