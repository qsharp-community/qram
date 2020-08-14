namespace SelectSwapSample {

    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    open Qram;
    
    /// # Summary
    /// Does a quick test of creating an implicit QRAM and then looks up a
    /// specific data value stored in it.
    /// # Input
    /// ## queryAddress
    /// The address you want to lookup.
    /// ## tradeoffParameter
    /// VALID VALUES HERE ARE {1, 2, 3}
    /// # Output
    /// The data value stored at `queryAddress`.
    /// # Remarks
    /// ## Example
    /// ```ps
    /// dotnet run -- --query-address 2 --tradeoff-parameter 2
    /// ```
    @EntryPoint()
    operation QromQuerySample(tradeoffParameter : Int) : Int[] {
        // Generate a (Int, Bool[]) array of data.
        let data = GenerateMemoryData();
        // Create the QRAM.
        let memory = SelectSwapQromOracle(data::DataSet, tradeoffParameter);
        // Measure and return the data value stored at `queryAddress`.
        mutable results = new Int[2^data::AddressSize];
        for (address in 0..2^data::AddressSize-1) {
            set results w/= address <- QueryAndMeasureQROM(memory, address);
        } 

        return results;
    }

    /// # Summary
    /// Takes a QRAM and tells you what data is stored at a single address.
    /// # Input
    /// ## memory
    /// A QRAM to query.
    /// ## queryAddress
    /// The address you want to look up.
    /// # Outputs
    /// The data stored at `queryAddress` expressed as a human readable integer.
    operation QueryAndMeasureQROM(memory : QROM, queryAddress : Int) : Int {
        using ((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])) {
            ApplyPauliFromBitString (PauliX, true, Reversed(IntAsBoolArray(queryAddress, memory::AddressSize)), addressRegister);
            memory::Read(LittleEndian(addressRegister), targetRegister);
            ResetAll(addressRegister);
            return MeasureInteger(LittleEndian(targetRegister));
        }
    }

    /// # Summary
    /// Generates sample data of the form (address, dataValue), here the
    /// hardcoded data being [(5, 3), (4, 2), (0, 0), (2, 5)]. 
    /// # Output
    /// Hardcoded data.
    function GenerateMemoryData() : MemoryBank {
        let numDataBits = 2;
        let data =  [
            (0, IntAsBoolArray(0, numDataBits)), 
            (1, IntAsBoolArray(1, numDataBits)), 
            (2, IntAsBoolArray(2, numDataBits)),
            (3, IntAsBoolArray(3, numDataBits)),
            (4, IntAsBoolArray(0, numDataBits)), 
            (5, IntAsBoolArray(1, numDataBits)),
            (6, IntAsBoolArray(2, numDataBits)),
            (7, IntAsBoolArray(3, numDataBits)),
            (8, IntAsBoolArray(0, numDataBits)),
            (9, IntAsBoolArray(1, numDataBits)),
            (10, IntAsBoolArray(2, numDataBits)),
            (11, IntAsBoolArray(3, numDataBits)),
            (12, IntAsBoolArray(0, numDataBits)),
            (13, IntAsBoolArray(1, numDataBits)),
            (14, IntAsBoolArray(2, numDataBits)),
            (15, IntAsBoolArray(3, numDataBits))
        ];
        return GeneratedMemoryBank(Mapped(MemoryCell, data));
    }
}
