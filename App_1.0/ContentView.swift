//
//  App_1.0
//
//  Created by Max Faller on 30.08.2025.
//
import MapKit
import SwiftUI
import CoreMotion
import CoreLocation

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var onLocationUpdate: ((Double, Double, Double) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            onLocationUpdate?(location.coordinate.latitude, location.coordinate.longitude, location.altitude)
        }
    }
}

struct ContentView: View {
    
    // Variabeln:
    
    @State private var Textfeld = false
    @State private var visibleButton = true
    @State var text = "Beschleunigung:"
    @State var start = false
    
    //Beschneunigung Variablen:
    
    let manager = CMMotionManager()
    
    @State var xBeschleunigung = 0.00
    @State var yBeschleunigung = 0.00
    @State var zBeschleunigung = 0.00
    @State var xBeschleunigungTotal = 0.00
    @State var yBeschleunigungTotal = 0.00
    @State var zBeschleunigungTotal = 0.00
    @State var maxBeschleunigung = 0.00
    
    @State var Zaeler = 0
    
    //Geschwindikeit Variabeln:
    
    @State var xGeschwindigkeit = 0.00
    @State var yGeschwindigkeit = 0.00
    @State var zGeschwindigkeit = 0.00
    @State var gesammtGeschwindigkeit = 0.00
    
    @State var xDistanz = 0.00
    @State var yDistanz = 0.00
    @State var zDistanz = 0.00
    @State var gesammtDistanz = 0.00
    
    @State var timer: Timer?
    
    //GPS Variabeln:
    
    @State private var locationManager = CLLocationManager()
    @State private var locationDelegate = LocationDelegate()
    @State var BreitenGrad = 0.00
    @State var LaengenGrad = 0.00
    @State var altBreitenGrad = 0.00
    @State var altLaengenGrad = 0.00
    @State var Location = false
    
    @State var DeltaBG = 0.00
    @State var DeltaLG = 0.00
    @State var MeterBewegungBG = 0.00
    @State var MeterBewegungLG = 0.00
    
    @State var hoehe = 0.00 // in m.ü.M
    @State var althoehe = 0.00 // in m.ü.M
    @State var DeltaHoehe = 0.00
    
    @State var DeltaBewegung = 0.00
    @State var gesammtBewegung = 0.00
    
    @State var einmalig = 0
    
    
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
                Text("X: \(xBeschleunigung, specifier: "%.3f")")
                    .padding(.top, 5)
                Text("Y: \(yBeschleunigung, specifier: "%.3f")")
                    .padding(.top, 5)
                Text("Z: \(zBeschleunigung, specifier: "%.3f")")
                    .padding(.top, 5)
                //Text("Max:\(maxBeschleunigung, specifier: "%.3f")")
                Text("X: \(xDistanz, specifier: "%.3f")")
                    .padding(.top, 5)
                Text("Y: \(yDistanz, specifier: "%.3f")")
                    .padding(.top, 5)
                Text("Z: \(zDistanz, specifier: "%.3f")")
                    .padding(.top, 5)
                Text("Geschwindgkeit:\(gesammtGeschwindigkeit, specifier: "%.3f")")
                    .padding(.top, 5)
                Text("Distanz:\(gesammtDistanz, specifier: "%.3f")")
                    .padding(.top, 5)
                Text("Längengrad: \(LaengenGrad, specifier: "%.3f")")
                    .padding(.top, 5)
                Text("Breitengrad: \(BreitenGrad, specifier: "%.3f")")
                    .padding(.top, 5)
                Text("Höhe über Meer: \(hoehe, specifier: "%.3f")")
                    .padding(.top, 5)
                
            }
        }
        
        
        
        
        
        .onAppear {
            locationDelegate.onLocationUpdate = { lat, lon, alt in
                BreitenGrad = lat
                LaengenGrad = lon
                hoehe = alt
            }
            
            locationManager.delegate = locationDelegate
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        .onChange(of: start) { newValue in
            if newValue == true {
                startMessung()
                GeschwindigkeitsTimer()
            }
        }
        
        .onDisappear {
            manager.stopDeviceMotionUpdates()
            timer?.invalidate()
            timer = nil
            locationManager.stopUpdatingLocation()
        }
    }
    
    
    //Funktionen
    
    
    private func startMessung() {
        
        //Sensoren pruefen
        guard manager.isDeviceMotionAvailable else {
            text = "Sensor geht nicht"
            return
        }
        
        //INtervall
        manager.deviceMotionUpdateInterval = 0.02
        
        // Start Messung
        manager.startDeviceMotionUpdates(to: .main) { motion, error in
            if let motion = motion {
                
                let acc = motion.userAcceleration
                xBeschleunigung = acc.x
                yBeschleunigung = acc.y
                zBeschleunigung = acc.z
                
                xBeschleunigung = round(xBeschleunigung * 1000) / 1000
                yBeschleunigung = round(yBeschleunigung * 1000) / 1000
                zBeschleunigung = round(zBeschleunigung * 1000) / 1000
            }
            
            //Sensorrauschen im Ruhezustand
            if xBeschleunigung < 0.01 && xBeschleunigung > -0.01 {
                xBeschleunigung = 0.00000
            }
            if yBeschleunigung < 0.01 && yBeschleunigung > -0.01 {
                yBeschleunigung = 0.00000
            }
            
            if zBeschleunigung < 0.01 && zBeschleunigung > -0.01 {
                zBeschleunigung = 0.00000
            }
        }
    }
    
    func GeschwindigkeitsTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            
            //xBeschleunigungTotal = xBeschleunigungTotal + xBeschleunigung
            //yBeschleunigungTotal = yBeschleunigungTotal + yBeschleunigung
            //zBeschleunigungTotal = zBeschleunigungTotal + zBeschleunigung
            
            //Zaeler = Zaeler + 1
            
            //if Zaeler == 20 {
                //Zaeler = 0
            
                // Integriere X,Y,Z
            xGeschwindigkeit = xGeschwindigkeit + xBeschleunigung * 9.81 * 0.02
            yGeschwindigkeit = yGeschwindigkeit + yBeschleunigung * 9.81 * 0.02
            zGeschwindigkeit = zGeschwindigkeit + zBeschleunigung * 9.81 * 0.02
 
            gesammtGeschwindigkeit = sqrt((xGeschwindigkeit * xGeschwindigkeit) + (yGeschwindigkeit * yGeschwindigkeit) + (zGeschwindigkeit * zGeschwindigkeit))

                // Integriere X,Y,Z
            xDistanz = xDistanz + xGeschwindigkeit * 0.02
            yDistanz = yDistanz + yGeschwindigkeit * 0.02
            zDistanz = zDistanz + zGeschwindigkeit * 0.02

            gesammtDistanz = sqrt((xDistanz * xDistanz) + (yDistanz * yDistanz) + (zDistanz * zDistanz))

            
                //xBeschleunigungTotal = 0.00000
                //yBeschleunigungTotal = 0.00000
                //zBeschleunigungTotal = 0.00000
            
        }
    }
    
    func GPSberechnung() {
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
        
            if einmalig == 0 {  //beim ersten Durchgang wird keine Bewegung registriert
                einmalig = 1
                altBreitenGrad = BreitenGrad
                altLaengenGrad = LaengenGrad
                althoehe = hoehe
            }
            
            DeltaBG = BreitenGrad - altBreitenGrad //111.133m pro Breitengrad veränderung
            DeltaLG = LaengenGrad - altLaengenGrad //111.319m * cos(BreitenGrad) pro Längengrad veränderung
            DeltaHoehe = hoehe - althoehe
            
            MeterBewegungBG = abs(DeltaBG) * 111.133
            MeterBewegungLG = abs(DeltaLG) * 111.319 * cos(BreitenGrad)
            
            altBreitenGrad = BreitenGrad
            altLaengenGrad = LaengenGrad
            althoehe = hoehe
            
            //Strecke in Metern
            
            DeltaBewegung = sqrt((MeterBewegungBG * MeterBewegungBG) + (MeterBewegungLG * MeterBewegungLG) + (DeltaHoehe * DeltaHoehe)) // veränderung
            gesammtBewegung = gesammtBewegung + DeltaBewegung    // gesammt Strecke
            
        }
    }
}

#Preview {
    ContentView()
}






