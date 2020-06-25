namespace Qram{
    open Microsoft.Quantum.Arithmetic;
    
    // Wrapper for registers that represent a quantum memory
    newtype MemoryRegister = (Qubit[]);
    
    // Wrapper for registers that represent addresses
    newtype AddressRegister = (Qubit[]);

    // Describes a single data point in a memory
    newtype MemoryCell = (address: Int, data: Bool[]);

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
    /// 
    /// ## Write
    /// 
    /// ## AddressSize
    /// 
    /// ## DataSize
    /// 
    newtype QRAM = (
        Read : ((AddressRegister, MemoryRegister, Qubit) => Unit is Adj + Ctl), 
        Write : ((MemoryRegister, (Int, Bool[])) => Unit), 
        AddressSize : Int,
        DataSize : Int
    );

}