//
//  Models.swift
//  new project
//
//  Created by apple on 11/05/2026.
//

import Foundation
struct Edition: Decodable {
    let identifier: String
    let language: String
    let name: String
    let englishName: String
    let format: String
    let type: String
    let direction: String
}

struct EditionsResponse: Decodable {
    let code: Int
    let status: String
    let data: [Edition]
}
