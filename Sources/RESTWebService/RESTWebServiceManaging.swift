//
//  RESTWebServiceManaging.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

public protocol RESTWebServiceManaging {
    
    func get<Model>(resource: RESTResource<Model>,
                    completionHandler: @escaping (Result<Model, RESTWebServiceError>) -> Void) -> URLRequest?
}
