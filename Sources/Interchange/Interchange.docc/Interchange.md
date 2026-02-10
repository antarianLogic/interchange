# ``Interchange``

A lightweight Swift package for interacting concurrently with RESTful web APIs using declarative endpoint specifications and returning decoded Codable types, with support for pagination, rate limiting, and more

## Overview

A ``InterchangeManager`` uses [URLSession](https://developer.apple.com/documentation/foundation/urlsession) to make [Swift Concurrent](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency) requests to [RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer) web APIs.

A ``RESTEndpoint`` struct is used to define the specifications of specific endpoints.
The individual `RESTEndpoint` structs would ideally be preconfigured with static convenience initializers defined elsewhere such as in a separate package (see <doc:Interchange#Ideal-Production-Usage>).

The results are decoded asynchronously from the JSON response and returned.
The specific [Decodable](https://developer.apple.com/documentation/swift/decodable) type to be output is specified by the caller as the concrete return type in ``InterchangeManager/sendRequest(with:)`` or ``InterchangeManager/pageStream(with:safetyLimit:)``.

## Quick Start Guide

To jump right in, see the <doc:QuickStart>.

## Initialization

The client initializes one ``InterchangeManager`` per web service with a base URL using ``InterchangeManager/init(baseURL:session:rateLimitHeaders:)``.

### Example

```swift
import Interchange

let url = URL(string: "https://example.com")!
let manager = InterchangeManager(baseURL: url)
```

Also the `URLSession` can optionally be injected (see <doc:Interchange#URLSession-Injection>) and rate-limiting headers can be specified (see <doc:Interchange#Rate-Limiting-Support>).

## Basic Requests

For single-page requests, use ``InterchangeManager/sendRequest(with:)``, passing a endpoint specification of type ``RESTEndpoint`` and specifying the `Decodable` type to return.

### Example

```swift
let endpoint = RESTEndpoint(method: .get,
                            path: "/cats/1")
struct CatModel: Codable, Sendable {
    let name: String
    let age: Int
}
do {
    let cat: CatModel = try await manager.sendRequest(with: endpoint)
    print("cat name: \(cat.name)")
} catch {
    print("Error: \(error)")
}
```

## Ideal Production Usage

The usage intent with `Interchange` is to hide the implementation details of endpoint specifications and output types from the calling site.
So for a clean calling implementation in your app, it is recommended to put the details of the specific endpoint specifications elsewhere in support code or even in a separate package from the main app.
For example, a Swift enum could be created with various static methods, each returning a prepared `RESTEndpoint` from it's inputs.
And all the `Codable` models could be defined in separate code as well, perhaps in the same package as the endpoints.
Then all you would have to do at the calling site (where you actually make the network call) is make the request as above with one of the static endpoint methods, possibly taking any inputs that you pass to that static method.

To go a step further, one could create a worker object that is initialized with the base URL and any other constants it needs such as client keys or whatever.
This worker object would hold on to the `InterchangeManager`, ideally injected as a `InterchangeManaging` conforming type such as `MockInterchangeManager` so it can be mocked during testing.
The worker would have async methods for all the endpoints it needs, each one returning an object of the expected concrete `Codable` type for that endpoint.
The worker code could also be put in the same package as the endpoints and the models, since these are all related to the specific Web API in question.

For an example of an entire package following these patterns with [endpoints](https://github.com/antarianLogic/spotify-web-api-interchange-kit/blob/main/Sources/SpotifyWebAPIInterchangeKit/API/SpotifyWebAPIRoutes.swift), [models](https://github.com/antarianLogic/spotify-web-api-interchange-kit/tree/main/Sources/SpotifyWebAPIInterchangeKit/API/Models), a [worker](https://github.com/antarianLogic/spotify-web-api-interchange-kit/blob/main/Sources/SpotifyWebAPIInterchangeKit/SpotifyWebAPIWorker.swift), and also including data presets and tests, see [SpotifyWebAPIInterchangeKit](https://github.com/antarianLogic/spotify-web-api-interchange-kit).

## Features

### Multipage Requests

For endpoints that return multipage responses, ``InterchangeManager/pageStream(with:safetyLimit:)`` can be used to immediately return an [AsyncThrowingStream](https://developer.apple.com/documentation/swift/asyncthrowingstream) that can be iterated asynchronously to retrieve each page.
An optional safety limit count can be passed to insure the iterator won't be infinite or if only a limited number of pages are desired.
The `Decodable` type must also conform to ``Pageable``.

### Offset vs. Page Number

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

`InterchangeManager` uses the [shared](https://developer.apple.com/documentation/foundation/urlsession/shared) `URLSession` by default but clients can optionally inject their own `URLSession` instead during initialization.
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

* All errors thrown originating from this package will be of type ``InterchangeError``. All `InterchangeError` cases have a `debugDescription` which is suitable for logging.
* Errors thrown by `JSONDecoder` during output decoding will be wrapped in a ``InterchangeError/decodingError(_:_:_:_:)`` with the request URL, reason string, and JSON coding path where the decoding failed also in the associated data.
* Errors thrown by the underlying [URLSession](https://developer.apple.com/documentation/foundation/urlsession/data(for:)) call will simply be rethrown.
* If the parent task is cancelled during any asyncrounous operations, a [CancellationError](https://developer.apple.com/documentation/swift/cancellationerror) will be thrown.

### Testing

#### Mocking

``InterchangeManager`` conforms to ``InterchangeManaging`` and thus can be injected and mocked.
A ``MockInterchangeManager`` already exists for your convenience.

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
