//
//  main.swift
//  DetoxRecorderCLI
//
//  Created by Leo Natan (Wix) on 5/27/20.
//  Copyright © 2020 Wix. All rights reserved.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

class DetoxRecorderCLI
{
	static let detoxPackageJson : [String: Any] = {
		let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("package.json")
		do {
			let data = try Data(contentsOf: url)
			let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
			
			guard let dict = jsonObj as? [String: Any] else {
				throw "Unknown package.json file format."
			}
			
			guard let detox = dict["detox"] as? [String: Any] else {
				throw "Unable to find “detox” object in package.json."
			}
			
			return detox
		} catch {
			LNUsagePrintMessageAndExit(prependMessage: error.localizedDescription, logLevel: .error)
		}
	}()
}

func whichURLFor(binaryName: String) throws -> URL {
	let whichProcess = Process()
	whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
	whichProcess.arguments = [binaryName]
	
	let out = Pipe()
//	let err = Pipe()
	whichProcess.standardOutput = out
//	whichProcess.standardError = err
	
	whichProcess.launch()
	whichProcess.waitUntilExit()
	
//	let errFileHandle = err.fileHandleForReading
	let readFileHandle = out.fileHandleForReading
	
//	let error = String(data: errFileHandle.readDataToEndOfFile(), encoding: .utf8)!.trimmingCharacters(in: .newlines)
	let response = String(data: readFileHandle.readDataToEndOfFile(), encoding: .utf8)!.trimmingCharacters(in: .newlines)
	
	if response.count == 0 {
		throw "\(binaryName) not found"
	}
	
	return URL(fileURLWithPath: response)
}

func prepareappBundleId(bundleId: String?, appPath: String?, config: String?) -> String {
	if let bundleId = bundleId {
		return bundleId
	} else if let _ /*appPath*/ = appPath {
		//TODO: Install path, get bundle identifier and return it
	} else {
		//TODO: Extract from config, install and use
	}
	
	return ""
}

func prepareSimulatorId(simulatorId: String?, config: String?) -> String {
	if let simulatorId = simulatorId {
		return simulatorId
	}
	
	//TODO: Extract from config
	return ""
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
	LNUsagePrintMessageAndExit(prependMessage: nil, logLevel: .stdOut, exitCode: 0)
}

let bundleId = parser.object(forKey: "bundleId") as? String
let appPath = parser.object(forKey: "appPath") as? String
let simId = parser.object(forKey: "simulatorId") as? String

let config = parser.object(forKey: "configuration") as? String

guard ((bundleId != nil || appPath != nil) && simId != nil) || config != nil else {
	if bundleId == nil && appPath == nil && config == nil {
		LNUsagePrintMessageAndExit(prependMessage: "You must either provide an app bundle identifier, an app bundle path or a Detox configuration.", logLevel: .error)
	}
	
	if simId == nil && appPath == nil {
		LNUsagePrintMessageAndExit(prependMessage: "You must either provide a simulator identifier or a Detox configuration.", logLevel: .error)
	}
	
	LNUsagePrintMessageAndExit(prependMessage: "Bloop‽", logLevel: .error)
}

guard let outputTestFile = parser.object(forKey: "outputTestFile") as? String else {
	LNUsagePrintMessageAndExit(prependMessage: "You must provide an output test file path.", logLevel: .error)
}

let appBundleId = prepareappBundleId(bundleId: bundleId, appPath: appPath, config: config)
let simulatorId = prepareSimulatorId(simulatorId: simId, config: config)

var args = ["simctl", "launch", simulatorId, appBundleId, "-DTXRecStartRecording", "1", "-DTXRecTestOutputPath", outputTestFile]

if let testName = parser.object(forKey: "testName") as? String {
	args.append(contentsOf: ["-DTXRecTestName", testName])
}

if parser.bool(forKey: "noExit") {
	args.append(contentsOf: ["-DTXRecNoExit", "1"])
}

do {
	let terminateProcess = Process()
	terminateProcess.executableURL = try whichURLFor(binaryName: "xcrun")
	terminateProcess.arguments = ["simctl", "launch", simulatorId, appBundleId]
	
	terminateProcess.launch()
	terminateProcess.waitUntilExit()
	
	let recordProcess = Process()
	recordProcess.executableURL = try whichURLFor(binaryName: "xcrun")
	recordProcess.arguments = args
	if parser.bool(forKey: "noInsertLibraries") {
		recordProcess.environment = [:]
	} else {
		recordProcess.environment = ["SIMCTL_CHILD_DYLD_INSERT_LIBRARIES": Bundle.main.executableURL!.deletingLastPathComponent().appendingPathComponent("DetoxRecorder.framework/DetoxRecorder").standardized.path]
	}
	recordProcess.launch()
	recordProcess.waitUntilExit()
} catch {
	LNUsagePrintMessageAndExit(prependMessage: "Xcode not installed.", logLevel: .error)
}
