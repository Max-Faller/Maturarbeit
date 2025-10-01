//
//  App_1.0
//
//  Created by Max Faller on 30.08.2025.
//
import MapKit
import SwiftUI
import CoreMotion

struct ContentView: View {
    
// Variabeln:
    
    @State private var Textfeld = false
    @State private var visibleButton = true
    @State var text = "Beschleunigung:"
    @State var start = false
    
//Beschneunigung Variablen:
    
    let manager = CMMotionManager()
    @State var xBeschleunigung = 0.00000
    @State var yBeschleunigung = 0.00000
    @State var zBeschleunigung = 0.00000
    @State var xyzBeschleunigung = 0.00000
    @State var timer: Timer? = nil
    

    
    
    var body: some View {
        VStack {
            if visibleButton == true {
                Button {
                    visibleButton = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        Textfeld = true
                        start = true
                    }
                } label: {
                    Image(systemName: "play.square")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                }
            }
            
            if Textfeld == true {
                Text(text)
                    .padding()
                    .font(.system(size: 30))
                Text("X: \(xBeschleunigung, specifier: "%.5f")")
                    .padding(.top, 5)
                Text("Y: \(yBeschleunigung, specifier: "%.5f")")
                    .padding(.top, 5)
                Text("Z: \(zBeschleunigung, specifier: "%.5f")")
                    .padding(.top, 5)
                Text("Insgesammt:\(xyzBeschleunigung, specifier: "%.5f")")
            }
        }
        .onChange(of: start) { v in
                    if v == true {
                        startAccelerometerUpdates()
                    }
                }
        .onDisappear {
                manager.stopAccelerometerUpdates()
                timer?.invalidate()
                timer = nil
        }
    }
        
    private func startAccelerometerUpdates() {
        guard manager.isAccelerometerAvailable else {
            return
            }
        
        manager.startAccelerometerUpdates()
        manager.accelerometerUpdateInterval = 0.01
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if let Beschleunigung = self.manager.accelerometerData {
                xBeschleunigung = Beschleunigung.acceleration.x
                yBeschleunigung = Beschleunigung.acceleration.y
                zBeschleunigung = Beschleunigung.acceleration.z
                
                let xSquare = xBeschleunigung * xBeschleunigung
                let ySquare = yBeschleunigung * yBeschleunigung
                let zSquare = zBeschleunigung * zBeschleunigung
                xyzBeschleunigung = sqrt(xSquare + ySquare + zSquare)
                
            }
        }
    }
}

#Preview {
    ContentView()
}
