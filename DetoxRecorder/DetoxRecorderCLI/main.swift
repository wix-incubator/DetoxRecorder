//
//  main.swift
//  DetoxRecorderCLI
//
//  Created by Leo Natan (Wix) on 5/27/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

import Foundation
import DTXSocketConnection

let log = DetoxLog(subsystem: "DetoxRecorder", category: "CLI")

LNUsageSetUtilName("detox recorder")

LNUsageSetIntroStrings([
	"Records UI interaction steps into a Detox test.",
	"",
	"After recording the test, add assertions that check if interface elements are in the expected state.",
	"",
	"If no app or simulator information is provided, the Detox configuration will be used for obtaining the appropriate information."])

LNUsageSetExampleStrings([
	"detox recorder --bundleId \"com.example.myApp\" --simulatorId booted --outputTestFile \"~/Desktop/RecordedTest.js\" --testName \"My Recorded Test\" --record",
	"detox recorder --bundleId \"com.example.myApp\" --simulatorId \"69D91B05-64F4-497B-A2FC-9A109B310F38\" --outputTestFile \"~/Desktop/RecordedTest.js\" --testName \"My Recorded Test\" --record",
	"detox recorder --configuration \"ios.sim.release\" --outputTestFile \"~/Desktop/RecordedTest.js\" --testName \"My Recorded Test\" --record"
])

LNUsageSetOptions([
	LNUsageOption(name: "record", shortcut: "r", valueRequirement: .none, description: "Start recording"),
	LNUsageOption(name: "outputTestFile", shortcut: "o", valueRequirement: .required, description: "The output file (required)"),
	LNUsageOption(name: "testName", shortcut: "n", valueRequirement: .required, description: "The test name (optional)"),
	LNUsageOption.empty(),
	LNUsageOption(name: "configuration", shortcut: "c", valueRequirement: .required, description: "The Detox configuration to use (optional, required if either app or simulator information is not provided"),
	LNUsageOption.empty(),
	LNUsageOption(name: "bundleId", shortcut: "b", valueRequirement: .required, description: "The app bundle identifier of an existing app to record (optional)"),
	LNUsageOption.empty(),
	LNUsageOption(name: "simulatorId", shortcut: "s", valueRequirement: .required, description: "The simulator identifier to use for recording or \"booted\" to use the currently booted simulator (optional)"),
	LNUsageOption(name: "version", shortcut: "v", valueRequirement: .none, description: "Prints version")
])

var hiddenOptions = [
	LNUsageOption(name: "noExit", shortcut: "no", valueRequirement: .none, description: "Do not exit the app after completing the test recording"),
	LNUsageOption(name: "noInsertLibraries", shortcut: "no2", valueRequirement: .none, description: "Do not use DYLD_INSERT_LIBRARIES for injecting the Detox Recorder framework; the app is responsible for loading the framework"),
	LNUsageOption(name: "recorderFrameworkPath", shortcut: "fpath", valueRequirement: .required, description: "The Detox Recorder path to use, rather than the default"),
]

#if DEBUG
hiddenOptions.append(LNUsageOption(name: "generateArtwork", valueRequirement: .none, description: "Generates artwork for documentation"))
#endif

LNUsageSetHiddenOptions(hiddenOptions)

extension String: LocalizedError {
    public var errorDescription: String? { return self }
	
	func capitalizingFirstLetter() -> String {
		return prefix(1).capitalized + dropFirst()
	}
	
	mutating func capitalizeFirstLetter() {
		self = self.capitalizingFirstLetter()
	}
}

extension Process {
	var simctlArguments: [String]? {
		get {
			return Array(arguments![1..<arguments!.count])
		}
		set(simctlArguments) {
			var arguments = ["simctl"]
			if let simctlArguments = simctlArguments {
				arguments.append(contentsOf: simctlArguments)
			}
			
			self.arguments = arguments
		}
	}
	
	@discardableResult
	func launchAndWaitUntilExitAndReturnOutput() throws -> String {
		let out = Pipe()
		let err = Pipe()
		standardOutput = out
		standardError = err
		
		log.info("Launching \(executableURL!.path) with arguments: \(arguments ?? []) environment: \(environment ?? [:])")
		
		var outData = Data()
		out.fileHandleForReading.readabilityHandler = { fileHandle in
			outData.append(fileHandle.availableData)
		}
		
		var errData = Data()
		err.fileHandleForReading.readabilityHandler = { fileHandle in
			errData.append(fileHandle.availableData)
		}
		
		let semaphore = DispatchSemaphore(value: 0)
		
		terminationHandler = { process in
			out.fileHandleForReading.readabilityHandler = nil
			err.fileHandleForReading.readabilityHandler = nil
			
			semaphore.signal()
		}
		
		launch()
		
		semaphore.wait()
		
		let response = String(data: outData, encoding: .utf8)!.trimmingCharacters(in: .newlines)
		let error = String(data: errData, encoding: .utf8)!.trimmingCharacters(in: .newlines)
		
		if(terminationStatus != 0) {
			throw error
		}
		
		return response
	}
}

class DetoxRecorderCLI
{
/*
	.detoxrc.js
	.detoxrc.json
	.detoxrc
	detox.config.js
	detox.config.json
	*/
	static let detoxPackageJson : [String: Any] = {
		let detoxConfigFiles = [".detoxrc.js", ".detoxrc.json", ".detoxrc", "detox.config.js", "detox.config.json"]
		
		log.info("Attempting to discover Detox config file")
		
		for configFileName in detoxConfigFiles {
			let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(configFileName)
			
			do {
				let data = try Data(contentsOf: url)
				
				do {
					let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
					
					guard let dict = jsonObj as? [String: Any] else {
						throw "Unknown file format"
					}
					
					log.info("Using “\(configFileName)” config file")
					
					return dict
				}
				catch {
					LNUsagePrintMessageAndExit(prependMessage: "Unable to read \(url.path): \(error.localizedDescription) The config file must be in JSON format.", logLevel: .error)
				}
			}
			catch {
				continue
			}
		}
		
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
			
			log.info("Using package.json as config file")
			
			return detox
		} catch {
			LNUsagePrintMessageAndExit(prependMessage: error.localizedDescription, logLevel: .error)
		}
	}()
	
	static func detoxConfig(_ configName: String) -> [String: Any] {
		guard let configs = DetoxRecorderCLI.detoxPackageJson["configurations"] as? [String: Any] else {
			LNUsagePrintMessageAndExit(prependMessage: "Key “configurations” is not found or unreadable in package.json.", logLevel: .error)
		}
		
		guard let config = configs[configName] as? [String: Any] else {
			LNUsagePrintMessageAndExit(prependMessage: "Configuration “\(configName)” is not found or unreadable in package.json.", logLevel: .error)
		}
		
		return config
	}
}

var whichCache: [String: URL] = [:]
func whichURLFor(binaryName: String) throws -> URL {
	if let url = whichCache[binaryName] {
		return url
	}
	
	let shellPath = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
	
	let whichProcess = Process()
	whichProcess.executableURL = URL(fileURLWithPath: shellPath)
	whichProcess.arguments = ["-l", "-c", "which \(binaryName)"]
	
	let response_ = (try? whichProcess.launchAndWaitUntilExitAndReturnOutput()) ?? ""
	//Only take the last line of response, to ignore any frivolous output the shell might do beforehand.
	let response = String(response_.split(whereSeparator: \.isNewline).last!)
	if response.count == 0 {
		throw "\(binaryName) not found"
	}
	
	let url = URL(fileURLWithPath: response)
	whichCache[binaryName] = url
	return url
}

func xcrunSimctlProcess() -> Process {
	let xcrunSimctlProcess = Process()
	xcrunSimctlProcess.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
	do {
		xcrunSimctlProcess.executableURL = try whichURLFor(binaryName: "xcrun")
	} catch {
		LNUsagePrintMessageAndExit(prependMessage: "Xcode not installed.", logLevel: .error)
	}
	xcrunSimctlProcess.arguments = ["simctl"]
	return xcrunSimctlProcess
}

func applesimutilsProcess() -> Process {
	let applesimutilsProcess = Process()
	do {
		applesimutilsProcess.executableURL =  try whichURLFor(binaryName: "applesimutils")
	} catch {
		LNUsagePrintMessageAndExit(prependMessage: "applesimutils is not installed.", logLevel: .error)
	}
	return applesimutilsProcess
}

func nmProcess() -> Process {
	let nmProcess = Process()
	nmProcess.executableURL = URL(fileURLWithPath: "/usr/bin/nm")
	return nmProcess
}

func otoolProcess() -> Process {
	let otoolProcess = Process()
	otoolProcess.executableURL = URL(fileURLWithPath: "/usr/bin/otool")
	return otoolProcess
}

func prepareappBundleId(bundleId: String?, config: String?, simulatorId: String) -> String {
	if let bundleId = bundleId {
		return bundleId
	} else {
		guard let appPath = DetoxRecorderCLI.detoxConfig(config!)["binaryPath"] as? String else {
			LNUsagePrintMessageAndExit(prependMessage: "Key “binaryPath” either not found or in unsupported format as found in package.json for the “\(config!)” configuration.", logLevel: .error)
		}
		
		guard FileManager.default.fileExists(atPath: appPath) else {
			LNUsagePrintMessageAndExit(prependMessage: "Key “binaryPath” points to a path that does not exist.", logLevel: .error)
		}
		
		let simctlInstall = xcrunSimctlProcess()
		simctlInstall.simctlArguments = ["install", simulatorId, appPath]
		do {
			_ = try simctlInstall.launchAndWaitUntilExitAndReturnOutput()
		} catch {
			LNUsagePrintMessageAndExit(prependMessage: "Failed installing app: \(error.localizedDescription).", logLevel: .error)
		}
		
		guard let bundle = Bundle(path: appPath), let foundBundleId = bundle.bundleIdentifier else {
			LNUsagePrintMessageAndExit(prependMessage: "Unable to read the app's Info.plist.", logLevel: .error)
		}
		
		return foundBundleId
	}
}

func ensureSimulatorBooted(_ simulatorId: String) -> String {
	let process = applesimutilsProcess()
	if simulatorId.lowercased() != "booted" {
		process.arguments = ["--list", "--byId", simulatorId]
	} else {
		process.arguments = ["--list", "--booted"]
	}
	let jsonString = try? process.launchAndWaitUntilExitAndReturnOutput()
	let object : [[String: Any]]
	do {
		guard let jsonString = jsonString, let data = jsonString.data(using: .utf8) else {
			throw "err"
		}
		
		object = try JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
	} catch {
		LNUsagePrintMessageAndExit(prependMessage: "applesimutils failed obtaining information about the simulator.", logLevel: .error)
	}
	
	guard let device = object.first else {
		if simulatorId.lowercased() != "booted" {
			LNUsagePrintMessageAndExit(prependMessage: "No simulator found with identifier “\(simulatorId)”.", logLevel: .error)
		} else {
			LNUsagePrintMessageAndExit(prependMessage: "No booted simulator found.", logLevel: .error)
		}
	}
		
	if device["state"]! as! String != "Booted" {
		let bootProcess = xcrunSimctlProcess()
		bootProcess.simctlArguments = ["boot", simulatorId]
		
		do {
			try bootProcess.launchAndWaitUntilExitAndReturnOutput()
		} catch {
			LNUsagePrintMessageAndExit(prependMessage: "Failed launching device with identifier “\(simulatorId)”: \(error.localizedDescription).", logLevel: .error)
		}
	}
	
	return device["udid"] as! String
}

func prepareSimulatorId(simulatorId: String?, config: String?) -> String {
	if let simulatorId = simulatorId {
		return ensureSimulatorBooted(simulatorId)
	}
	
	guard let deviceJson = DetoxRecorderCLI.detoxConfig(config!)["device"] as? [String: String] else {
		LNUsagePrintMessageAndExit(prependMessage: "Key “device” either not found or in unsupported format as found in package.json for the “\(config!)” configuration.", logLevel: .error)
	}
	
	var arguments: [String] = ["--list"]
	deviceJson.forEach { key, value in
		arguments.append("--by\(key.lowercased() == "os" ? "OS" : key.capitalizingFirstLetter())")
		arguments.append(value)
	}
	
	let process = applesimutilsProcess()
	process.arguments = arguments
	let listResponseJson = (try? process.launchAndWaitUntilExitAndReturnOutput()) ?? ""
	guard let listResponse = try? JSONSerialization.jsonObject(with: listResponseJson.data(using: .utf8)!, options: []) as? [[String: Any]], listResponse.count != 0 else {
		LNUsagePrintMessageAndExit(prependMessage: "Unable to find simulator as described in package.json for the “\(config!)” configuration.", logLevel: .error)
	}
	
	guard listResponse.count == 1 else {
		LNUsagePrintMessageAndExit(prependMessage: "Multiple simulators matched to description in package.json for the “\(config!)” configuration; ensure a more specific query.", logLevel: .error)
	}
	
	guard let simulator = listResponse.first, let foundSimId = simulator["udid"] as? String else {
		LNUsagePrintMessageAndExit(prependMessage: "Unabled to parse simulator data returned from applesimutils.", logLevel: .error)
	}
	
	return ensureSimulatorBooted(foundSimId)
}

func executableContainsMagicSymbol(_ url: URL) -> Bool {
	let process = nmProcess()
	process.arguments = ["-U", url.standardized.path]

	let anotherProcess = otoolProcess()
	anotherProcess.arguments = ["-L", url.standardized.path]

	do {
		let symbols = try process.launchAndWaitUntilExitAndReturnOutput()
		let linkedFrameworks = try anotherProcess.launchAndWaitUntilExitAndReturnOutput()

		return symbols.contains("DTXUIInteractionRecorder") || linkedFrameworks.contains("DetoxRecorder")
	} catch {
		return false
	}
}

log.info("Parsing arguments")
let parser = LNUsageParseArguments()

guard parser.bool(forKey: "version") == false else {
	LNUsagePrintMessageAndExit(prependMessage: "detox-recorder version \(__version)", logLevel: .stdOut)
}

guard parser.object(forKey: "record") != nil else {
	LNUsagePrintMessageAndExit(prependMessage: "No command specified.", logLevel: .error)
}

let bundleId = parser.object(forKey: "bundleId") as? String
let simId = parser.object(forKey: "simulatorId") as? String

let config = parser.object(forKey: "configuration") as? String

guard (bundleId != nil && simId != nil) || config != nil else {
	if bundleId == nil && config == nil {
		LNUsagePrintMessageAndExit(prependMessage: "You must either provide an app bundle identifier or a Detox configuration.", logLevel: .error)
	}
	
	if simId == nil && config == nil {
		LNUsagePrintMessageAndExit(prependMessage: "You must either provide a simulator identifier or a Detox configuration.", logLevel: .error)
	}
	
	LNUsagePrintMessageAndExit(prependMessage: "Bloop‽", logLevel: .error)
}

guard let outputTestFile = parser.object(forKey: "outputTestFile") as? String else {
	LNUsagePrintMessageAndExit(prependMessage: "You must provide an output test file path.", logLevel: .error)
}

let simulatorId = prepareSimulatorId(simulatorId: simId, config: config)
let appBundleId = prepareappBundleId(bundleId: bundleId, config: config, simulatorId: simulatorId)

let shouldInsertProcess = xcrunSimctlProcess()
let shouldInsert: Bool
shouldInsertProcess.simctlArguments = ["get_app_container", simulatorId, appBundleId]
do {
	let appInstalledPath = try shouldInsertProcess.launchAndWaitUntilExitAndReturnOutput()
	guard let appBundle = Bundle(path: appInstalledPath), let executableURL = appBundle.executableURL else {
		throw "err"
	}
	
	shouldInsert = executableContainsMagicSymbol(executableURL) == false
	
	log.info("App binary requires framework injection: \(String(describing: shouldInsert))")
} catch {
	shouldInsert = true
}

let testName = parser.object(forKey: "testName") as? String ?? "My Recorded Test"
var args = ["launch", simulatorId, appBundleId, "-DTXRecStartRecording", "1", "-DTXRecTestName", testName]

if parser.bool(forKey: "noExit") {
	args.append(contentsOf: ["-DTXRecNoExit", "1"])
}

#if DEBUG
if parser.bool(forKey: "generateArtwork") {
	args.append(contentsOf: ["-DTXGenerateArtwork", "1"])
}
#endif

let terminateProcess = xcrunSimctlProcess()
terminateProcess.simctlArguments = ["terminate", simulatorId, appBundleId]

_ = try? terminateProcess.launchAndWaitUntilExitAndReturnOutput()

let recordingHandler = RecordingHandler(recordingUrl: URL(fileURLWithPath: (outputTestFile as NSString).expandingTildeInPath), testName: testName) { recordingHandler in
	args.append(contentsOf: ["-DTXServiceName", recordingHandler.serviceName])
	
	let recordProcess = xcrunSimctlProcess()
	recordProcess.simctlArguments = args
	if shouldInsert == false || parser.bool(forKey: "noInsertLibraries") == true {
		recordProcess.environment = [:]
	} else {
		let frameworkUrl : URL
		if let frameworkOverridePath = parser.object(forKey: "recorderFrameworkPath") as? String {
			frameworkUrl = URL(fileURLWithPath: frameworkOverridePath, isDirectory: true)
		} else {
			frameworkUrl = Bundle.main.executableURL!.deletingLastPathComponent().appendingPathComponent("DetoxRecorder.framework/")
		}
		recordProcess.environment = ["SIMCTL_CHILD_DYLD_INSERT_LIBRARIES": frameworkUrl.appendingPathComponent("DetoxRecorder").standardized.path]
	}
	
	do {
		try recordProcess.launchAndWaitUntilExitAndReturnOutput()
	} catch {
		LNUsagePrintMessageAndExit(prependMessage: "Failed starting recording: \(error.localizedDescription).", logLevel: .error)
	}
	
	LNUsagePrintMessage(prependMessage: "Recording… (CTRL+C to stop)", logLevel: .stdOut)
}

signal(SIGINT) { _ in
	signal(SIGINT, nil)
	recordingHandler.printFinishAndExit(true)
}

RunLoop.current.run(until: .distantFuture)
