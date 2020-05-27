namespace Memory {
    
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;

    newtype QRAM = (Lookup : ((Qubit[], Qubit) => Unit is Adj + Ctl), Size : Int);

    /// # Summary
    /// Generates an oracle representing a bucket brigade style qRAM with a 
    /// list of address locations that contain the value 1.
    ///
    /// # Input
    /// ## OnesAddresses
    /// An array of strings that documents the addresses where the value in 
    /// in memory is 1.
    ///
    /// # Remarks
    /// ## Example
    /// ```Q#
    /// operation ReadoutQRAM( Memory : QRAM, Address : Bool[]) : Bool {
    /// using ((addressQubits, target) = (Qubit[3], Qubit)) {
    ///     // prepare address value
    ///     ApplyPauliFromBitString (PauliX, true, Address, addressQubits);
    ///     QRAM(address, target);
    ///     return BoolFromResult(MResetZ(target));
    ///    }  
    /// }
    /// ```
    ///
    /// # See Also
    /// - OperationName
    ///
    /// # References
    /// - [arXiv:0000.0000](https://arxiv.org/abs/0000.0000)
    function BucketBrigadeOracle(OnesAddresses : String[]) : QRAM {
        //Generates an operation that takes an array of qubits describe
        true
    }
}
