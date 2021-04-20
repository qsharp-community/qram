namespace Tests {
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Logical;
    open QsharpCommunity.Qram;    


    // Basic lookup with all addresses checked, all valid tradeoff parameters tested
    // for single-bit data.
    @Test("ToffoliSimulator")
    operation SelectOracleSingleBitSingleLookupMatchResults() : Unit {
        let data = SingleBitData();
        let largestAddress = Max(Mapped(AddressLookup, data::DataSet));
        for i in 0..largestAddress {
            for control in [true, false] {
                CreateQueryMeasureOneAddressSelect(data, i, control);
            }
        }
    }

    // Basic lookup with all addresses checked, all valid tradeoff parameters tested
    // for multi-bit data.
    @Test("ToffoliSimulator")
    operation SelectOracleMultiBitSingleLookupMatchResults() : Unit {
        let data = MultiBitData();
        let largestAddress = Max(Mapped(AddressLookup, data::DataSet));
        for i in 0..largestAddress {
            for control in [true, false] {
                CreateQueryMeasureOneAddressSelect(data, i, control);
            }
        }
    }

    internal operation CreateQueryMeasureOneAddressSelect(
        data : MemoryBank, 
        queryAddress : Int,
        control : Bool
    ) 
    : Unit {
        // Get the data value you expect to find at queryAddress
        let expectedValue = DataAtAddress(data, queryAddress);
        let emptyValue = ConstantArray(data::DataSize, false);

        // Create the new Qrom oracle
        let memory = SelectQromOracle(data::DataSet);

        use (addressRegister, targetRegister) = 
            (Qubit[memory::AddressSize], Qubit[memory::DataSize]);

        if control {
            use ctl = Qubit();

            for active in [true, false] {
                within {
                    // Activate control qubit
                    ApplyIfA(X, active, ctl);
                    // Prepare the address register
                    ApplyXorInPlace(queryAddress, LittleEndian(addressRegister));
                } apply {
                    // Perform the lookup
                    Controlled memory::Read([ctl], (LittleEndian(addressRegister), targetRegister));
                }

                // Get results and make sure its the same format as the data provided i.e. Bool[].
                let result = ResultArrayAsBoolArray(ForEach(MResetZ, targetRegister));
                AllEqualityFactB(result, active ? expectedValue | emptyValue,
                    $"Expecting value {expectedValue} at address {queryAddress}, got {result}.");
            }
        } else {
            within {
                // Prepare the address register
                ApplyXorInPlace(queryAddress, LittleEndian(addressRegister));
            } apply {
                // Perform the lookup
                memory::Read(LittleEndian(addressRegister), targetRegister);
            }

            // Get results and make sure its the same format as the data provided i.e. Bool[].
            let result = ResultArrayAsBoolArray(ForEach(MResetZ, targetRegister));
            AllEqualityFactB(result, expectedValue, 
                $"Expecting value {expectedValue} at address {queryAddress}, got {result}.");
        }
    }
}
