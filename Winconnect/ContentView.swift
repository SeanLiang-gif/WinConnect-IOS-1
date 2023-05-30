import SwiftUI
import Dispatch
import UIKit
import Foundation

var ip = "10.0.0.89"
let tcpClient = TCPClient(serverIP: "10.0.0.89") // Replace with your server IP address

struct ContentView: View {
    
    @State var isConnected: Int = 0
    
    var body: some View {
        TabView {
            AppsPage(isConnected: $isConnected)
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Apps")
                }
            
            PCStatusPage(isConnected: $isConnected)
                .tabItem {
                    Image(systemName: "desktopcomputer")
                    Text("PC Status")
                }
            
            MediaControlsPage()
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Media Controls")
                }
        }
    }
}


struct AppsPage: View {
    @Binding var isConnected: Int
    @State private var message: String = ""
    @State private var showConnectionError = false
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    var body: some View {
        VStack(spacing: 50) {
            Text(connectionStatusText())
                .font(.title)
            
            Text("Remote start App")
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(1...9, id: \.self) { index in
                    Button(action: {
                        let message = "App \(index) tapped"
                        print(message)
                        DispatchQueue.global(qos: .userInitiated).async {
                            tcpClient.sendCommand(message)
                        }
                    }) {
                        Text("App \(index)")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            
            if isConnected == 0{
                Button(action: {
                    connect()
                }) {
                    Text("Connect")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                
            } else {
                Button(action: {
                    disconnect()
                }) {
                    Text("Disconnect")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
        }
        .alert(isPresented: $showConnectionError) {
            Alert(
                title: Text("Connection Failed"),
                message: Text("Failed to connect to the server. Please check your network status."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func connectionStatusText() -> String {
        if isConnected == 2 {
            return "Connecting..."
        } else if isConnected == 1 {
            return "Connected"
        } else {
            return "Disconnected"
        }
    }
    
    func sendMessage(_ message: String) {
        tcpClient.sendCommand(message)
    }
    
    func connect() {
        isConnected = 2
        if tcpClient.run() {
            isConnected = 1
        } else {
            showConnectionError = true
            isConnected = 0
        }
    }
    
    func disconnect() {
        tcpClient.closeConnection()
        isConnected = 0
    }
}

struct PCStatusPage: View {
    @Binding var isConnected: Int
    @ObservedObject var receiver = TCPServer()

    var body: some View {
        VStack(spacing: 60) {
            Text("PC Status")
                .font(.title)
                .padding()

            VStack {
                Text("CPU Usage: \(String(format: "%.1f", receiver.cpuUsage))%")
                ProgressView(value: Double(receiver.cpuUsage) / 100.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            .padding()

            VStack {
                Text("RAM Usage: \(String(format: "%.1f", receiver.ramUsage))%")
                ProgressView(value: Double(receiver.ramUsage) / 100.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
            }
            .padding()
        }
        .onAppear {
            if isConnected == 1 {
                DispatchQueue.global(qos: .background).async {
                    receiver.start()
                }
            }
            else {
                DispatchQueue.main.async {
                    receiver.stop()
                    receiver.cpuUsage = 0
                    receiver.ramUsage = 0
                }
            }
        }
    }
}



//MediaControlsPage
//There are five buttons on the Media Control page
//previous, play/pause, next, volume down, volume down
struct MediaControlsPage: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Media Controls")
                .font(.largeTitle)
                .padding(.bottom, 40)
            
            HStack(spacing: 10) {
                
                CircleButton(action: {
                    tcpClient.sendCommand("media prev")
                    print("previous tapped")
                }) {
                    Image(systemName: "backward.end.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .foregroundColor(.white)
                }
                .padding(40)
                .background(
                    RadialGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), center: .center, startRadius: 5, endRadius: 120)
                )
                .clipShape(Circle())
                .shadow(radius: 10)
                
                CircleButton(action: {
                    tcpClient.sendCommand("media play")
                    print("Play/Pause tapped")
                }) {
                    Image(systemName: "playpause.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .foregroundColor(.white)
                }
                .padding(50)
                .background(
                    RadialGradient(gradient: Gradient(colors: [Color.green, Color.blue]), center: .center, startRadius: 5, endRadius: 150)
                )
                .clipShape(Circle())
                .shadow(radius: 10)
                
                CircleButton(action: {
                    tcpClient.sendCommand("media next")
                    print("Next tapped")
                }) {
                    Image(systemName: "forward.end.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .foregroundColor(.white)
                }
                .padding(40)
                .background(
                    RadialGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), center: .center, startRadius: 5, endRadius: 120)
                )
                .clipShape(Circle())
                .shadow(radius: 10)
            }
            .padding(.bottom, 40)
            
            HStack(spacing: 50) {
                CircleButton(action: {
                    tcpClient.sendCommand("volume down")
                    print("Volume down tapped")
                }) {
                    Image(systemName: "speaker.wave.1.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50)
                        .foregroundColor(.white)
                }
                .padding(30)
                .background(
                    RadialGradient(gradient: Gradient(colors: [Color.orange, Color.red]), center: .center, startRadius: 5, endRadius: 100)
                )
                .clipShape(Circle())
                .shadow(radius: 10)
                
                CircleButton(action: {
                    tcpClient.sendCommand("volume up")
                    print("Volume up tapped")
                }) {
                    Image(systemName: "speaker.wave.3.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70)
                        .foregroundColor(.white)
                }
                .padding(30)
                .background(
                    RadialGradient(gradient: Gradient(colors: [Color.orange, Color.red]), center: .center, startRadius: 5, endRadius:100)
                )
                .clipShape(Circle())
                .shadow(radius: 10)
            }
            .padding()
        }
    }
}

struct CircleButton<Content: View>: View {
    var action: () -> Void
    var content: () -> Content
    
    var body: some View {
        Button(action: action) {
            content()
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
