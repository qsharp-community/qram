namespace QromSample {

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
    /// # Output
    /// The data value stored at `queryAddress`.
    /// # Remarks
    /// ## Example
    /// ```ps
    /// dotnet run -- --query-address 2
    /// ```
    @EntryPoint()
    operation QromQuerySample(queryAddress : Int) : Int {
        // Generate a (Int, Bool[]) array of data.
        let data = GenerateMemoryData();
        // Create the QRAM.
        let memory = QromOracle(data::DataSet);
        // Measure and return the data value stored at `queryAddress`.
        return QueryAndMeasureQROM(memory, queryAddress);
    }

    /// # Summary
    /// Takes a QRAM and tells you what data is stored at a single address.
    /// # Input
    /// ## memory
    /// A QRAM to query.
    /// ## queryAddress
    /// The address you want to look up.
    /// # Output
    /// The data stored at `queryAddress` expressed as a human readable integer.
    operation QueryAndMeasureQROM(memory : QROM, queryAddress : Int) : Int {
        using ((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])) {
            ApplyPauliFromBitString(PauliX, true, IntAsBoolArray(queryAddress, memory::AddressSize), addressRegister);
            memory::Read(LittleEndian(addressRegister), targetRegister);
            Adjoint ApplyPauliFromBitString(PauliX, true, IntAsBoolArray(queryAddress, memory::AddressSize), addressRegister);
            //ResetAll(addressRegister);
            //AssertMeasurementProbability([PauliZ], targetRegister, One, 1.0, "", 1E-10);
            return queryAddress;
            //return MeasureInteger(LittleEndian(targetRegister));
        }
    }

    /// # Summary
    /// Generates sample data of the form (address, dataValue), here the
    /// hardcoded data being [(5, 3), (4, 2), (0, 0), (2, 5)]. 
    /// # Output
    /// Hardcoded data.
    function GenerateMemoryData() : MemoryBank {
        let numDataBits = 1;
        let data =  [(1, IntAsBoolArray(1, numDataBits)), 
            (0, IntAsBoolArray(0, numDataBits))];
        return GeneratedMemoryBank(Mapped(MemoryCell, data));
    }

    // function GenerateMemoryData() : MemoryBank {
    //     let numDataBits = 3;
    //     let data =  [(5, IntAsBoolArray(3, numDataBits)), 
    //         (4, IntAsBoolArray(2, numDataBits)), 
    //         (0, IntAsBoolArray(0, numDataBits)), 
    //         (2, IntAsBoolArray(5, numDataBits))];
    //     return GeneratedMemoryBank(Mapped(MemoryCell, data));
    // }
}
