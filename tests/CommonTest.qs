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
        let fiveHasOne = (5, [true]);
        let fourHasOne = (4, [true]);
        let oneHasZero = (0, [false]);
        let twoHasZero = (2, [false]);
        return [fiveHasOne, fourHasOne, oneHasZero, twoHasZero];
    }

    internal function GenerateMultiBitData() : (Int, Bool[])[] {
        let numDataBits = 3;
        let fiveHasThree = (5, IntAsBoolArray(3, numDataBits));
        let fourHasTwo = (4, IntAsBoolArray(2, numDataBits));
        let oneHasZero = (0, IntAsBoolArray(0, numDataBits));
        let twoHasFive = (2, IntAsBoolArray(5, numDataBits));
        return [fiveHasThree, fourHasTwo, oneHasZero, twoHasFive];
    }


}