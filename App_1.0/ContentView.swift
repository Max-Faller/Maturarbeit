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
    @State var maxBeschleunigung = 0.00000
    
//Geschwindikeit Variabeln:
    
    @State var xGeschwindigkeit = 0.00000
    @State var yGeschwindigkeit = 0.00000
    @State var zGeschwindigkeit = 0.00000
    @State var gesammtGeschwindigkeit = 0.00000
    
    @State var timer: Timer?

//UI:
    
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
                //Text("Max:\(maxBeschleunigung, specifier: "%.5f")")
                Text("X: \(xGeschwindigkeit, specifier: "%.5f")")
                    .padding(.top, 5)
                Text("Y: \(yGeschwindigkeit, specifier: "%.5f")")
                    .padding(.top, 5)
                Text("Z: \(zGeschwindigkeit, specifier: "%.5f")")
                    .padding(.top, 5)
                Text("Geschwindgkeit:\(gesammtGeschwindigkeit, specifier: "%.5f")")
                
            }
        }
        .onChange(of: start) { newValue in
            if newValue == true {
                print(true)
                startMessung()
                GeschwindigkeitsTimer()
                        
            }
        }
        .onDisappear {
            manager.stopDeviceMotionUpdates()
            timer?.invalidate()
            timer = nil
        }
    }
    
    
    private func startMessung() {
        
        //Sensoren pruefen
        guard manager.isDeviceMotionAvailable else {
            text = "Sensor geht nicht"
            return
        }
        
        //INtervall
        manager.deviceMotionUpdateInterval = 0.01
        
        // Start Messung
        manager.startDeviceMotionUpdates(to: .main) { motion, error in
            if let motion = motion {
                
                let acc = motion.userAcceleration
                xBeschleunigung = acc.x
                yBeschleunigung = acc.y
                zBeschleunigung = acc.z
                
                //Ueberpruefen ob es richtig funktionniert
                if maxBeschleunigung < abs(acc.x) {
                    maxBeschleunigung = abs(acc.x)
                }
                if maxBeschleunigung < abs(acc.z) {
                    maxBeschleunigung = abs(acc.z)
                }
                if maxBeschleunigung < abs(acc.y) {
                    maxBeschleunigung = abs(acc.y)
                }
            }
        }
    }
    
    func GeschwindigkeitsTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            // Integriere X,Y,Z
            xGeschwindigkeit = xGeschwindigkeit + xBeschleunigung * 9.81 * 0.01
            yGeschwindigkeit = yGeschwindigkeit + yBeschleunigung * 9.81 * 0.01
            zGeschwindigkeit = zGeschwindigkeit + zBeschleunigung * 9.81 * 0.01
            
            gesammtGeschwindigkeit = sqrt(pow(xGeschwindigkeit, 2) + pow(yGeschwindigkeit, 2) + pow(zGeschwindigkeit, 2))
            
        }
    }
}

#Preview {
    ContentView()
}
