# Quick Start Guide

Get up and running quickly with Interchange

## Installation

Do ONE of the following, depending on whether you are adding this package as a dependency to an app-level Xcode project or another Swift Package.

### App-level Projects

Add this package through Xcode. For more information see [Adding Package Dependencies](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

### Swift Packages

Add this dependency line to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/antarianLogic/interchange", from: "1.0.0")
]
```

## Basic Usage (GET Requests)

```swift
import Interchange

// 1. Create manager
guard let url = URL(string: "https://jsonplaceholder.typicode.com") else { return }
let manager = InterchangeManager(baseURL: url)

// 2. Define output model
struct Post: Codable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

// 3. Create GET endpoint
let endpoint = RESTEndpoint(method: .get,
                            path: "/posts/1")

// 4. Make request
do {
    let post: Post = try await manager.sendRequest(with: endpoint)
    print("Post title: \(post.title)")
} catch {
    print("Error: \(error)")
}
```

## Common Patterns

### Query Parameters

```swift
let endpoint = RESTEndpoint(
    method: .get,
    path: "/posts",
    queryParameters: [
        URLQueryItem(name: "userId", value: "1")
    ]
)
// Results in: https://jsonplaceholder.typicode.com/posts?userId=1
```

### User Agent

```swift
// YOUR_USER_AGENT is usually a constant value expected by the API provider  
let endpoint = RESTEndpoint(method: .get,
                            path: "/posts",
                            headers: ["User-Agent": "YOUR_USER_AGENT"])
```

### Authentication

```swift
// YOUR_TOKEN would have been obtained earlier, possibly using another endpoint and request
let endpoint = RESTEndpoint(method: .get,
                            path: "/posts",
                            headers: ["Authorization": "Bearer YOUR_TOKEN"])
```

### POST/PUT/PATCH Requests

```swift
import Interchange

// 1. Create manager
guard let url = URL(string: "https://jsonplaceholder.typicode.com") else { return }
let manager = InterchangeManager(baseURL: url)

// 2. Define body model and encode data
struct Body: Codable, Sendable {
    let userId: Int
    let title: String
    let body: String
}
let body = Body(userId: 1,
                title: "foo",
                body: "bar")
let encoder = JSONEncoder()
// Sorting makes result deterministic which accommodates testing.
// Body doesn't need slashes escaped.
encoder.outputFormatting = [.sortedKeys,
                            .withoutEscapingSlashes]
guard let bodyJSONData = try? encoder.encode(body),
      let bodyJSON = String(data: bodyJSONData, encoding: .utf8) else { return }

// 3. Define output model
struct Post: Codable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

// 4. Create endpoint
let endpoint = RESTEndpoint(method: .post, // or use .put for PUT requests, .patch for PATCH
                            path: "/posts",
                            headers: ["Content-Type" : "application/json; charset=utf-8"],
                            body: bodyJSON)

// 4. Make request
do {
    let returnedObj: Post = try await manager.sendRequest(with: endpoint)
    print("title: \(returnedObj.title)")
} catch {
    print("Error: \(error)")
}
```

### Pagination

```swift
// 1. Make response model conform to Pageable
struct ItemsResponse: Codable, Pageable, Sendable {
    let total: UInt
    let offset: UInt
    let items: [Item]
    
    var totalCount: UInt { total }
    var currentOffset: UInt { offset }
    var submodels: [Item] { items }
}

// 2. Create endpoint with pagination
let endpoint = RESTEndpoint(
    method: .get,
    path: "/items",
    pageSizeQueryItem: URLQueryItem(name: "limit", value: "100"),
    offsetQueryItem: URLQueryItem(name: "offset", value: "0")
)

// 3. Iterate through all pages
for try await page in manager.pageStream(with: endpoint) as AsyncThrowingStream<ItemsResponse, Error> {
    print("Received \(page.items.count) items")
    // Process items...
}
```

See see <doc:Interchange#Multipage-Requests> in the main documentation for more.

### Rate Limiting Support

```swift
// Use whatever rate limit keys which are defined by the particular service
let rlHeaders = RESTRateLimitHeaders(rateLimitKey: "X-RateLimit-Limit",
                                     rateLimitRemainingKey: "X-RateLimit-Remaining")
let manager = InterchangeManager(baseURL: url,
                                    rateLimitHeaders: rlHeaders)
// Requests will automatically throttle as you approach limits
```

See see <doc:Interchange#Rate-Limiting-Support> in the main documentation for more.

### Caching

```swift
// Return cached result if same call was made less than 300 seconds (5 minutes) ago
let endpoint = RESTEndpoint(method: .get,
                            path: "/posts",
                            cacheInterval: 300)
```

## Error Handling

```swift
do {
    let data: MyModel = try await manager.sendRequest(with: endpoint)
    // Use data...
} catch let error as InterchangeError {
    switch error {
    case .httpError(let code, let message, _):
        print("HTTP \(code): \(message)")
    case .decodingError(_, _, let reason, _):
        print("JSON decode failed: \(reason)")
    default:
        print("Request failed: \(error)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

See see <doc:Interchange#Error-Handling> in the main documentation for more.

## Next Steps

- 📚 [Full Documentation](<doc:Interchange>)
- 🐛 [Report Issues](https://github.com/antarianLogic/interchange/issues)
- 💬 [Ask Questions](https://github.com/antarianLogic/interchange/discussions)
