//
//  StikEnableJIT.swift
//  MeloNX + Titan Bridge
//
//  Created by Stossy11 on 10/02/2025.
//  Titan Modification by Gemini
//

import Foundation
import Network
import UIKit

func stikJITorStikDebug() -> Int {
    let teamid = SecTaskCopyTeamIdentifier(SecTaskCreateFromSelf(nil)!, nil)
    
    if checkifappinstalled("com.stik.sj") {
        return 1 // StikDebug
    }
    
    if checkifappinstalled("com.stik.sj.\(String(teamid ?? ""))") {
        return 2 // StikJIT
    }
    
    return 0 // Not Found
}

func checkforOld() -> Bool {
    return true
}

func checkifappinstalled(_ id: String) -> Bool {
    guard let handle = dlopen("/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices", RTLD_LAZY) else {
        return false
    }
    
    typealias SBSLaunchApplicationWithIdentifierFunc = @convention(c) (CFString, Bool) -> Int32
    guard let sym = dlsym(handle, "SBSLaunchApplicationWithIdentifier") else {
        dlclose(handle)
        return false
    }
    
    let bundleID: CFString = id as CFString
    let suspended: Bool = false
    
    let SBSLaunchApplicationWithIdentifier = unsafeBitCast(sym, to: SBSLaunchApplicationWithIdentifierFunc.self)
    let result = SBSLaunchApplicationWithIdentifier(bundleID, suspended)

    return result == 9
} 

// --- TITAN ENGINE BOOT SEQUENCE ---
func launchTitanIfPresent() {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let enginePath = documentsURL.appendingPathComponent("Engine/bin/wine").path
    
    if fileManager.fileExists(atPath: enginePath) {
        print("🚀 TITAN: Engine found. Taking over JIT thread...")
        
        // Detach thread to keep the UI from freezing while Wine boots
        Thread.detachNewThread {
            let pid = fork()
            if pid == 0 {
                // Optimize for A18 Pro
                setenv("FEX_APP_NAME", "Titan_GTA_V", 1)
                setenv("DYLD_LIBRARY_PATH", documentsURL.appendingPathComponent("Engine/lib").path, 1)
                
                // Point to the Wine binary inside your Engine folder
                execv(enginePath, nil)
                exit(0)
            }
        }
    } else {
        print("ℹ️ MeloNX: No Titan Engine found. Proceeding with normal emulator mode.")
    }
}

func enableJITStik() {
    let bundle = Bundle.main.bundleIdentifier
    var urlScheme: String = "stikjit://enable-jit?bundle-id=" + (bundle ?? "com.stossy11.MeloNX")
    
    if #available(iOS 19.0, *) {
        let scriptdata = script.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        urlScheme += "&script-data=\(scriptdata)"
    }
    
    if let launchURL = URL(string: urlScheme) {
        UIApplication.shared.open(launchURL, options: [:]) { success in
            if success {
                // 1-second delay to ensure the JIT "door" is fully open
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    launchTitanIfPresent()
                }
            }
        }
    }
}

// Keep the original MeloNX JIT script block for the A18 Pro exploit
let script = """
Y29uc3QgQ01EX0RFVEFDSCA9IDA7CmNvbnN0IENNRF9QUkVQQVJFX1JFR0lPTiA9IDE7CmNvbnN0IENNRF9ORVdfQlJFQUtQT0lOVFMgPSAyOwpjb21tYW5kcyA9IHsKICAgIFtDTURfREVUQUNIXTogSklUMjZEZXRhY2gsCiAgICBbQ01EX1BSRVBBUkVfUmVHSU9OXTogSklUMjZQcmVwYXJlUmVnaW9uLAogICAgW0NNRF9ORVdfQlJFQUtQT0lOVFNdOiBKSVQyNk5ld0JyZWFrcG9pbnRzCn07CmNvbnN0IGxlZ2FjeUNvbW1hbmRzID0gewogICAgWzB4NjhdOiBKSVQyNk5ld0JyZWFrcG9pbnRzLAogICAgWzB4NjldOiBKSVQyNkhhbmRsZUJyazB4NjksCiAgICBbMHhmMDBkXTogSklUMjZIYW5kbGVCcmsweGYwMGQKfTsKCmxldCB0aWQsIHgwLCB4MSwgeDE2LCBwYzsKCmxldCBkZXRhY2hlZCA9IGZhbHNlOwpsZXQgcGlkID0gZ2V0X3BpZCgpOwpsb2coYHBpZCA9ICR7cGlkfWApOwpsZXQgYXR0YWNoUmVzcG9uc2UgPSBzZW5kX2NvbW1hbmQoYHZBdHRhY2g7JHtwaWQudG9TdHJpbmcoMTYpfWApOwpsb2coYGF0dGFjaF9yZXNwb25zZSA9ICR7YXR0YWNoUmVzcG9uc2V9YCk7CiAgICAKbGV0IHRvdGFsQnJlYWtwb2ludHMgPSAwOwp3aGlsZSAoIWRldGFjaGVkKSB7CiAgICB0b3RhbEJyZWFrcG9pbnRzKys7CiAgICBsb2coYEhhbmRsaW5nIGJyZWFrcG9pbnQgJHt0b3RhbEJyZWFrcG9pbnRzfWApOwogICAgCiAgICBsZXQgYnJrUmVzcG9uc2UgPSBzZW5kX2NvbW1hbmQoYGNoYSk7CiAgICBsb2coYGJyay1yZXNwb25zZSA9ICR7YnJrUmVzcG9uc2V9YCk7Cn0K
"""
