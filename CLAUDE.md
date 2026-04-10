# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Interchange is a lightweight Swift package for building RESTful API clients using async/await and actors. It targets iOS 15.0+ and macOS 12.0+, uses Swift 6 strict concurrency, and has one test-only dependency: [Mocker](https://github.com/WeTransfer/Mocker).

## Commands

```bash
# Build
swift build

# Run all tests
swift test

# Run a single test
swift test --filter InterchangeTests/<TestMethodName>
```

No linting or formatting tools are configured.

## Architecture

The package follows a **protocol-based, actor-based design**:

### Core Types

- **`InterchangeManager`** (actor) — The main entry point. One instance per API base URL. Manages URLSession, rate limit state, and JSON decoding. All requests flow through `sendRequest<M>()` and `pageStream<M>()`.

- **`InterchangeManaging`** (protocol) — The public interface for `InterchangeManager`. Enables dependency injection. `MockInterchangeManager` is the test double.

- **`RESTEndpoint`** (struct, `Sendable`) — Declarative, immutable specification of a single request: method, path, headers, query params, body, pagination config, cache interval, and timeout. Also contains pagination helpers (`nextPageEndpoint()`, offset/page calculations).

- **`InterchangeError`** (enum, `Sendable`) — All error cases including HTTP errors (status code, URL, body) and decoding errors (with coding path context).

- **`Pageable`** (protocol) — Models that support pagination implement `totalCount`, `currentOffset`, and `submodels`. Required to call `pageStream()`.

- **`PageStreamActor`** (actor) — Drives `pageStream()` by iterating `RESTEndpoint.nextPageEndpoint()` until all pages are fetched or a `safetyLimit` is hit. Returns an `AsyncThrowingStream`.

### Request Lifecycle

`sendRequest()` on `InterchangeManager`:
1. Apply rate limiting (if `RESTRateLimitHeaders` was configured)
2. Build `URLRequest` from `RESTEndpoint` + base URL
3. Execute via `URLSession`
4. Validate HTTP status (200–203 success; others throw `InterchangeError.httpError`)
5. Update rate limit state from response headers
6. Decode response body to generic `M: Decodable & Sendable`

### Pagination

`RESTEndpoint` supports two pagination styles via query items:
- **Offset-based:** `offsetQueryItem` + `pageSizeQueryItem`
- **Page-based:** `pageQueryItem` + `pageSizeQueryItem`

`nextPageEndpoint()` calculates the updated query item for the next page. `pageStream()` orchestrates iteration via `PageStreamActor` and returns `AsyncThrowingStream<M, Error>`.

## Testing

Tests use XCTest with the Mocker library for HTTP mocking. The codebase is transitioning to Swift Testing (`@Test`, `#expect`) — prefer Swift Testing for new tests.

Test support files live in `Tests/InterchangeTests/Support/`:
- `TestEndpoints.swift` — pre-built endpoint definitions
- `TestModels.swift` — Codable test models
- `MockHelpers.swift`, `StringHelpers.swift`, `URLHelpers.swift` — utilities

## Documentation

Public APIs use DocC comments. The documentation catalog is at `Sources/Interchange/Interchange.docc/`, including `QuickStart.md` and `Interchange.md`.
