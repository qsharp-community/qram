namespace implicitQRAM {

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
    /// dotnet run -- --query-address false false
    /// ```
    @EntryPoint()
    operation TestImplicitQRAM(queryAddress : Bool[]) : Int {
        // Generate a (Bool[], Bool[]).
        let data = GenerateMemoryData();
        // Create the QRAM.
        let blackBox = ImplicitQRAMOracle(data);
        // Measure and return the data value stored at `queryAddress`.
        return QueryAndMeasureQRAM(blackBox, queryAddress);
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
    operation QueryAndMeasureQRAM(memory : QRAM, queryAddress : Bool[]) : Int {
        using((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])){
            ApplyPauliFromBitString (PauliX, true, queryAddress, addressRegister);
            memory::Lookup(LittleEndian(addressRegister), targetRegister);
            ResetAll(addressRegister);
            return MeasureInteger(LittleEndian(targetRegister));
        }
    }

    /// # Summary
    /// Generates sample data of the form (address, dataValue), here the
    /// hardcoded data being [(5, 3), (4, 2), (1, 1)]. 
    /// # Output
    /// Hardcoded data.
    function GenerateMemoryData() : (Bool[], Bool[])[] {
        let fiveHasThree = (IntAsBoolArray(5,3),IntAsBoolArray(3,2));
        let fourHasTwo = (IntAsBoolArray(4,3),IntAsBoolArray(2,2));
        let oneHasOne = (IntAsBoolArray(1,3),IntAsBoolArray(1,2));
        return [fiveHasThree, fourHasTwo, oneHasOne];
    }
}

