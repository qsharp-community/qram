namespace Qram{
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;

    // Notes:
    // Target Register might be better?
    // Can make target register with  loop over target qubits
    // spec for OnesAddress could be an address and value

    // TODO: Probably want LittleEndian for address, data can be whatever
    // Type that 
    newtype QRAM = (Lookup : ((Qubit[], Qubit) => Unit is Adj + Ctl), AddressSize : Int);

    function SingleImplicitQRAMOracle(OnesAddresses : Bool[][]) : QRAM {
        let addressLength = Length(Head(OnesAddresses));
        return Default<QRAM>()
            w/ Lookup <- ApplySingleImplicitQRAMOracle(OnesAddresses, _, _)
            w/ AddressSize <- addressLength;
    }


    internal operation ApplySingleImplicitQRAMOracle(
        OnesAddresses: Bool[][], 
        AddressRegister : Qubit[],
        Target : Qubit
    )
    : Unit is Adj + Ctl {
        for (address in OnesAddresses) {
            (ControlledOnBitString(address, X))(AddressRegister, Target); 
        }
    }

    // [5,0,2,8,7]
    // Assume that if data is not power of 2, assume rest 0s
    internal function OnesAddressesFromData(dataArray : Bool[][]) : Bool[][][] {
        let numDataBits = Length(Head(dataArray));
        mutable onesAddresses = new Bool[][][numDataBits];
        
        for (idx in 0..numDataBits) {
            set onesAddresses w/=idx <- AddressesFromData(ElementsAt(dataArray, idx));
        }
        return onesAddresses;
    }


///////////////////////////////////////////////////////////////////////////
// UTILITY FUNCTIONS
///////////////////////////////////////////////////////////////////////////
    internal function AddressesFromData(dataArray : Bool[]) : Bool[][] {
        mutable onesAddresses = new Bool[][0];
        let nBits = BitSizeI(Length(dataArray));
        for ((idx, bitValue) in Enumerated(dataArray)) {
            if (bitValue) {
                set onesAddresses += [IntAsBoolArray(idx, nBits)];
            }
        }
        return onesAddresses;
    }

    internal function ElementsAt<'T>(dataArrayArray : 'T[][], n : Int) : 'T[] {
        return Mapped(ElementAt<'T>(_, n), dataArrayArray);
    }

    internal function ElementAt<'T>(array : 'T[], idx : Int) : 'T {
        return array[idx];
    }




    /// # Summary
    /// Generates an oracle representing a bucket brigade style qRAM with a 
    /// list of address locations that contain the value 1.
    ///
    /// # Input
    /// ## Address
    /// An array of strings that documents the addresses where the value in 
    /// in memory is 1.
    ///
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
}
