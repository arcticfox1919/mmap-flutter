import Flutter
import UIKit

// C function declarations
@_silgen_name("mio_get_version")
func mio_get_version() -> UnsafePointer<CChar>?

@_silgen_name("mio_mmap_create_from_path") 
func mio_mmap_create_from_path(_ path: UnsafePointer<CChar>, _ accessMode: UInt32, _ offset: Int, _ length: Int, _ error: UnsafeMutablePointer<UInt32>) -> OpaquePointer?

@_silgen_name("mio_mmap_create_from_handle")
func mio_mmap_create_from_handle(_ fileHandle: Int, _ accessMode: UInt32, _ offset: Int, _ length: Int, _ error: UnsafeMutablePointer<UInt32>) -> OpaquePointer?

@_silgen_name("mio_mmap_get_data")
func mio_mmap_get_data(_ handle: OpaquePointer) -> UnsafePointer<UInt8>?

@_silgen_name("mio_mmap_get_data_writable")
func mio_mmap_get_data_writable(_ handle: OpaquePointer) -> UnsafeMutablePointer<UInt8>?

@_silgen_name("mio_mmap_get_size")
func mio_mmap_get_size(_ handle: OpaquePointer) -> Int

@_silgen_name("mio_mmap_get_mapped_length")
func mio_mmap_get_mapped_length(_ handle: OpaquePointer) -> Int

@_silgen_name("mio_mmap_is_open")
func mio_mmap_is_open(_ handle: OpaquePointer) -> Int32

@_silgen_name("mio_mmap_is_mapped")
func mio_mmap_is_mapped(_ handle: OpaquePointer) -> Int32

@_silgen_name("mio_mmap_sync")
func mio_mmap_sync(_ handle: OpaquePointer) -> UInt32

@_silgen_name("mio_mmap_destroy")
func mio_mmap_destroy(_ handle: OpaquePointer)

@_silgen_name("mio_get_error_message")
func mio_get_error_message(_ error: UInt32) -> UnsafePointer<CChar>?

// Error codes and access modes constants
let MIO_SUCCESS: UInt32 = 0
let MIO_ERROR_INVALID_ARGUMENT: UInt32 = 1
let MIO_ERROR_FILE_NOT_FOUND: UInt32 = 2
let MIO_ERROR_PERMISSION_DENIED: UInt32 = 3
let MIO_ERROR_OUT_OF_MEMORY: UInt32 = 4
let MIO_ERROR_MAPPING_FAILED: UInt32 = 5
let MIO_ERROR_INVALID_HANDLE: UInt32 = 6
let MIO_ERROR_UNKNOWN: UInt32 = 7

let MIO_ACCESS_READ: UInt32 = 0
let MIO_ACCESS_WRITE: UInt32 = 1

public class Mmap2FlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mmap2_flutter", binaryMessenger: registrar.messenger())
    let instance = Mmap2FlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getVersion":
      result(getVersion())
    case "createFromPath":
      handleCreateFromPath(call, result: result)
    case "createFromHandle":
      handleCreateFromHandle(call, result: result)
    case "getData":
      handleGetData(call, result: result)
    case "getDataWritable":
      handleGetDataWritable(call, result: result)
    case "getSize":
      handleGetSize(call, result: result)
    case "getMappedLength":
      handleGetMappedLength(call, result: result)
    case "isOpen":
      handleIsOpen(call, result: result)
    case "isMapped":
      handleIsMapped(call, result: result)
    case "sync":
      handleSync(call, result: result)
    case "destroy":
      handleDestroy(call, result: result)
    case "getErrorMessage":
      handleGetErrorMessage(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - Version Methods
  
  private func getVersion() -> String {
    guard let versionPtr = mio_get_version() else {
      return "Unknown"
    }
    return String(cString: versionPtr)
  }
  
  // MARK: - Memory Map Creation Methods
  
  private func handleCreateFromPath(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let path = args["path"] as? String,
          let accessModeInt = args["accessMode"] as? Int,
          let offset = args["offset"] as? Int,
          let length = args["length"] as? Int else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for createFromPath", details: nil))
      return
    }
    
    let accessMode = accessModeInt == 0 ? MIO_ACCESS_READ : MIO_ACCESS_WRITE
    var error: UInt32 = MIO_SUCCESS
    
    let handle = path.withCString { pathPtr in
      mio_mmap_create_from_path(pathPtr, accessMode, offset, length, &error)
    }
    
    if error != MIO_SUCCESS {
      let errorMessage = getErrorMessage(for: error)
      result(FlutterError(code: "MMAP_ERROR", message: errorMessage, details: ["errorCode": error]))
      return
    }
    
    guard let validHandle = handle else {
      result(FlutterError(code: "NULL_HANDLE", message: "Failed to create memory map", details: nil))
      return
    }
    
    // Store handle pointer as Int64 for Flutter
    let handleId = Int64(Int(bitPattern: validHandle))
    result(["handleId": handleId])
  }
  
  private func handleCreateFromHandle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let fileHandle = args["fileHandle"] as? Int,
          let accessModeInt = args["accessMode"] as? Int,
          let offset = args["offset"] as? Int,
          let length = args["length"] as? Int else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for createFromHandle", details: nil))
      return
    }
    
    let accessMode = accessModeInt == 0 ? MIO_ACCESS_READ : MIO_ACCESS_WRITE
    var error: UInt32 = MIO_SUCCESS
    
    let handle = mio_mmap_create_from_handle(fileHandle, accessMode, offset, length, &error)
    
    if error != MIO_SUCCESS {
      let errorMessage = getErrorMessage(for: error)
      result(FlutterError(code: "MMAP_ERROR", message: errorMessage, details: ["errorCode": error]))
      return
    }
    
    guard let validHandle = handle else {
      result(FlutterError(code: "NULL_HANDLE", message: "Failed to create memory map", details: nil))
      return
    }
    
    let handleId = Int64(Int(bitPattern: validHandle))
    result(["handleId": handleId])
  }
  
  // MARK: - Data Access Methods
  
  private func handleGetData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let handleId = getHandleFromCall(call) else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid handle", details: nil))
      return
    }
    
    guard let dataPtr = mio_mmap_get_data(handleId) else {
      result(FlutterError(code: "NULL_POINTER", message: "Failed to get data pointer", details: nil))
      return
    }
    
    let size = mio_mmap_get_size(handleId)
    let data = Data(bytes: dataPtr, count: size)
    result(FlutterStandardTypedData(bytes: data))
  }
  
  private func handleGetDataWritable(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let handleId = getHandleFromCall(call) else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid handle", details: nil))
      return
    }
    
    guard let dataPtr = mio_mmap_get_data_writable(handleId) else {
      result(FlutterError(code: "NULL_POINTER", message: "Failed to get writable data pointer", details: nil))
      return
    }
    
    let size = mio_mmap_get_size(handleId)
    let data = Data(bytes: dataPtr, count: size)
    result(FlutterStandardTypedData(bytes: data))
  }
  
  // MARK: - Information Methods
  
  private func handleGetSize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let handleId = getHandleFromCall(call) else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid handle", details: nil))
      return
    }
    
    let size = mio_mmap_get_size(handleId)
    result(Int64(size))
  }
  
  private func handleGetMappedLength(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let handleId = getHandleFromCall(call) else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid handle", details: nil))
      return
    }
    
    let length = mio_mmap_get_mapped_length(handleId)
    result(Int64(length))
  }
  
  private func handleIsOpen(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let handleId = getHandleFromCall(call) else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid handle", details: nil))
      return
    }
    
    let isOpen = mio_mmap_is_open(handleId)
    result(isOpen != 0)
  }
  
  private func handleIsMapped(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let handleId = getHandleFromCall(call) else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid handle", details: nil))
      return
    }
    
    let isMapped = mio_mmap_is_mapped(handleId)
    result(isMapped != 0)
  }
  
  // MARK: - Operation Methods
  
  private func handleSync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let handleId = getHandleFromCall(call) else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid handle", details: nil))
      return
    }
    
    let error = mio_mmap_sync(handleId)
    if error != MIO_SUCCESS {
      let errorMessage = getErrorMessage(for: error)
      result(FlutterError(code: "SYNC_ERROR", message: errorMessage, details: ["errorCode": error]))
      return
    }
    
    result(nil)
  }
  
  private func handleDestroy(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let handleId = getHandleFromCall(call) else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid handle", details: nil))
      return
    }
    
    mio_mmap_destroy(handleId)
    result(nil)
  }
  
  private func handleGetErrorMessage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let errorCodeInt = args["errorCode"] as? Int else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid error code", details: nil))
      return
    }
    
    let errorCode = UInt32(errorCodeInt)
    let message = getErrorMessage(for: errorCode)
    result(message)
  }
  
  // MARK: - Helper Methods
  
  private func getHandleFromCall(_ call: FlutterMethodCall) -> OpaquePointer? {
    guard let args = call.arguments as? [String: Any],
          let handleIdInt = args["handleId"] as? Int64 else {
      return nil
    }
    
    return OpaquePointer(bitPattern: Int(handleIdInt))
  }
  
  private func getErrorMessage(for error: UInt32) -> String {
    guard let messagePtr = mio_get_error_message(error) else {
      return "Unknown error"
    }
    return String(cString: messagePtr)
  }
}
