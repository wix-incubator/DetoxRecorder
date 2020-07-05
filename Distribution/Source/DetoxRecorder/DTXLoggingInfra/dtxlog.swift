//
//  dtxlog.swift
//  dtxlog
//
//  Created by Leo Natan (Wix) on 5/3/20.
//  Copyright © 2020 Leo Natan. All rights reserved.
//

import Foundation

let log = DetoxLog(category: "FromSwift")

@_cdecl("swift_test_logs")
func swift_test_logs() {
	log.debug("Hello")
	log.error("There")
}
