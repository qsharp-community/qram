## General project goals

- Proficiency with Q# as a programming language
- Understanding the role of qRAM in quantum computing, its benefits, and costs
- Describe the different memory paradigms in quantum machine learning

### Bonus goals

- Actually run a small qRAM on a quantum machine; how well does it work?
- Describe the different types of classical RAM
- Describe how one might implement a qRAM in hardware

## Key Deliverables

- Q# Library, to be released open-source
  - Implementations:
    - [ ] Bucket-brigade (original circuit model, and updated constant-depth model)
    - [ ] Various qROMs
    - [ ] Quantum state preparation ("select/SWAP" oracles)
    - [ ] Application-specific qROMs
  - Samples:
    - [ ] Instantiation and querying all implemented qRAMs/qROMs
    - [ ] Resource estimation
- Written report about the different methods used

### Pre-reading

- Learn about how classical RAMs work (bitlines, wordlines, capacitors, structure, etc.)

### Step 1
- Set up QDK and Python development environments
- Get acquainted with Q#. Set up QDK and Python
- Work through some of the quantum katas (on-going)
- Read original bucket-brigade qRAM papers (https://arxiv.org/abs/0708.1879, https://arxiv.org/pdf/0807.4994)

### Step 2
- Read through work with basic qROM circuits (https://arxiv.org/abs/1902.01329)
- Implement basic large-depth large-width circuits in Q#
   - Set up framework for random-generation of such circuits (on-going; should do for these, and all future types)

### Step 3
- Implement bucket brigade circuits (https://arxiv.org/abs/1502.03450)
- Implement Alexandru's constant-depth bucket-brigade circuits (https://arxiv.org/abs/2002.09340)
- Start running circuits in the resources estimator and Toffoli simulator machines (on-going) - with random versions of these circuits, how do the gate counts compare to the ones from our paper?

### Step 4
- Implement Vadym and Guang-How's state preparation circuits (select/SWAP) (https://arxiv.org/abs/1812.00954)
  - Get an idea of the actual constants in the runtime
- Implement qROM from "encoding electronic spectra" paper (https://arxiv.org/abs/1805.03662)

### Step 5
- Writing up findings, documenting code, and getting ready for release
    - Publish on Blog etc.