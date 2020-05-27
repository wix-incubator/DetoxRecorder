//
//  main.swift
//  DetoxRecorderCLI
//
//  Created by Leo Natan (Wix) on 5/27/20.
//  Copyright © 2020 Wix. All rights reserved.
//

import Foundation

class DetoxRecorderCLI
{
	static let packageJson : [String: Any] = {
		let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("package.json")
		do {
			let data = try Data(contentsOf: url)
			let rv = try JSONSerialization.jsonObject(with: data, options: [])
			return rv as! [String: Any]
		} catch {
			LNUsagePrintMessage(prependMessage: error.localizedDescription, logLevel: .error)
			exit(-1)
		}
	}()
}

LNUsageSetUtilName("detox recorder")

LNUsageSetIntroStrings([
	"Records UI interaction steps into a Detox test.",
	"",
	"After recording the test, add assertions that check if interface elements are in the expected state.",
	"",
	"If no app or simulator information is provided, the package.json will be used for obtaining the appropriate information."])

LNUsageSetExampleStrings([
	"detox recorder --bundleId \"com.example.myApp\" --simulatorId \"69D91B05-64F4-497B-A2FC-9A109B310F38\" --outputTestFile \"/Users/myname/Desktop/RecordedTest.js\" --testName \"My Recorded Test\" --record",
	"detox recorder --outputTestFile \"/Users/myname/Desktop/RecordedTest.js\" --record",
])

LNUsageSetOptions([
	LNUsageOption(name: "record", shortcut: "r", valueRequirement: .none, description: "Start recording"),
	LNUsageOption(name: "outputTestFile", shortcut: "o", valueRequirement: .required, description: "The output file (required)"),
	LNUsageOption(name: "testName", shortcut: "n", valueRequirement: .required, description: "The test name (optional)"),
	LNUsageOption.empty(),
	LNUsageOption(name: "configuration", shortcut: "c", valueRequirement: .required, description: "The Detox configuration to use (optional, required if either app or simulator information is not provided"),
	LNUsageOption.empty(),
	LNUsageOption(name: "bundleId", shortcut: "b", valueRequirement: .required, description: "The app bundle identifier of an existing app to record (optional)"),
	LNUsageOption(name: "appPath", shortcut: "app", valueRequirement: .required, description: "The path of an app bundle to install before recording (optional)"),
	LNUsageOption.empty(),
	LNUsageOption(name: "simulatorId", shortcut: "s", valueRequirement: .required, description: "The simulator identifier to use for recording (optional)"),
	LNUsageOption.empty(),
])

LNUsageSetHiddenOptions([
	LNUsageOption(name: "noExit", shortcut: "no", valueRequirement: .none, description: "Do not exit the app after completing the test recording"),
	LNUsageOption(name: "noInsertLibraries", shortcut: "no2", valueRequirement: .none, description: "Do not use DYLD_INSERT_LIBRARIES for injecting the Detox Recorder framework; the app is responsible for loading the framework"),
])

let parser = LNUsageParseArguments()

guard parser.object(forKey: "record") != nil else {
	LNUsagePrintMessage(prependMessage: nil, logLevel: .stdOut)
	exit(0)
}

let json = DetoxRecorderCLI.packageJson
