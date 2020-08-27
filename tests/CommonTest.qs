namespace Tests {
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Logical;
    open Microsoft.Quantum.Random;
    open Qram;

    // Memory where every address is specified and contains a bitstring for 
    // the data bit to one is probOne.
    internal operation FullMemory(
        numAddressBits : Int, 
        numDataBits : Int, 
        probOne : Double
    ) 
    : MemoryBank {
        let numAddresses = 2^numAddressBits-1;
        let addresses = RangeAsIntArray(0..numAddresses);
        let values = DrawMany(DrawMany(DrawRandomBool, numDataBits, _), numAddresses, probOne);
        let data = Zip(addresses, values);
        return GeneratedMemoryBank(Mapped(MemoryCell, data));
    }

    // Memory where every address is specified and contains a random bitstring for the data.
    internal operation RandomFullMemory(
        numAddressBits : Int, 
        numDataBits : Int
    ) 
    : MemoryBank {
        return FullMemory(numAddressBits, numDataBits, 0.5);
    }

    // Memory where every address contains a 0.
    internal operation ZerosFullMemory(
        numAddressBits : Int, 
        numDataBits : Int
    ) 
    : MemoryBank {
        return FullMemory(numAddressBits, numDataBits, 0.0);
    }

    // QRAM where every memory cell contains a 1
    internal operation OnesFullMemory(
        numAddressBits : Int, 
        numDataBits : Int
    ) 
    : MemoryBank {
        return FullMemory(numAddressBits, numDataBits, 1.0);
    }
    
    internal operation PrepareIntAddressRegister(address : Int, register : Qubit[]) 
    : Unit is Adj + Ctl {
        let queryAddressAsBoolArray = IntAsBoolArray(address, Length(register));
        ApplyPauliFromBitString(PauliX, true, queryAddressAsBoolArray, register);
    }

    //FIXME: Need a way to randomly generate a subselection of addresses 
    //to specify in the memory
    internal operation PartialMemory(
        numAddressBits : Int, 
        numDataBits : Int, 
        probOne : Double,
        numMemoryCells: Int
    ) 
    : MemoryBank {
        let numAddresses = 2^numAddressBits-1;
        Fact(numMemoryCells<=numAddresses, "More cells were asked for than address bits can support.");
        let addresses = RangeAsIntArray(0..numAddresses);
        let values = DrawMany(DrawMany(DrawRandomBool, numDataBits, _), numMemoryCells, probOne);
        let data = Zip(addresses, values);
        return GeneratedMemoryBank(Mapped(MemoryCell, data));
    }


}
