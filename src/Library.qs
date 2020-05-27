namespace Memory{
    
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;

    /// Probably want Little Endian
    newtype QRAM = (Lookup : ((Qubit[], Qubit) => Unit is Adj + Ctl));

    /// # Summary
    /// Generates an oracle representing a bucket brigade style qRAM with a 
    /// list of address locations that contain the value 1.
    ///
    /// # Input
    /// ## Address
    /// An array of strings that documents the addresses where the value in 
    /// in memory is 1.
    ///  "0101000101"
    ///
    /// BB has a register of hardware qubits - need to know which of those are
    /// set to 1; easiest way to do that is to send a string like "0011" to indicate that
    /// this register is in the state
    ///
    /// |0> ------   (qubit 0, address 00)
    /// |0> ------   (qubit 1, address 01)
    /// |1> ------   (qubit 2, address 10)
    /// |1> ------   (qubit 3, address 11)
    ///
    /// This is a 2-bit address; so QRAM(00) = 0, QRAM(01) = 0, QRAM(10) = 1, QRAM(11) = 1
    ///
    /// The black box has to perform this operation ^^ given the inputs, based on the contents
    /// of the hardware register it starts with
 


    /// # Remarks
    /// ## Example
    /// ```Q#
    /// operation ReadoutSingleAddress(Memory : QRAM, Address : Bool[]) : Bool {
    ///     using ((addressQubits, target) = (Qubit[3], Qubit())) {
    ///         // prepare address value
    ///         ApplyPauliFromBitString (PauliX, true, Address, addressQubits);
    ///         QRAM(address, target);
    ///         return BoolFromResult(MResetZ(target));
    ///        }  
    ///     }
    /// ```
    ///
    /// # See Also
    /// - OperationName
    ///
    /// # References
    /// - [arXiv:0000.0000](https://arxiv.org/abs/0000.0000)
    function ImplicitQRAMOracle(OnesAddresses : Bool[][]) : QRAM {
        return QRAM(CreateImplicitQRAMOracle(OnesAddresses, _, _));
    }
    /// [[false, true, true], [false, false, false]]
    /// Target Register might be better?
    /// Can make target register with  loop over target qubits
    /// spec for OnesAddress could be an address and value
    operation CreateImplicitQRAMOracle(
        OnesAddresses: Bool[][], 
        AddressRegister : Qubit[],
        Target : Qubit) 
    : Unit is Adj + Ctl {
        for (address in OnesAddresses){
            (ControlledOnBitString(address, X))(AddressRegister, Target); 
        }
    }
}