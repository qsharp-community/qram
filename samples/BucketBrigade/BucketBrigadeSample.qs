namespace BucketBrigadeSample {

    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    open Qram;

    /// # Summary
    /// Generates a Bucket Brigade Qram and looks up the data 
    /// stored at queryAddress.
    /// # Input
    /// ## queryAddress
    /// Address of the data you want to look up. The data is currently
    /// hardcoded below in GenerateMemoryData.
    /// # Output
    /// The data as an Int that is stored at queryAddress.
    /// # Remarks
    /// ## Example
    /// ```ps
    /// dotnet run -- --query-address 2
    /// ```
    @EntryPoint()
    operation BBBitEncodingSample(queryAddress : Int) : Int {
        // Generate a (Int, Bool[]) array of data.
        let data = GenerateMemoryData();
        // Create the QRAM.
        using (flatMemoryRegister = Qubit[(2^data::AddressSize) * data::DataSize]){
            let memoryRegister = Most(
                Partitioned(
                    ConstantArray(2^data::AddressSize, data::DataSize), 
                    flatMemoryRegister
                )
            );

            let memory = BucketBrigadeQRAMOracle(
                data::DataSet, 
                MemoryRegister(memoryRegister)
            );
            // Measure and return the data value stored at `queryAddress`.
            let value = QueryAndMeasureQRAM(memory, MemoryRegister(memoryRegister), queryAddress); 
            ResetAll(flatMemoryRegister);
            return value;
        }

    }

    /// # Summary
    /// Looks up the data in a memory at a specific address, queryAddress by 
    /// querying the memory and then measuring the result.
    /// # Input
    /// ## memory
    /// The Qram describing the memory.
    /// ## memoryRegister
    /// The qubit register holding the data of the Qram.
    /// ## queryAddress
    /// The address you want to look up the data at.
    /// # Output
    /// The value in the memory stored at queryAddress as an Int.
    operation QueryAndMeasureQRAM(
        memory : QRAM, 
        memoryRegister : MemoryRegister, 
        queryAddress : Int
    ) 
    : Int {
        using ((addressRegister, targetRegister) = 
            (Qubit[memory::AddressSize],  Qubit[memory::DataSize])
        ) {
            ApplyPauliFromBitString(PauliX, true, 
                IntAsBoolArray(queryAddress, memory::AddressSize), 
                addressRegister
            );
            memory::QueryBit(AddressRegister(addressRegister), 
                memoryRegister, targetRegister
            );
            ResetAll(addressRegister);
            return ResultArrayAsInt(MultiM(targetRegister));
        }
    }

    /// # Summary
    /// Generates sample data of the form (address, dataValue), here the
    /// hardcoded data being [(5, 3), (4, 1), (2, 2)]. 
    /// # Output
    /// Hardcoded data.
    function GenerateMemoryData() : MemoryBank {
        let numDataBits = 2;
        let data =  [
            (5, IntAsBoolArray(3, numDataBits)), 
            (4, IntAsBoolArray(1, numDataBits)), 
            (2, IntAsBoolArray(2, numDataBits))
        ];
        return GeneratedMemoryBank(Mapped(MemoryCell, data));
    }
}