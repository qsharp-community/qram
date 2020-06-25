namespace BucketBrigadeSample {

    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    open Qram;

    @EntryPoint()
    operation QromSample(queryAddress : Int) : Int {
        // Generate a (Int, Bool[]) array of data.
        let data = GenerateMemoryData();
        // Create the QRAM.
        let memory = BucketBrigadeQRAMOracle(data);
        using (memoryRegister = Qubit[memory::DataSize]){
            // Measure and return the data value stored at `queryAddress`.
            return QueryAndMeasureQRAM(memory, MemoryRegister(memoryRegister), queryAddress);
        }

    }

    operation QueryAndMeasureQRAM(
        memory : QRAM, 
        memoryRegister : MemoryRegister, 
        queryAddress : Int
    ) 
    : Int {
        using ((addressRegister, target) = (Qubit[memory::AddressSize],  Qubit())) {
            ApplyPauliFromBitString(PauliX, true, IntAsBoolArray(queryAddress, memory::AddressSize), addressRegister);
            DumpRegister((), memoryRegister!);
            memory::Read(AddressRegister(addressRegister), memoryRegister, target);
            ResetAll(addressRegister);
            return ResultArrayAsInt([MResetZ(target)]);
        }
    }

    /// # Summary
    /// Generates sample data of the form (address, dataValue), here the
    /// hardcoded data being [(5, 3), (4, 2), (1, 1)]. 
    /// # Output
    /// Hardcoded data.
    function GenerateMemoryData() : (Int, Bool[])[] {
        return [(0, [true]), (1, [true]), (2, [true]), (3, [true])];
    }
}