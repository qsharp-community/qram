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
    open Qram;

    internal function DataAtAddress(
        data : (Int, Bool[])[],
        queryAddress : Int 
    ) 
    : Bool[] {
        // Find the index in the original dataset with a particular address
        let addressIndex = Where(MatchedAddress(_, queryAddress), data);
        // The address you are looking for may not have been explicitly given
        if (IsEmpty(addressIndex)){
            // Need to pad out the bool array for 0 to the right length
            let dataLength = Length(Snd(data[0]));
            return ConstantArray(dataLength, false);
        }
        else {
            // Look up the actual data value at the correct address index
            return Snd(data[Head(addressIndex)]);
        }
    }

    /// # Summary
    /// Work around for lambda functions, checks if first element in a tuple
    /// is a particular integer.
    /// # Input
    /// ## dataTuple
    /// Represents a single address and data value pair in the memory.
    /// ## queryAddress
    /// The address you are looking to find.
    /// # Output
    /// Bool representing if that tuple has the address you are looking for.
    internal function MatchedAddress(
        dataTuple : (Int, Bool[]), 
        queryAddress : Int
    ) 
    : Bool {
        return EqualI(Fst(dataTuple), queryAddress);
    }

    // Hardcoded data set
    internal function GenerateSingleBitData() : (Int, Bool[])[] {
        return [(5, [true]), (4, [true]), (1, [false]), (2, [false])];
    }

    // QRAM where every memory cell contains a 0
    internal function GenerateEmptyQRAM(addressSize : Int) : (Int, Bool[])[] {
        let addresses = SequenceI(0, 2^addressSize - 1);
        let data = ConstantArray(2^addressSize, [false]);
        return Zip(addresses, data);
    }

    // QRAM where every memory cell contains a 1
    internal function GenerateFullQRAM(addressSize : Int) : (Int, Bool[])[] {
        let addresses = SequenceI(0, 2^addressSize - 1);
        let data = ConstantArray(2^addressSize, [true]);
        return Zip(addresses, data);
    }

    // QRAM where only the first memory cell contains a 1
    internal function GenerateFirstCellFullQRAM() : (Int, Bool[])[] {
        return [(0, [true])];
    }

    // QRAM where only the second memory cell contains a 1
    internal function GenerateSecondCellFullQRAM() : (Int, Bool[])[] {
        return [(1, [true])];
    }

    // QRAM where only the last memory cell contains a 1
    internal function GenerateLastCellFullQRAM(addressSize : Int) : (Int, Bool[])[] {
        return [(2^addressSize - 1, [true])];
    }
    

    // Hardcoded data set for a multi-bit output situation
    internal function GenerateMultiBitData() : (Int, Bool[])[] {
        let numDataBits = 3;
        let fiveHasThree = (5, IntAsBoolArray(3, numDataBits));
        let fourHasTwo = (4, IntAsBoolArray(2, numDataBits));
        let oneHasZero = (0, IntAsBoolArray(0, numDataBits));
        let twoHasFive = (2, IntAsBoolArray(5, numDataBits));
        return [fiveHasThree, fourHasTwo, oneHasZero, twoHasFive];
    }


}