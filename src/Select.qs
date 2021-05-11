namespace QsharpCommunity.Qram {
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Math;

///////////////////////////////////////////////////////////////////////////
// PUBLIC API
///////////////////////////////////////////////////////////////////////////

    /// # Summary
    /// Creates an instance of a QROM based on unary iteration given the data it needs to store.
    /// Source: https://arxiv.org/abs/1805.03662.
    /// # Input
    /// ## dataValues
    /// An array of memory cells where the address is an Int and the 
    /// data is a boolean array representing the user data.
    /// # Output
    /// A `QROM` type.
    function SelectQromOracle(dataValues : MemoryCell[]) : QROM {
        let memoryBank = GeneratedMemoryBank(dataValues);
        let largestAddress = Max(Mapped(AddressLookup, dataValues));
        let data = MappedOverRange(DataAtAddress(memoryBank, _), 0..largestAddress);

        return Default<QROM>()
            w/ Read <- ApplySelectNetwork(data, _, _)
            w/ AddressSize <- memoryBank::AddressSize
            w/ DataSize <- memoryBank::DataSize;
    }


///////////////////////////////////////////////////////////////////////////
// INTERNAL IMPLEMENTATION
///////////////////////////////////////////////////////////////////////////

    /// # Summary
    /// Recursive implementation of QROM.
    ///
    /// # Description
    /// The controlled variant of this operation allows for a recursive
    /// decomposition into two parts that splits `data` into a lower part
    /// of length $2^{n-1}$ and an upper part of length $N-2^{n-1}$, where
    /// $N$ is the length of `data` and $n$ is the number of bits in the
    /// `address` register.
    ///
    /// The operation requires one additional helper qubit for each recursion
    /// level.
    ///
    /// # Input
    /// ## data
    /// The bit strings of the memory bank.
    /// ## address
    /// The address register.
    /// ## target
    /// The target register.
    internal operation ApplySelectNetwork(data : Bool[][], address : LittleEndian, target : Qubit[]) : Unit is Adj + Ctl {
        body (...) {
            let (N, n) = DimensionsForSelect(data, address);

            if N == 1 { // base case
                WriteMemoryContents(Head(data), target);
            } else {
                let (most, tail) = MostAndTail(address![...n - 1]);
                let parts = Partitioned([2^(n - 1)], data);

                within {
                    X(tail);
                } apply {
                    Controlled ApplySelectNetwork([tail], (parts[0], LittleEndian(most), target)); 
                }

                Controlled ApplySelectNetwork([tail], (parts[1], LittleEndian(most), target)); 
            }
        }
        adjoint auto;

        controlled (ctls, ...) {
            let (N, n) = DimensionsForSelect(data, address);

            Fact(Length(ctls) == 1, "table lookup can only be controlled with single control line");
            let ctl = Head(ctls);

            if N == 1 { // base case
                Controlled WriteMemoryContents(ctls, (Head(data), target));
            } else {
                use helper = Qubit();

                let (most, tail) = MostAndTail(address![...n - 1]);
                let parts = Partitioned([2^(n - 1)], data);

                within {
                    X(tail);
                } apply {
                    ApplyAnd(ctl, tail, helper);
                }

                Controlled ApplySelectNetwork([helper], (parts[0], LittleEndian(most), target));

                CNOT(ctl, helper);

                Controlled ApplySelectNetwork([helper], (parts[1], LittleEndian(most), target));

                Adjoint ApplyAnd(ctl, tail, helper);
            }
        }
        controlled adjoint auto;
    }

    /// # Summary
    /// Validates and adjusts dimensions for address register
    ///
    /// # Description
    /// Given $N$ bit strings in `data` and an address register of length $n'$,
    /// this function first checks whether $N \neq 0$ and $\lceil\log_2 N\rceil = n \le n'$,
    /// and then returns the tuple $(N, n)$.
    ///
    /// # Input
    /// ## data
    /// The bit strings of the memory bank.
    /// ## address
    /// The address register.
    internal function DimensionsForSelect(data : Bool[][], address : LittleEndian) : (Int, Int) {
        let N = Length(data);
        Fact(N > 0, "data cannot be empty");

        let n = Ceiling(Lg(IntAsDouble(N)));
        Fact(Length(address!) >= n, $"address register is too small, requires at least {n} qubits");

        return (N, n);
    }

    /// # Summary
    /// Writes out memory contents of a single bit string
    ///
    /// # Input
    /// ## value
    /// Single bit string.
    /// ## target
    /// Target register.
    internal operation WriteMemoryContents(value : Bool[], target : Qubit[]) : Unit is Adj + Ctl {
        EqualityFactI(Length(value), Length(target), "number of data bits must equal number of target qubits");

        ApplyPauliFromBitString(PauliX, true, value, target);
    }

}
