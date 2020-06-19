namespace implicitQRAM {

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
    /// dotnet run -- --query-address false false
    /// ```

    operation TestImplicitQRAM(queryAddress : Int) : Int {
        // Generate a (Int, Bool[]) array of data.
        let data = GenerateMemoryData();
        // Create the QRAM.
        let memory = ImplicitQRAMOracle(data);
        // Write out some debugging info about our qRAM.
        Message($"qRAM address size: {memory::AddressSize} bits");
        Message($"qRAM data size:    {memory::DataSize} bits");
        // Measure and return the data value stored at `queryAddress`.
        return QueryAndMeasureQRAM(memory, queryAddress);
    }
    
    @EntryPoint()
    operation TestImplicitQRAMSuperPosition() : Int {
        // Generate a (Int, Bool[]) array of data.
        let data = GenerateMemoryData();
        // Create the QRAM.
        let memory = ImplicitQRAMOracle(data);
        // Measure and return the data value stored at `queryAddress`.
        return QuerySuperpositionAndMeasureQRAM(memory);
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
    operation QueryAndMeasureQRAM(memory : QRAM, queryAddress : Int) : Int {
        using ((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])) {
            ApplyPauliFromBitString (PauliX, true, IntAsBoolArray(queryAddress, memory::AddressSize), addressRegister);
            memory::Lookup(LittleEndian(addressRegister), targetRegister);
            ResetAll(addressRegister);
            return MeasureInteger(LittleEndian(targetRegister));
        }
    }

    operation QuerySuperpositionAndMeasureQRAM(memory : QRAM) : Int {
        using ((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])) {
            // Prepares the address register in superposition.
            ApplyToEach(H, addressRegister);
            DumpRegister((),addressRegister);
            // Performs the lookup on the qRAM
            memory::Lookup(LittleEndian(addressRegister), targetRegister);
            DumpMachine();
            // Be kind rewind
            ResetAll(addressRegister);
            
            return MeasureInteger(LittleEndian(targetRegister));
        }
    }

    /// # Summary
    /// Generates sample data of the form (address, dataValue), here the
    /// hardcoded data being [(5, 3), (4, 2), (1, 1)]. 
    /// # Output
    /// Hardcoded data.
    function GenerateMemoryData() : (Int, Bool[])[] {
        let fiveHasThree = (5, IntAsBoolArray(3, 2));
        let fourHasTwo = (4, IntAsBoolArray(2, 2));
        let oneHasOne = (1, IntAsBoolArray(1, 2));
        return [fourHasTwo];
    }
}
