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

            if (N == 1) { // base case
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

    internal function DimensionsForSelect(data : Bool[][], address : LittleEndian) : (Int, Int) {
        let N = Length(data);
        Fact(N > 0, "data cannot be empty");

        let n = Ceiling(Lg(IntAsDouble(N)));
        Fact(Length(address!) >= n, $"address register is too small, requires at least {n} qubits");

        return (N, n);
    }

    internal operation WriteMemoryContents(value : Bool[], target : Qubit[]) : Unit is Adj + Ctl {
        EqualityFactI(Length(value), Length(target), "number of data bits must equal number of target qubits");

        ApplyPauliFromBitString(PauliX, true, value, target);
    }

}
