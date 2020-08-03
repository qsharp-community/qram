namespace ResourcesEstimation {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Measurement;
    
    open Qram;

    function GenerateMemoryData() : MemoryBank {
        let numDataBits = 3;
        let data =  [(5, IntAsBoolArray(3, numDataBits)), 
            (4, IntAsBoolArray(2, numDataBits)), 
            (0, IntAsBoolArray(0, numDataBits)), 
            (2, IntAsBoolArray(5, numDataBits))];
        return GeneratedMemoryBank(Mapped(MemoryCell, data));
    }
    
    operation QueryAndMeasureQROM(memory : QROM, queryAddress : Int) : Int {
        using ((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])) {
            ApplyPauliFromBitString (PauliX, true, IntAsBoolArray(queryAddress, memory::AddressSize), addressRegister);
            memory::Read(LittleEndian(addressRegister), targetRegister);
            ResetAll(addressRegister);
            return MeasureInteger(LittleEndian(targetRegister));
        }
    }

    operation MeasureQROM(memory : QROM, queryAddress : Int) : Int {
        using ((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])) {
            ApplyPauliFromBitString (PauliX, true, IntAsBoolArray(queryAddress, memory::AddressSize), addressRegister);
            memory::Read(LittleEndian(addressRegister), targetRegister);
            ResetAll(addressRegister);
            return MeasureInteger(LittleEndian(targetRegister));
        }
    }



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

    operation MeasureQRAM(
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

    operation SetupBaseQRAM() : Unit {
        let data = GenerateMemoryData();
        // Create the QRAM.
        using (flatMemoryRegister = Qubit[(2^data::AddressSize) * data::DataSize]) {
            let memoryRegister = PartitionMemoryRegister(flatMemoryRegister, data);

            let memory = BucketBrigadeQRAMOracle(data::DataSet, memoryRegister);

            // Measure and return the data value stored at `queryAddress`.
            //let value = QueryAndMeasureQRAM(memory, memoryRegister, queryAddress); 

            ResetAll(flatMemoryRegister);
        }
    }

    operation QueryBaseQRAM(queryAddress : Int) : Int {
        let data = GenerateMemoryData();
        // Create the QRAM.
        using (flatMemoryRegister = Qubit[(2^data::AddressSize) * data::DataSize]) {
            let memoryRegister = PartitionMemoryRegister(flatMemoryRegister, data);

            let memory = BucketBrigadeQRAMOracle(data::DataSet, memoryRegister);

            // Measure and return the data value stored at `queryAddress`.
            let value = QueryAndMeasureQRAM(memory, memoryRegister, queryAddress); 

            ResetAll(flatMemoryRegister);
            return value;
        }
    }

}
