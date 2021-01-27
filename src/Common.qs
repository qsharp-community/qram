namespace QsharpCommunity.Qram{
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Logical;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Convert;

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
    /// # Named Items
    /// ## QueryPhase
    /// Takes an address, memory, and target qubit to perform the lookup.
    /// ## QueryBit
    /// Takes an address, memory, and target qubit to perform the lookup.
    /// ## Write
    /// Writes a data value at address Int, with the value Bool[] to a MemoryRegister.
    /// ## AddressSize
    /// The size (number of bits) needed to represent an address for the QRAM.
    /// ## DataSize
    /// The size (number of bits) needed to represent a data value for the QRAM.
    newtype QRAM = (
        QueryPhase : ((AddressRegister, MemoryRegister, Qubit[]) => Unit is Adj + Ctl),
        QueryBit : ((AddressRegister, MemoryRegister, Qubit[]) => Unit is Adj + Ctl), 
        Write : ((MemoryRegister, MemoryCell) => Unit), 
        AddressSize : Int,
        DataSize : Int
    );

    /// # Summary
    /// Wrapper for registers that represent a quantum memory.
    newtype MemoryRegister = (Qubit[][]);

    /// # Summary
    /// Takes a flat qubit register and groups the qubits by the number of addresses it represents
    /// # Input
    /// ## flatRegister
    /// 
    /// ## numAddressBits
    /// 
    /// # Output
    /// 
    function PartitionMemoryRegister(flatRegister : Qubit[], memoryBank : MemoryBank) : MemoryRegister {
        return MemoryRegister(
            // Partitioned always returns the rest of the list as an additional array, 
            // dropping it here as it should be empty.
            Most(
                Partitioned(
                    ConstantArray(2^memoryBank::AddressSize, memoryBank::DataSize), 
                    flatRegister
                )  
            )
        );
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
    function ElementsAt<'T>(dataArrayArray : 'T[][], idx : Int) : 'T[] {
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
    function ElementAt<'T>(array : 'T[], idx : Int) : 'T {
        return array[idx];
    }

    /// # Summary
    /// Wrapper for registers that represent addresses.
    newtype AddressRegister = (Qubit[]);

    /// # Summary
    /// Describes a single data point in a memory.
    /// # Input
    /// ## Address
    /// The address in the memory that the MemoryCell describes.
    /// ## Value
    /// The value in the memory that the MemoryCell describes.
    newtype MemoryCell = (Address : Int, Value : Bool[]);

    /// # Summary
    /// Describes a dataset as well as metadata about the data.
    /// # Input
    /// ## DataSet
    /// The data explicitly stored in the memory.
    /// ## AddressSize
    /// The number of bits required to represent the largest explicit address
    /// in the DataSet.
    /// ## DataSize
    /// The number of bits required to represent the largest data valueS
    /// in the DataSet.
    newtype MemoryBank = (DataSet : MemoryCell[], AddressSize : Int, DataSize : Int);

    /// # Summary
    /// Helper function that returns the address of a particular MemoryCell.
    /// Basically a lambda function for the unwrapping.
    /// # Input
    /// ## cell
    /// The memory cell you want to know about.
    /// # Output
    /// The address of that MemoryCell.
    function AddressLookup(cell : MemoryCell) : Int {
        return cell::Address;
    }

    /// # Summary
    /// Helper function that returns the Value of a particular MemoryCell.
    /// Basically a lambda function for the unwrapping.
    /// # Input
    /// ## cell
    /// The memory cell you want to know about.
    /// # Output
    /// The Value of that MemoryCell.
    function ValueLookup(cell : MemoryCell) : Bool[] {
        return cell::Value;
    }

    /// # Summary
    /// Easy way to get all of the addresses specified in a MemoryBank.
    /// # Input
    /// ## bank
    /// The MemoryBank you want to know about.
    /// # Output
    /// A list of addresses given by each MemoryCell in the DataSet.
    function AddressList(bank : MemoryBank) : Int[] {
        return Mapped(AddressLookup, bank::DataSet);
    }

    /// # Summary
    /// Easy way to get all of the values specified in a MemoryBank.
    /// # Input
    /// ## bank
    /// The MemoryBank you want to know about.
    /// # Output
    /// A list of values given by each MemoryCell in the DataSet.
    function DataList(bank : MemoryBank) : Bool[][] {
        return Mapped(ValueLookup, bank::DataSet);
    }

    /// # Summary
    /// Given a MemoryBank, it looks up the Value stored at queryAddress.
    /// If the address is not explicitly in the DataSet, the returned value is
    /// 0.
    /// # Input
    /// ## bank
    /// The MemoryBank you want to know about.
    /// ## queryAddress
    /// The address you want to learn the value for.
    /// # Output
    /// The Value as a Bool[] at the queryAddress in the MemoryBank.
    function DataAtAddress(
        bank : MemoryBank,
        queryAddress : Int 
    ) 
    : Bool[] {
        let addressFound = IndexOf(EqualI(_, queryAddress), AddressList(bank));

        if (not EqualI(addressFound, -1)){
            // Look up the actual data value at the correct address index
            return ValueLookup((LookupFunction(bank::DataSet))(addressFound));
        }
        // The address you are looking for may not have been explicitly given,
        // we assume that the data value there is 0.
        else {
            return ConstantArray(bank::DataSize, false);     
        }
    }

    /// # Summary
    /// Takes a DataSet, generates the necessary metadata and wraps it as a 
    /// MemoryBank.
    /// # Input
    /// ## dataSet
    /// The list of MemoryCells that makes up the data for the bank.
    /// # Output
    /// The wrapped MemoryBank.
    function GeneratedMemoryBank(dataSet : MemoryCell[]) : MemoryBank {
        let largestAddress = Max(Mapped(AddressLookup, dataSet));
        mutable valueSize = 0;
        
        // Determine largest size of stored value to set output qubit register size
        for cell in dataSet {
            if Length(cell::Value) > valueSize {
                set valueSize = Length(cell::Value);
            }
        }
        return Default<MemoryBank>()
            w/ DataSet <- dataSet
            w/ AddressSize <- BitSizeI(largestAddress)
            w/ DataSize <- valueSize;
    }


    operation ApplyCNOTCascade(controls : Qubit[], targets : Qubit[]) :  Unit is Adj + Ctl
    {
        for control in controls {
            ApplyToEachCA(CNOT(control, _), targets);
        }
    }

    operation ApplyMultiTargetCNOT(control : Qubit, targets : Qubit[]) : Unit is Adj + Ctl
    {
        ApplyToEachCA(CNOT(control, _), targets);
    }


    /// # Summary
    /// Swap qubits at the level of registers
    /// # Input
    /// ## registerA
    /// The first register to swap.
    /// ## registerB
    /// The second register to swap.
    operation SwapFullRegisters(registerA : Qubit[], registerB : Qubit[]) 
    : Unit is Adj + Ctl {
        EqualityFactB(Length(registerA) == Length(registerB), true, "Cannot SWAP registers of unequal size.");

        // TODO: find a way to do this in one line with ApplyToEach 
        for qubitIndex in RangeAsIntArray(0..Length(registerA)-1) {
            SWAP(registerA[qubitIndex], registerB[qubitIndex]);
        }
    }

}