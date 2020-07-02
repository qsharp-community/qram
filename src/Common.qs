namespace Qram{
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arithmetic;
    
    // Wrapper for registers that represent a quantum memory
    newtype MemoryRegister = (Qubit[]);
    
    // Wrapper for registers that represent addresses
    newtype AddressRegister = (Qubit[]);

    // Describes a single data point in a memory
    newtype MemoryCell = (Address : Int, Value : Bool[]);

    // Describes a dataset as well as 
    newtype MemoryBank = (DataSet : MemoryCell[], AddressSize : Int, DataSize : Int);

    function AddressList(cell : MemoryCell) : Int {
        return cell::Address;
    }

    function GeneratedMemoryBank(dataSet : MemoryCell[]) : MemoryBank {
        let largestAddress = Max(Mapped(AddressList, dataSet));
        mutable valueSize = 0;
        
        // Determine largest size of stored value to set output qubit register size
        for (cell in dataSet){
            if(Length(cell::Value) > valueSize){
                set valueSize = Length(cell::Value);
            }
        }
        return Default<MemoryBank>()
            w/ DataSet <- dataSet
            w/ AddressSize <- BitSizeI(largestAddress)
            w/ DataSize <- valueSize;
    }

    /// # Summary
    /// Type representing a generic QROM type.
    /// # Input
    /// ## Read
    /// The named operation that will look up data from the QROM.
    /// ## AddressSize
    /// The size (number of bits) needed to represent an address for the QROM.
    /// ## DataSize
    /// The size (number of bits) needed to represent a data value for the QROM.
    newtype QROM = (
        Read : ((LittleEndian, Qubit[]) => Unit is Adj + Ctl), 
        AddressSize : Int,
        DataSize : Int
    );

    /// # Summary
    /// Type representing a generic QRAM type.
    /// # Input
    /// ## Read
    /// Takes an address, memory, and target qubit to perform the lookup.
    /// ## Write
    /// Writes a data value at address Int, with the value Bool[] to a MemoryRegister.
    /// ## AddressSize
    /// The size (number of bits) needed to represent an address for the QRAM.
    /// ## DataSize
    /// The size (number of bits) needed to represent a data value for the QRAM.
    newtype QRAM = (
        Read : ((AddressRegister, MemoryRegister, Qubit[]) => Unit is Adj + Ctl), 
        Write : ((MemoryRegister, MemoryCell) => Unit), 
        AddressSize : Int,
        DataSize : Int
    );

}