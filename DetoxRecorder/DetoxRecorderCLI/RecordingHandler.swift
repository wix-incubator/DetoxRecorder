//
//  RecordingHandler.swift
//  DetoxRecorderCLI
//
//  Created by Leo Natan (Wix) on 7/19/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

import Foundation
import DTXSocketConnection

class RecordingHandler: NSObject, NetServiceDelegate, DTXSocketConnectionDelegate {
	fileprivate var socketConnection: DTXSocketConnection! = nil
	let serviceName = UUID().uuidString
	fileprivate	let netService: NetService
	
	let currentFileUrl: URL
	let currentFile: FileHandle
	var currentFileOffset: UInt64 = 0
	var previousFileOffset: UInt64 = 0
	let fileOutro: Data
	
	fileprivate var awaitingCompletionHandler: ((RecordingHandler) -> Void)?
	
	init(recordingUrl: URL, testName: String, completionHandler: @escaping (RecordingHandler) -> Void) {
		awaitingCompletionHandler = completionHandler
		netService = NetService(domain: "local", type: "_detoxrecorder._tcp", name: serviceName, port: 0)
		
		do {
			let directoryUrl: URL
			if recordingUrl.hasDirectoryPath {
				directoryUrl = recordingUrl
				currentFileUrl = recordingUrl.appendingPathComponent("recorder_test.js", isDirectory: false)
			} else {
				directoryUrl = recordingUrl.deletingLastPathComponent()
				currentFileUrl = recordingUrl
			}
			
			try FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: true, attributes: nil)
			
			try "".write(to: currentFileUrl, atomically: true, encoding: .utf8)
			currentFile = try FileHandle(forWritingTo: currentFileUrl)
			let intro = "describe('Recorded suite', () => {\n\tit('\(testName)', async () => {\n".data(using: .utf8)!
			fileOutro = "\t})\n});".data(using: .utf8)!
			
			try currentFile.write(contentsOf: intro)
			try currentFile.write(contentsOf: fileOutro)
			
			try currentFile.seek(toOffset: UInt64(intro.count))
			previousFileOffset = UInt64(intro.count)
			currentFileOffset = UInt64(intro.count)
		} catch {
			LNUsagePrintMessageAndExit(prependMessage: "Unable to open output test file for writing: \(error.localizedDescription)", logLevel: .error)
		}
		
		super.init()
		
		netService.delegate = self
		netService.schedule(in: .current, forMode: .default)
		netService.publish(options: .listenForConnections)
	}
	
	fileprivate func truncateFile() throws {
		try currentFile.truncate(atOffset: currentFileOffset)
	}
	
	
	fileprivate func writeActionToFile(_ action: String) throws {
		try truncateFile()
		
		let data = "\t\t\(action)\n".data(using: .utf8)!
		try currentFile.write(contentsOf: data)
		
		previousFileOffset = currentFileOffset
		currentFileOffset += UInt64(data.count)
	}
	
	fileprivate func writeOutroToFile() throws {
		try currentFile.truncate(atOffset: currentFileOffset)
		try currentFile.write(contentsOf: fileOutro)
	}
	
	fileprivate func addAction(_ action: String) throws {
		log.info("Adding recorded action: \(action)")
		try writeActionToFile(action)
		try writeOutroToFile()
	}
	
	fileprivate func updateAction(_ action: String?) throws {
		try currentFile.seek(toOffset: previousFileOffset)
		currentFileOffset = previousFileOffset
		
		if let action = action {
			log.info("Updating last recorded action to: \(action)")
			try writeActionToFile(action)
		} else {
			log.info("Removing last recorded action")
			try truncateFile()
		}
		
		try writeOutroToFile()
	}
	
	func printFinishAndExit(_ leadingNewLine: Bool = false) -> Never {
		LNUsagePrintMessageAndExit(prependMessage: "\(leadingNewLine ? "\n" : "")Finished recording to \(currentFileUrl.path)", logLevel: .stdOut)
	}
	
	fileprivate func startReceiving() {
		socketConnection.receive { [weak self] data, error in
			guard let self = self else {
				return
			}
			
			guard let data = data else {
				LNUsagePrintMessageAndExit(prependMessage: "Error reading recording command: \(error!.localizedDescription)", logLevel: .error)
			}
			
			let command = try! PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: AnyObject]
			let actionType = command["type"] as! String
			
			do {
				switch(actionType) {
				case "add":
					let detoxCommand = command["command"] as! String
					try self.addAction(detoxCommand)
					break
				case "update":
					let detoxCommand = command["command"] as! String
					try self.updateAction(detoxCommand)
					break
				case "remove":
					try self.updateAction(nil)
					break
				case "end":
					self.printFinishAndExit()
					break
				case "ping":
					//Ignore
					break
				default:
					throw "Got unknown command type: \(actionType)"
				}
			} catch {
				LNUsagePrintMessageAndExit(prependMessage: "Error writing command to output test file: \(error.localizedDescription)", logLevel: .error)
			}
			
			self.startReceiving()
		}
	}
	
	// MARK: DTXSocketConnectionDelegate
	
	func readClosed(for socketConnection: DTXSocketConnection) {
		log.info("Socket connection closed for reading.")
		
		printFinishAndExit()
	}
	
	func writeClosed(for socketConnection: DTXSocketConnection) {
		log.info("Socket connection closed for writing.")
		
		printFinishAndExit()
	}
	
	// MARK: NSNetServiceDelegate
	
	func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
		socketConnection = DTXSocketConnection(inputStream: inputStream, outputStream: outputStream, delegateQueue: nil)
		socketConnection.delegate = self
		socketConnection.open()
		startReceiving()
	}
	
	func netServiceDidPublish(_ sender: NetService) {
		log.info("Published recording service: \(sender)")
		awaitingCompletionHandler?(self)
		awaitingCompletionHandler = nil
	}
	
	func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
		LNUsagePrintMessageAndExit(prependMessage: "Failed stating a recording service.", logLevel: .error)
	}
}
