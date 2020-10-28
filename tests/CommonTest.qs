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
    open QsharpCommunity.Qram;

    // Hardcoded data set
    internal function SingleBitData() : MemoryBank {
        let data = [(5, [true]), (4, [true]), (1, [false]), (2, [false])];
        return GeneratedMemoryBank(Mapped(MemoryCell, data));
    }

    // Hardcoded data set for a multi-bit output situation
    internal function MultiBitData() : MemoryBank {
        let numDataBits = 3;
        let data =  [
            (5, IntAsBoolArray(3, numDataBits)), 
            (4, IntAsBoolArray(2, numDataBits)), 
            (0, IntAsBoolArray(0, numDataBits)), 
            (2, IntAsBoolArray(5, numDataBits))];
        return GeneratedMemoryBank(Mapped(MemoryCell, data));
    }

    // TODO: parameterize data values as w
    // QRAM where every memory cell contains a 0
    internal function EmptyQRAM(addressSize : Int) : MemoryBank {
        let addresses = SequenceI(0, 2^addressSize - 1);
        let data = ConstantArray(2^addressSize, [false]);
        return GeneratedMemoryBank(Mapped(MemoryCell,Zipped(addresses, data)));
    }

    // QRAM where every memory cell contains a 1
    internal function FullQRAM(addressSize : Int) : MemoryBank {
        let addresses = SequenceI(0, 2^addressSize - 1);
        let data = ConstantArray(2^addressSize, [true]);
        return GeneratedMemoryBank(Mapped(MemoryCell,Zipped(addresses, data)));
    }

    // QRAM where only the first memory cell contains a 1
    internal function FirstCellFullQRAM() : MemoryBank {
        return GeneratedMemoryBank([MemoryCell(0, [true])]);
    }

    // QRAM where only the second memory cell contains a 1
    internal function SecondCellFullQRAM() : MemoryBank {
        return GeneratedMemoryBank([MemoryCell(1, [true])]);
    }

    // QRAM where only the last memory cell contains a 1
    internal function LastCellFullQRAM(addressSize : Int) : MemoryBank {
        return GeneratedMemoryBank([MemoryCell(2^addressSize - 1, [true])]);
    }
    
    internal operation PrepareIntAddressRegister(address : Int, register : Qubit[]) 
    : Unit is Adj + Ctl {
        let queryAddressAsBoolArray = IntAsBoolArray(address, Length(register));
        ApplyPauliFromBitString(PauliX, true, queryAddressAsBoolArray, register);
    }


}
