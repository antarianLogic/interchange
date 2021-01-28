//
//  URLProtocolStub.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

class URLProtocolStub: URLProtocol {

    // this dictionary maps URLs to test data
    static var testURLs = [URL: Data]()

    // say we want to handle all types of request
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    // ignore this method; just send back what we were given
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // if we have a valid URL…
        if let url = request.url {
            // …and if we have test data for that URL…
            if let data = Self.testURLs[url] {
                // …load it immediately.
                self.client?.urlProtocol(self, didLoad: data)
            } else {
                guard let httpResponse = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: nil) else { return }
                self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            }
        }

        // mark that we've finished
        self.client?.urlProtocolDidFinishLoading(self)
    }

    // this method is required but doesn't need to do anything
    override func stopLoading() {}
}
