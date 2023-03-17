# ``RESTWebService``

A Swift Concurrent REST web service framework using declarative endpoint specifications and returning decoded generic types.

## Overview

A ``RESTWebServiceManager`` uses [URLSession](https://developer.apple.com/documentation/foundation/urlsession) to make [Swift Concurrent](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency) requests to [RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer) web services. A ``RESTEndpoint`` struct (which ideally would be preconfigured with static convenience initializers defined in separate code or a package) is used to define the specifications of specific REST endpoints. The results are decoded asynchronously (according to the generic [Decodable](https://developer.apple.com/documentation/swift/decodable) type specified by the caller) from the JSON response and returned.

### Initialization

The client initializes one ``RESTWebServiceManager`` per web service with a base URL using ``RESTWebServiceManager/init(baseURL:session:rateLimitHeaders:)``. For example:

```swift
let url = URL(string: "https://example.com")!
let wsManager = RESTWebServiceManager(baseURL: url)
```

Also the `URLSession` can optionally be injected (see <doc:RESTWebService#URLSession-Injection>) and rate-limiting headers can be specified (see <doc:RESTWebService#Rate-Limiting>).

### One-shot Requests

For single-page requests, use ``RESTWebServiceManager/sendRequest(with:)``, passing a endpoint specification of type ``RESTEndpoint`` and specifying the `Decodable` type to return. For example:

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

For endpoints that return multipage responses, ``RESTWebServiceManager/pageStream(with:safetyLimit:)`` can be used to immediately return an [AsyncThrowingStream](https://developer.apple.com/documentation/swift/asyncthrowingstream) that can be iterated asynchronously to retrieve each page. An optional safety limit count can be passed to insure the iterator won't be infinite or if only a limited number of pages are desired. The `Decodable` type must also conform to ``Pageable``. For example:

```swift
let endpoint = FooEndpoints.getFoos()
let stream: AsyncThrowingStream<SomeDecodable,Error> = wsManager.pageStream(with: endpoint, safetyLimit: 1000)
var pageIterator = stream.makeAsyncIterator()
do {
    let page1 = try await pageIterator.next()
    // page1 now contains a fully decoded model object containing the first page of data
    let page2 = try await pageIterator.next()
    // page2 now contains a fully decoded model object containing the second page of data
    // etc...
    // until pageX is nil meaning no more pages
} catch {
    print("error: \(String(reflecting:error))")
}
```

### URLSession Injection

`RESTWebServiceManager` uses the shared `URLSession` by default but clients can optionally inject their own `URLSession` instead during initialization. See ``RESTWebServiceManager/init(baseURL:session:rateLimitHeaders:)``.

### Rate Limiting

If the endpoint supports rate-limiting statistics in the response headers, a rate limiting back-off delay scheme can optionally be enabled by passing the header keys in a ``RESTRateLimitHeaders`` struct during initialization. See ``RESTWebServiceManager/init(baseURL:session:rateLimitHeaders:)``.

The delay (`waitInterval`) before performing the next web service request is calculated using a reciprocal power function of the total requests allowed per second (`rateLimit`) and the remaining requests allowed currently (`rateLimitRemaining`), represented by the following pseudocode:

```
waitInterval = previousRequestTime + rateLimit / (1.5 ^ rateLimitRemaining) - currentTime
if waitInterval > 0, wait waitInterval
```

So as you can see, for nominal values of `rateLimit` (~60/sec) when `rateLimitRemaining` is as little as half of `rateLimit`, the delay is still pretty small (less than a millisecond). But as `rateLimitRemaining` approaches zero, the delay approaches `rateLimit`, backing off in a hopefully graceful manner so the UI responsiveness won't just go from 100% to 0% when it hits the wall and no more web service requests can be made for a while.

### Errors

All errors thrown are of type ``RESTWebServiceError`` enum. Some of the error enum cases contain the lower-level error in associated data. All cases have a `debugDescription` which is suitable for logging.

### Mocking

``RESTWebServiceManager`` conforms to ``RESTWebServiceManaging`` and thus can be injected and mocked. In fact there already is a ``MockRESTWebServiceManager`` for your convenience.

## Topics

### Initializers

- ``RESTWebServiceManager/init(baseURL:session:rateLimitHeaders:)``
