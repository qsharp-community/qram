namespace Qram{
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;

///////////////////////////////////////////////////////////////////////////
// PUBLIC API
///////////////////////////////////////////////////////////////////////////



    /// # Summary
    /// Creates an instance of a SelectSWAP QROM given the data it needs to store.
    /// Source: https://arxiv.org/abs/1812.00954
    /// # Input
    /// ## dataValues
    /// An array of memory cells where the address is an Int and the 
    /// data is a boolean array representing the user data.
    /// ## tradeoffFraction (TODO: RENAME)
    /// An array of memory cells where the address is an Int and the 
    /// data is a boolean array representing the user data.
    /// # Output
    /// A `QROM` type.
    function SelectSwapQromOracle(dataValues : MemoryCell[], tradeoffFraction : Int) : QROM {
        let bank = GeneratedMemoryBank(dataValues);
        // Replace
        let selectSwapQuery = selectSwap(bank, tradeoffFraction); 
        
        return Default<QROM>()
            w/ Read <- selectSwapQuery //Replace
            w/ AddressSize <- bank::AddressSize
            w/ DataSize <- bank::DataSize;
            // Add tradeoffFraction?
    }

///////////////////////////////////////////////////////////////////////////
// INTERNAL IMPLEMENTATION
///////////////////////////////////////////////////////////////////////////

    /// # Summary
    /// Creates circuitry for SelectSWAP qROM in two parts. 
    /// # Input
    /// ## dataValues
    /// A MemoryBank contained the addresses and contents of the memory
    /// # Output
    /// An operation that can be used to look up data `value` at `address`.
    internal operation selectSwap(bank : MemoryBank, tradeoffFraction : Int) 
    : ((LittleEndian, Qubit[]) => Unit is Adj + Ctl) {
        // Create qubit register
        // Call select + swap as per fig 1c of the paper; for data of non-power-2 
        // sizes we will have to also implement fig 1d.
        }
    }

    /// # Summary
    /// Select operation
    /// # Input
    /// 
    /// # Output
    /// 
    internal operation Select(bank : MemoryBank) 
    : Unit is Adj + Ctl {
        // Apply multiplexing operation
    }

    /// # Summary
    /// Swap operation
    /// # Input
    /// 
    /// # Output
    ///
    internal operation SwapNetwork(dataValues : MemoryBank) 
    : Unit is Adj + Ctl {
        // Apply swap network
    }

