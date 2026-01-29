# ``Interchange``

A lightweight Swift package for interacting concurrently with RESTful web APIs using declarative endpoint specifications and returning decoded Codable types, with support for pagination, rate limiting, and more

## Overview

A ``InterchangeManager`` uses [URLSession](https://developer.apple.com/documentation/foundation/urlsession) to make [Swift Concurrent](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency) requests to [RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer) web APIs.

A ``RESTEndpoint`` struct is used to define the specifications of specific endpoints.
The individual `RESTEndpoint` structs would ideally be preconfigured with static convenience initializers defined elsewhere such as in a separate package.

The results are decoded asynchronously from the JSON response and returned.
The specific [Decodable](https://developer.apple.com/documentation/swift/decodable) type to be output is specified by the caller as the concrete return type in ``InterchangeManager/sendRequest(with:)`` or ``InterchangeManager/pageStream(with:safetyLimit:)``.

#### Quick Start Guide

To jump right in, see the <doc:QuickStart>.

### Initialization

The client initializes one ``InterchangeManager`` per web service with a base URL using ``InterchangeManager/init(baseURL:session:rateLimitHeaders:)``.

#### Example

```swift
let url = URL(string: "https://example.com")!
let wsManager = InterchangeManager(baseURL: url)
```

Also the `URLSession` can optionally be injected (see <doc:Interchange#URLSession-Injection>) and rate-limiting headers can be specified (see <doc:Interchange#Rate-Limiting-Support>).

### One-shot Requests

For single-page requests, use ``InterchangeManager/sendRequest(with:)``, passing a endpoint specification of type ``RESTEndpoint`` and specifying the `Decodable` type to return.

#### Example

```swift
let endpoint = FooEndpoints.getFoo(input: "123")
do {
    let foo: SomeDecodable = try await wsManager.sendRequest(with: endpoint)
    // foo now contains a fully decoded model object
} catch {
    print("error: \(String(reflecting:error))")
}
```

### Multipage Requests

For endpoints that return multipage responses, ``InterchangeManager/pageStream(with:safetyLimit:)`` can be used to immediately return an [AsyncThrowingStream](https://developer.apple.com/documentation/swift/asyncthrowingstream) that can be iterated asynchronously to retrieve each page.
An optional safety limit count can be passed to insure the iterator won't be infinite or if only a limited number of pages are desired.
The `Decodable` type must also conform to ``Pageable``.

#### Offset vs. Page Number

Interchange supports both offset-based and page-number-based pagination:

**Offset-based** (common in modern APIs):
```swift
offsetQueryItem: URLQueryItem(name: "offset", value: "0")
// Produces: ?offset=0, ?offset=50, ?offset=100, ...
```

**Page-number-based** (common in older APIs):
```swift
pageQueryItem: URLQueryItem(name: "page", value: "1")
// Produces: ?page=1, ?page=2, ?page=3, ...
```

Use ``RESTEndpoint/offsetQueryItem`` or ``RESTEndpoint/pageQueryItem``.
If both exist, `offsetQueryItem` will be used and `pageQueryItem` will be ignored.

#### Example

```swift
struct ItemsResponse: Codable, Pageable, Sendable {
    let total: UInt
    let offset: UInt
    let items: [Item]
    
    var totalCount: UInt { total }
    var currentOffset: UInt { offset }
    var submodels: [Item] { items }
}

let endpoint = RESTEndpoint(
    method: .get,
    path: "/items",
    pageSizeQueryItem: URLQueryItem(name: "limit", value: "100"),
    offsetQueryItem: URLQueryItem(name: "offset", value: "0")
)

do {
    for try await page in manager.pageStream(with: endpoint, safetyLimit: 1000) as AsyncThrowingStream<ItemsResponse, Error> {
        print("Received \(page.items.count) items")
        // Process items...
    }
} catch {
    print("error: \(String(reflecting:error))")
}
```

### URLSession Injection

`InterchangeManager` uses the shared `URLSession` by default but clients can optionally inject their own `URLSession` instead during initialization.
See ``InterchangeManager/init(baseURL:session:rateLimitHeaders:)``.

### Rate Limiting Support

Many web APIs enforce rate limits to prevent abuse.
If the endpoint supports rate-limiting statistics in the response headers, Interchange can automatically respect these limits by reading the rate limit headers and throttling the requests.

#### Configuration

Enable and configure rate limiting by providing the header names your API uses:

```swift
let rlHeaders = RESTRateLimitHeaders(rateLimitKey: "X-RateLimit-Limit",
                                     rateLimitRemainingKey: "X-RateLimit-Remaining")
let manager = InterchangeManager(baseURL: url,
                                    rateLimitHeaders: rlHeaders)
```

#### How It Works

When enabled, a rate limiting back-off delay scheme will be in effect.
The delay (`waitInterval`) before performing the next web service request is calculated using a function of the total requests allowed per second (`rateLimit`) and the remaining requests allowed currently (`rateLimitRemaining`), represented by the following pseudocode:

```
waitInterval = previousRequestTime + rateLimit / (1.5 ^ rateLimitRemaining) - currentTime
if waitInterval > 0, wait waitInterval
```

So as you can see, for nominal values of `rateLimit` (~60/sec) when `rateLimitRemaining` is as little as half of `rateLimit`, the delay is still pretty small (less than a millisecond).
But as `rateLimitRemaining` approaches zero, the delay approaches `rateLimit`, backing off in a hopefully graceful manner so the UI responsiveness won't just go from 100% to 0% when it hits the wall and no more web service requests can be made for a while.
This should help minimize the times the calls fail outright due to rate limit violations.
But as a tradeoff, keep in mind it might lead to some noticeable delay when `rateLimitRemaining` gets really low.
A delay is usually a better user experience than a failure though.

See ``InterchangeManager/init(baseURL:session:rateLimitHeaders:)``.

### Error Handling

All errors thrown are of type ``InterchangeError`` enum.
Some of the error enum cases contain the lower-level error in associated data.
All cases have a `debugDescription` which is suitable for logging.

### Testing

#### Mocking

``InterchangeManager`` conforms to ``InterchangeManaging`` and thus can be injected and mocked.
In fact there already is a ``MockInterchangeManager`` for your convenience.

#### External Testing

```swift
@Test func testDataLoading() async throws {
    // Create a mock service manager for testing
    let mockManager = MockInterchangeManager()
    let item = Item(id: 1, name: "Test")
    await mockManager.pushMockData(item)
    ...
    // Test model decoding
    let result: Item = try await mockManager.sendRequest(with: endpoint)
    #expect(result.name == "Test")
}
```

#### Internal Testing

See `InterchangeManagerTests` under the `Tests/InterchangeTests` group in Xcode for many examples.
The Mock framework is used in the tests to bypass the internet but they still use a real InterchangeManager.
Create a preset in MockHelpers.swift and add it to registerAll().

## Topics

### Initializers

- ``InterchangeManager/init(baseURL:session:rateLimitHeaders:)``

### Making Requests

- ``InterchangeManager/sendRequest(with:)``
- ``InterchangeManager/pageStream(with:safetyLimit:)``
