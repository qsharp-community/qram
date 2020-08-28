# qRAM Library for Q\#

[![Unitary Fund](https://img.shields.io/badge/Supported%20By-UNITARY%20FUND-brightgreen.svg?style=flat)](http://unitary.fund)

This library implements a variety of different proposals for memory for quantum computers, also commonly called qRAM.

> Want to learn more about what qRAM is?
> Check out the [primer on memory for quantum computers](https://github.com/qsharp-community/qram/tree/master/docs/primer.pdf) in our docs!

## Motivation

There are many different proposals for qRAM in quantum computing that each have different tradeoffs, and currently come up a lot in quantum machine learning applications.
We want to better understand the costs and benefits of different qRAM implementations in quantum machine learning as well as quantum computing more generally.
This library will help achieve these goals by giving us a concrete way to measure the resources each approach takes; choosing to do this in Q# allows us to leverage the built-in resource estimator to quickly iterate profiling the qRAM implementations and optimizing the circuits.

#### FAQ:

- **Do I need a qRAM?**

  _Sometimes_.
  You'll need a qRAM, or some more general means of _quantum state preparation_ in quantum machine learning (QML) algorithms that require you to load in classical data, or query an oracle that returns classical data. I've heard a number of stories of people working on QML being actively discouraged from doing so because ``QML won't work without a qRAM''. That's just not true, because *many QML algorithms do not need a qRAM*. Now, whether or not they yield any quantum advantage is a separate question, and won't be discussed here. The key point is that *some* QML algorithms need a qRAM, and they will potentially run into trouble as per the next question.
  
- **Can we design an efficient qRAM?**

  _Maybe_. In the primer we'll take a look at proposals that will in principle run in polynomial depth, and others that scale far worse. There are some very interesting qubit-time tradeoffs one can explore, in particular if the data being stored has some sort of underlying structure. Regardless, even if we can design an efficient circuit, we'd also like something that is efficient in a fault-tolerant setting, and this is potentially very expensive.

- **Can I build one?**

  _Maybe_. No one has actually done so, but there are a handful of hardware proposals that will be discussed in more detail in the hardware section of [the primer on memory for quantum computers](https://github.com/qsharp-community/qram/tree/master/docs/primer.pdf).

## Build status

[![Run Tests](https://github.com/qsharp-community/qram/workflows/Run%20Tests/badge.svg)](https://github.com/qsharp-community/qram/actions?query=workflow%3A%22Run+Tests%22)
[![Build and publish NuGet package to GitHub packages](https://github.com/qsharp-community/qram/workflows/Build%20and%20publish%20NuGet%20package%20to%20GitHub%20packages/badge.svg)](https://github.com/qsharp-community/qram/actions?query=workflow%3A%22Build+and+publish+NuGet+package+to+GitHub+packages%22)

## Code style

[![q# code style](https://img.shields.io/badge/code%20style-Q%23-blue)](https://docs.microsoft.com/quantum/contributing/style-guide?tabs=guidance)
[![q# APIcode style](https://img.shields.io/badge/code%20style-Q%23%20API-ff69b4)](https://docs.microsoft.com/quantum/contributing/style-guide?tabs=guidance)
[![c# APIcode style](https://img.shields.io/badge/code%20style-C%23-lightgrey)](https://docs.microsoft.com/dotnet/csharp/programming-guide/inside-a-program/coding-conventions)
[![CoC](https://img.shields.io/badge/code%20of%20conduct-contributor%20covenant-yellow)](CODE_OF_CONDUCT.md)

## Screenshots

**Example of a Bucket Brigade qRAM circuit:**
TODO: Q# notebook screenshots/gif
TODO: Source in VS Code/gif

![Bucket Brigade qRAM](docs/images/bb.gif)

## Tech/framework used

**Built with:**

- [Quantum Development Kit](https://docs.microsoft.com/quantum/)
- [.NET Core SDK 3.1](https://dotnet.microsoft.com/download/dotnet-core/3.1)
- [Python](https://www.python.org/downloads/)
- [Visual Studio Code](https://code.visualstudio.com/) and [Visual Studio](https://visualstudio.microsoft.com/)
- [Jupyter Notebook](https://jupyter.org/)

## Features

This library implements a [**variety of different approaches**]() for qRAM and qROM, including:

- **Bucket Brigade qRAM:** A read/write style memory where specific qubits are set aside to hold the data in the memory. The information can be queried so that the data returned is either bit encoded or phase encoded.
  - Relevant paper(s): Initial proposals in [0708.1879](https://arxiv.org/abs/0708.1879), [0807.4994](https://arxiv.org/abs/0807.4994); circuit model [1502.03450](https://arxiv.org/abs/1502.03450), and recent optimization [2002.09340](https://arxiv.org/abs/2002.09340)

- **qROM:** A read-only style memory that creates a fixed operation that given an address and a target, encodes the data at that address on the target. qROMs are like quantum lookup tables.
  - Relevant paper(s): [Shafaei et al.](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.407.9599), [Abdessaied et al.](https://ieeexplore.ieee.org/document/7515539), [1902.01329](https://arxiv.org/abs/1902.01329).
- **SELECT-SWAP qROM:** A read-only style memory similar to the basic qROM but that has multiplexing optimizations that can help you adjust your program resources.
  - Relevant paper(s): [1812.00954](https://arxiv.org/abs/1812.00954). 

It is important to us that we come up with an extensible framework for implementing as many qRAM/qROM implementation as possible so we can have a uniform way to evaluate and compare these proposals.
We also include a [**sample for doing resource estimation**](./samples/ResourcesEstimation) (and not actually simulating) so that you can get an idea of what the resources are needed to run your memory.

To validate the qRAM/qROM implementations in this library, this library includes [**unit tests for small memories**](./tests/) that can be simulated classically.

This library is highly portable, and can easily be added to any Q# project with just a package include in your project file!
Check out the [**instructions below**](./README.md#how-to-use) for adding the qRAM library to your project.

## Code Example

### Creating and then measuring a read-only memory:

```c# <!--FIXME-->
operation QromQuerySample(queryAddress : Int) : Int {
    // Generate a (Int, Bool[]) array of data.
    let data = GenerateMemoryData();
    // Create the QRAM.
    let memory = QromOracle(data::DataSet);
    // Measure and return the data value stored at `queryAddress`.
    return QueryAndMeasureQROM(memory, queryAddress);
}
```
See [Qrom sample](/samples/Qrom) for the rest of this implementation!

### Using a phase query Bucket Brigade QRAM to reflect about a marked state:

```c# <!--FIXME-->
operation GroverSearch(addressSize : Int, markedElements : Int[]) : Int {
  // First, set up a qRAM with marked elements set to 1.
  let nMarkedElements = Length(markedElements);
  mutable groverMemoryContents = Mapped<Int,MemoryCell>(MemoryCell(_, [false]), RangeAsIntArray(0..2^addressSize - 1));

  // Set the data value to true for each marked address.
  for (markedElement in markedElements) {
    set groverMemoryContents w/= markedElement <- MemoryCell(markedElement, [true]);
  }

  using ((groverQubits, targetQubit, flatMemoryRegister) =
      (Qubit[addressSize], Qubit[1], Qubit[2^addressSize])
  ) {
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
        for (idxIteration in 0..NIterations(nMarkedElements, addressSize) - 1) {
          
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
}
```
See [the Grover sample](/samples/Grover) for the rest of this implementation!

TODO: #37
<!--Show what the library does as concisely as possible, developers should be able to figure out **how** your project solves their problem by looking at the code example. Make sure the API you are showing off is obvious, and that your code is short and concise.-->

## Installation

Anywhere you can use Q#, you can use this library!

- Python host program
- Jupyter Notebooks
- Stand-alone command line application
- C#/F# host program

For complete and up-to-date ways to install the Quantum Development Kit (including Q# tooling) see [the official Q# docs](https://docs.microsoft.com/quantum/quickstarts/).

For convenience, in this repo we include the following ways to make it easier to use this project.

- [Remote Development Environment (VS Code)](https://code.visualstudio.com/blogs/2019/05/02/remote-development)
  - Once you open this repo in VS Code, you should be able to open the command pallet and select `Remote-Containers: Reopen in Container` and your editor will re-launch in a local docker container that will be properly configured to use the project.
- Binder in-browser host (Web): TODO: Test

## API Reference

TODO: See [#27](https://github.com/qsharp-community/qram/issues/27)

## Tests

The tests for this library all live in the `tests` directory.
To run the tests, navigate to that directory and run `dotnet test` and the .NET project will find and run all the tests in this directory.
If you are adding new features or functionality, make sure to add some tests to either the existing files, or make a new one.
For more info on writing tests for Q#, check out the [official Q# docs](https://docs.microsoft.com/quantum/user-guide/using-qsharp/testing-debugging).

## How to use?

### You want to use a published version of the library package:

TODO: more detail on nuget.org stuff once published there.

_For more information on adding packages to Q# projects (the instructions are the same as for C# packages) check out the [official docs](https://docs.microsoft.com/nuget/consume-packages/install-use-packages-dotnet-cli#install-a-package)._

### You want to work on developing the library and use a locally built version of the project:

The basic idea in this case is build locally a version of the nuget packages and then put it in a folder locally that is a known source to nuget.

0. Remove any previous copies of the package from your local nuget feed (you likely picked this location), and global nuget cache (default path on Windows 10 for the cache is below):

```Powershell
> rm C:\Users\skais\nuget-packages\QSharpCommunity.Libraries.Qram.X.X.X.nupkg
> rm C:\Users\skais\.nuget\packages\QSharpCommunity.Libraries.Qram\
```

1. Build the package for the Qram library:

```Powershell
> cd src
> dotnet pack
```

2. Copy the package to your local nuget source (a location you selected, an example one is below). The `X` in the name are the place holder for the version number you are building (should be generated by the previous step).

```Powershell
> cp .\bin\Debug\QSharpCommunity.Libraries.Qram.X.X.X.nupkg 'C:\Users\skais\nuget-packages\'
```

## Contribute

Please see our [contributing guidelines](CONTRIBUTING.md) and our [code of conduct](CODE_OF_CONDUCT.md) before working on a contribution, thanks!

## Credits
- Primary developers: @glassnotes, @crazy4pi314
- Code review and API design assistance: @RolfHuisman, @cgranade, @amirebrahimi

#### Anything else that seems useful

- [WIQCA talk](https://www.wiqca.dev/events/quantum101-qml_qram.html) on qRAM by @glassnotes
- [QSI seminar](https://www.youtube.com/watch?v=IicCWK2D7sg) by @glassnotes
- Live development of this library with @crazy4pi314 on [Twitch](https://twitch.tv/crazy4pi314)

## License

MIT © [qsharp-community](https://github.com/qsharp-community/qram/blob/master/LICENSE)
