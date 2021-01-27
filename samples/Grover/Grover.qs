namespace GroverSample {
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arithmetic;

    open QsharpCommunity.Qram;

    /// # Summary
    /// This sample is an adaptation of the Grover sample in the QDK documentation
    /// that uses a BucketBrigadeQRAM as an oracle, rather than the usual reflection
    /// about marked states.
    /// https://github.com/microsoft/Quantum/tree/master/samples/algorithms/simple-grover
    /// # Input
    /// ## addressSize
    /// How many bits to use for your address.
    /// ## markedElements
    /// The index of the element you want to search for.
    /// # Output
    /// The index of the marked element.
    /// # Remarks
    /// ## Example
    /// ```ps
    /// dotnet run -- --address-size 3 --marked-elements 4
    /// ```
    @EntryPoint()
    operation GroverSearch(addressSize : Int, markedElements : Int[]) : Int {
        // First, set up a qRAM with marked elements set to 1.
        let nMarkedElements = Length(markedElements);
        mutable groverMemoryContents = Mapped<Int,MemoryCell>(MemoryCell(_, [false]), RangeAsIntArray(0..2^addressSize - 1));

        // Set the data value to true for each marked address.
        for markedElement in markedElements {
            set groverMemoryContents w/= markedElement <- MemoryCell(markedElement, [true]);
		}

        use (groverQubits, targetQubit, flatMemoryRegister) = 
            (Qubit[addressSize], Qubit[1], Qubit[2^addressSize]);
        // Create a structured register to make indexing through the memory easier.
        let memoryRegister = PartitionMemoryRegister(
            flatMemoryRegister, 
            GeneratedMemoryBank(groverMemoryContents)
        );
        // Prepare the memory register with the initial data. 
        let memory = BucketBrigadeQRAMOracle(groverMemoryContents, memoryRegister);

        // Initialize a uniform superposition over all possible inputs.
        PrepareUniform(groverQubits);

        // Grover iterations - the reflection about the marked element is implemented
        // as a QRAM phase query. Only the memory cells storing a 1 will produce a phase.
        for idxIteration in 0..NIterations(nMarkedElements, addressSize) - 1 {

            memory::QueryPhase(AddressRegister(groverQubits), memoryRegister, targetQubit);
            ReflectAboutUniform(groverQubits);

            // It's necessary to remove phase since QueryPhase only sets phase 
            // on the specific address instead of inverting like traditional Grover's.
            ApplyToEach(Z, targetQubit);
            ResetAll(targetQubit);
        }
        ResetAll(flatMemoryRegister);

        // Measure and return the answer.
        ResetAll(targetQubit);
        return MeasureInteger(LittleEndian(groverQubits));
    }

    /// # Summary
    /// Returns the number of Grover iterations needed to find a single marked
    /// item, given the number of qubits in a register.
    function NIterations(nMarkedElements : Int, nQubits : Int) : Int {
        let nItems = 1 <<< nQubits; // 2^numQubits
        // compute number of iterations:
        let angle = ArcSin(Sqrt(IntAsDouble(nMarkedElements)) / Sqrt(IntAsDouble(nItems)));
        let nIterations = Round(0.25 * PI() / angle - 0.5);
        return nIterations;
    }

}
