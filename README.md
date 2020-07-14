# qRAM Library for Q\#

[![Unitary Fund](https://img.shields.io/badge/Supported%20By-UNITARY%20FUND-brightgreen.svg?style=flat)](http://unitary.fund)

This library implements a variety of different proposals for memory for quantum computers, also commonly called qRAM.
Want to learn more about what qRAM is?
Check out the [primer on memory for quantum computers](https://github.com/qsharp-community/qram/suites/870816048/artifacts/10122400) in our docs!

## Motivation

There are many different proposals for qRAM in quantum computing that each have different tradeoffs, and currently come up a lot in quantum machine learning applications.
We want to better understand the costs and benefits of different qRAM implementations in quantum machine learning as well as quantum computing more generally.
This library will help achieve these goals by giving us a concrete way to measure the resources each approach takes; choosing to do this in Q# allows us to leverage the built-in resource estimator to quickly iterate profiling the qRAM implementations and optimizing the circuits.

## Build status

[![Run Tests](https://github.com/qsharp-community/qram/workflows/Run%20Tests/badge.svg)](https://github.com/qsharp-community/qram/actions?query=workflow%3A%22Run+Tests%22)
[![Build and publish NuGet package to GitHub packages](https://github.com/qsharp-community/qram/workflows/Build%20and%20publish%20NuGet%20package%20to%20GitHub%20packages/badge.svg)](https://github.com/qsharp-community/qram/actions?query=workflow%3A%22Build+and+publish+NuGet+package+to+GitHub+packages%22)

## Code style

[![q# code style](https://img.shields.io/badge/code%20style-Q%23-blue)](https://docs.microsoft.com/en-us/quantum/contributing/style-guide?tabs=guidance)
[![q# APIcode style](https://img.shields.io/badge/code%20style-Q%23%20API-ff69b4)](https://docs.microsoft.com/en-us/quantum/contributing/style-guide?tabs=guidance)
[![c# APIcode style](https://img.shields.io/badge/code%20style-C%23-lightgrey)](https://docs.microsoft.com/dotnet/csharp/programming-guide/inside-a-program/coding-conventions)
[![CoC](https://img.shields.io/badge/code%20of%20conduct-contributor%20covenant-yellow)](CODE_OF_CONDUCT.md)

## Screenshots

**Example of a Bucket Brigade qRAM circuit:**

![Bucket Brigade qRAM](docs/images/bb.gif)

TODO: Include logo/demo screenshot etc.

## Tech/framework used

**Built with:**

- [Quantum Development Kit](https://docs.microsoft.com/quantum/)
- [.NET Core SDK 3.1](https://dotnet.microsoft.com/download/dotnet-core/3.1)
- [Python](https://www.python.org/downloads/)
- [Visual Studio Code](https://code.visualstudio.com/) and [Visual Studio](https://visualstudio.microsoft.com/)
- [Jupyter Notebook](https://jupyter.org/)

## Features

What makes your project stand out?

## Code Example

TODO: Add more! Fix syntax highlighting

```qsharp
operation QueryAndMeasureQRAM(memory : QRAM, queryAddress : Int) : Int {
        using ((addressRegister, targetRegister) = (Qubit[memory::AddressSize], Qubit[memory::DataSize])) {
            ApplyPauliFromBitString (PauliX, true, IntAsBoolArray(queryAddress, memory::AddressSize), addressRegister);
            memory::Lookup(LittleEndian(addressRegister), targetRegister);
            ResetAll(addressRegister);
            return MeasureInteger(LittleEndian(targetRegister));
        }
    }
```
<!--Show what the library does as concisely as possible, developers should be able to figure out **how** your project solves their problem by looking at the code example. Make sure the API you are showing off is obvious, and that your code is short and concise.-->

## Installation

TODO:
- [ ] Docker
- [ ] Binder
- [ ] Codespaces
- [x] Remote development environment with VS Code
  - Dev container is in `.devcontainer`, see instructions for VSCode on how to launch.
- [ ] local install

## API Reference

TODO: Complete once compiler extension is finalized for scraping API docs
<!--Depending on the size of the project, if it is small and simple enough the reference docs can be added to the README. For medium size to larger projects it is important to at least provide a link to where the API reference docs live.-->

## Tests
TODO: Describe and show how to run the tests with code examples.

## How to use?
TODO: Link to user manual in docs
<!--If people like your project they’ll want to learn how they can use it. To do so include step by step guide to use your project.-->

## Contribute

Please see our [contributing guidelines](CONTRIBUTING.md) and our [code of conduct](CODE_OF_CONDUCT.md) before working on a contribution, thanks!

## Credits
- Primary developers: @glassnotes, @shikharsingh3, @crazy4pi314
- Code review and API design assistance: @RolfHuisman, @cgranade

#### Anything else that seems useful

- [WIQCA talk](https://www.wiqca.dev/events/quantum101-qml_qram.html) on qRAM by @glassnotes
- Live development of this library with @crazy4pi314 on [Twitch](https://twitch.tv/crazy4pi314)

## License

MIT © [qsharp-community](https://github.com/qsharp-community/qram/blob/master/LICENSE)
