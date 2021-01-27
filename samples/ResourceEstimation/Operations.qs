namespace ResourceEstimation {
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open QsharpCommunity.Qram;
    
    operation QromQuerySample(rawData : (Int, Bool[])[], queryAddress : Int) : Int {
        // Generate a (Int, Bool[]) array of data.
        let data = ParseMemoryData(rawData);
        // Create the QRAM.
        let memory = QromOracle(data::DataSet);
        // Measure and return the data value stored at `queryAddress`.
        return QueryAndMeasureQROM(memory, queryAddress);
    }

    operation QueryAndMeasureQROM(memory : QROM, queryAddress : Int) : Int {
        use (addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize]);
        ApplyPauliFromBitString (PauliX, true, IntAsBoolArray(queryAddress, memory::AddressSize), addressRegister);
        memory::Read(LittleEndian(addressRegister), targetRegister);
        ResetAll(addressRegister);
        return MeasureInteger(LittleEndian(targetRegister));
    }

    function ParseMemoryData(data : (Int, Bool[])[]) : MemoryBank{
        return GeneratedMemoryBank(Mapped(MemoryCell, data));
    }


}
