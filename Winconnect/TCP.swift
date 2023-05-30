import Foundation

let PORT: UInt32 = 1278

class TCPClient {
    let serverIP: String
    var inputStream: InputStream?
    var outputStream: OutputStream?

    init(serverIP: String) {
        self.serverIP = serverIP
    }

    func run() -> Bool {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocketToHost(nil, serverIP as CFString, PORT, &readStream, &writeStream)

        inputStream = readStream?.takeRetainedValue()
        outputStream = writeStream?.takeRetainedValue()

        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.global().async {
            self.inputStream?.open()
            self.outputStream?.open()

            print("Connecting to the receiver...")

            semaphore.signal()
        }

        let timeoutInSeconds: TimeInterval = 5
        let timeoutResult = semaphore.wait(timeout: .now() + timeoutInSeconds)

        if timeoutResult == .timedOut {
            print("Connection timeout")
            return false
        }

        print("Connected to the receiver")
        return true
    }

    func sendCommand(_ command: String) {
        DispatchQueue.global().async {
            guard let outputStream = self.outputStream else {
                print("Output stream is not available")
                return
            }

            let data = command.data(using: .utf8)!
            let bytesSent = data.withUnsafeBytes { outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count) }

            if bytesSent == -1 {
                print("Send failed")
            } else if bytesSent == 0 {
                print("Connection closed by the server")
            }
        }
    }
    
    func receivePCData() -> (cpuUsage: Int, ramUsage: Int) {
        var cpuUsage = 0
        var ramUsage = 0
        
        DispatchQueue.global().async {
            guard let inputStream = self.inputStream else {
                print("Input stream is not available")
                return
            }
            
            var buffer = [UInt8](repeating: 0, count: 1024)
            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
            
            if bytesRead <= 0 {
                print("Failed to receive data")
                return
            }
            
            let receivedData = Data(bytes: buffer, count: bytesRead)
            
            guard let receivedString = String(data: receivedData, encoding: .utf8) else {
                print("Failed to decode received data")
                return
            }
            
            let usageComponents = receivedString.components(separatedBy: "|")
            
            // Extract CPU usage
            let cpuUsageString = usageComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)
            cpuUsage = Int(cpuUsageString) ?? 0
            
            // Extract RAM usage
            let ramUsageString = usageComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
            ramUsage = Int(ramUsageString) ?? 0
        }
        
        return (cpuUsage, ramUsage)
    }

    func closeConnection() {
        inputStream?.close()
        outputStream?.close()
    }
}

func sendToServer(message: String) {
    let client = TCPClient(serverIP: "10.0.0.89") // Replace with your server IP address
    client.sendCommand(message)
}
