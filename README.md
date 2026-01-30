# Interchange

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20visionOS-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)

## A lightweight Swift package for interacting concurrently with RESTful web APIs using declarative endpoint specifications and returning decoded Codable types, with support for pagination, rate limiting, and more

---

## Features

- 🪶 **Lightweight**: Relativly simple implementation with no main target dependencies
- 🚸 **Swift Concurrency**: Uses `async`/`await` and actors for thread-safe operations
- 📋 **Declarative**: The configuration specific to each call is passed as declaratively as value types
- 🦺 **Type-Safe**: Leverages Swift's `Codable` for automatic JSON parsing
- 📑 **Pagination Support**: Stream multi-page responses with `AsyncThrowingStream`
- 🚦 **Automatic Rate Limiting**: Respects API rate limits based on response headers
- 💾 **Caching**: Built-in URLCache support with configurable intervals
- 🧪 **Testable**: Protocol-based design for easy mocking

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 6.0+
- Xcode 14.0+

## Quick Start

To jump right in, see the [Quick Start Guide](Sources/Interchange/Interchange.docc/QuickStart.md).

## Full Documentation

The full documentation is here: [Interchange](Sources/Interchange/Interchange.docc/Interchange.md).

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Carl Sheppard** - [Antarian Logic LLC](https://github.com/antarianLogic)

## Acknowledgments

- Uses [Mocker](https://github.com/WeTransfer/Mocker) for testing

## Support

- 📫 Report issues on [GitHub Issues](https://github.com/antarianLogic/interchange/issues)
- 💬 Ask questions in [GitHub Discussions](https://github.com/antarianLogic/interchange/discussions)
- ⭐ Star the repo if you find it useful!
