namespace GroverSample {
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arithmetic;

    open Qram;

    /// # Summary
    /// This sample is an adaptation of the Grover sample in the QDK documentation
    /// that uses a BucketBrigadeQRAM as an oracle, rather than the usual reflection
    /// about marked states.
    @EntryPoint()
    operation GroverSearch(addressSize : Int, markedElement : Int) : Int {
        // First, set up a qRAM with a single value set to 1
        let groverMemoryContents = [MemoryCell(markedElement, [true])];
 
        // Is there a better way to do this in the situation where the memory register
        // is not explicitly owned by the qRAM?
        // Also, the target is not really used here except to execute the query and perform
        // phase kickback
        using ((groverQubits, targetQubit, flatMemoryRegister) = 
            (Qubit[addressSize], Qubit[1], Qubit[2^addressSize])
        ) {
                // Create a memory
                // This part feels really clunky
                //let memoryRegister = MemoryRegister(Most(Partitioned(ConstantArray(2^addressSize, 1), flatMemoryRegister)));
                //let memory = BucketBrigadeQRAMOracle(groverMemoryContents, memoryRegister);

                DumpRegister("memory.txt", flatMemoryRegister);
                // Initialize a uniform superposition over all possible inputs.
                PrepareUniform(groverQubits);

                // Grover iterations - the reflection about the marked element is implemented
                // as a QRAM phase query. Only the memory cells storing a 1 will produce a phase
                for (idxIteration in 0..NIterations(addressSize) - 1) {
                    //memory::QueryPhase(AddressRegister(groverQubits), memoryRegister, targetQubit);
                    ReflectAboutMarked(groverQubits, markedElement);
                    ReflectAboutUniform(groverQubits);
                }

                ResetAll(flatMemoryRegister);

        
            // Measure and return the answer.
            ResetAll(targetQubit);
            return MeasureInteger(LittleEndian(groverQubits));
        }
    }

    /// # Summary
    /// Returns the number of Grover iterations needed to find a single marked
    /// item, given the number of qubits in a register.
    function NIterations(nQubits : Int) : Int {
        let nItems = 1 <<< nQubits; // 2^numQubits
        // compute number of iterations:
        let angle = ArcSin(1. / Sqrt(IntAsDouble(nItems)));
        let nIterations = Round(0.25 * PI() / angle - 0.5);
        return nIterations;
    }

}
