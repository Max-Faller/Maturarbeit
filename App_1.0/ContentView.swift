//
//  App_1.0
//
//  Created by Max Faller on 30.08.2025.
//
import MapKit
import SwiftUI
import CoreMotion
import CoreLocation



struct BeschleunigungMessung: Codable {
    let timestamp: Date
    let xBeschleunigung: Double
    let yBeschleunigung: Double
    let zBeschleunigung: Double
}
    
    
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
    @State var xBeschleunigungOhneG = 0.00
    @State var yBeschleunigungOhneG = 0.00
    @State var zBeschleunigungOhneG = 0.00
    @State var xBeschleunigungTotal = 0.00
    @State var yBeschleunigungTotal = 0.00
    @State var zBeschleunigungTotal = 0.00
    @State var maxBeschleunigung = 0.00
    
    @State var Zaeler = 0
    @State var reset = false
    
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
    
    //Varabeln fuer das Speichern der Daten:
    
    @State private var beschleunigungMessungen: [BeschleunigungMessung] = []

    
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
            
            //Start Button
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
                
                //reset Button
                Button {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        
                        xGeschwindigkeit = 0.0
                        yGeschwindigkeit = 0.0
                        zGeschwindigkeit = 0.0
                        gesammtGeschwindigkeit = 0.0
                        xDistanz = 0.0
                        yDistanz = 0.0
                        zDistanz = 0.0
                        gesammtDistanz = 0.0
                        teileDatei()
                    }
                } label: {
                    Image(systemName: "repeat.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)
                }
                
                Text("X: \(xBeschleunigung, specifier: "%.3f")")
                    .padding(.top, 5)
                Text("Y: \(yBeschleunigung, specifier: "%.3f")")
                    .padding(.top, 5)
                Text("Z: \(zBeschleunigung, specifier: "%.3f")")
                    .padding(.top, 5)
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
                Text("GPS-Distanz: \(gesammtBewegung, specifier: "%.3f")")
                    .padding(.top, 5)
            }
        }
        
        
        .onAppear { //sobald App gestartet wird, wird GPS ausgelesen
            locationDelegate.onLocationUpdate = { lat, lon, alt in
                BreitenGrad = lat
                LaengenGrad = lon
                hoehe = alt
            }
            
            locationManager.delegate = locationDelegate
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            GPSberechnung()
        }
        
        .onChange(of: start) { newValue in
            if newValue == true {
                startMessung()
                //GeschwindigkeitsTimer()
            }
        }
     
        .onDisappear {
            manager.stopDeviceMotionUpdates()
            timer?.invalidate()
            timer = nil
            locationManager.stopUpdatingLocation()
            speichernBeschleunigungsDaten()
        }
    }
    
    //Funktionen:::::
    
    
    //Funktion zum speichern der Daten
    
    private func speichernBeschleunigungsDaten() {
        let fileManager = FileManager.default
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("beschleunigung_messungen.csv")
        
        let header = "Timestamp,X,Y,Z\n"
        var csvText = header
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        
        // Daten im CVS-Format --- Hilfe von ChatGPT
        for messung in beschleunigungMessungen {
            let timestamp = dateFormatter.string(from: messung.timestamp)
            let line = "\(timestamp),\(messung.xBeschleunigung),\(messung.yBeschleunigung),\(messung.zBeschleunigung)\n"
            csvText.append(line)
        }
        do {
            try csvText.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Fehler beim speichern")
        }
    }

    private func teileDatei() {    //ChatGPT hilfe
        let fileManager = FileManager.default
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("beschleunigung_messungen.csv")
            
        if fileManager.fileExists(atPath: url.path) {
            let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityController, animated: true, completion: nil)
            }
        }
    }
    
    
    
    
    //FUnktion auslesen und integrieren der Beschleunigungsdaten:
    
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
                
                xBeschleunigungOhneG = xBeschleunigung*9.81
                yBeschleunigungOhneG = yBeschleunigung*9.81
                zBeschleunigungOhneG = zBeschleunigung*9.81
                
                //Sensorrauschen im Ruhezustand
                if xBeschleunigungOhneG < 0.05 && xBeschleunigungOhneG > -0.05 {
                    xBeschleunigungOhneG = 0.00000
                }
                if yBeschleunigungOhneG < 0.05 && yBeschleunigungOhneG > -0.05 {
                    yBeschleunigungOhneG = 0.00000
                }
                
                if zBeschleunigungOhneG < 0.05 && zBeschleunigungOhneG > -0.05 {
                    zBeschleunigungOhneG = 0.00000
                }
                //Daten speichern
                let neueMessung = BeschleunigungMessung(timestamp: Date(), xBeschleunigung: xBeschleunigung, yBeschleunigung: yBeschleunigung, zBeschleunigung: zBeschleunigung)
                beschleunigungMessungen.append(neueMessung)
                speichernBeschleunigungsDaten()
                
                //Integrieren
                
                xGeschwindigkeit = xGeschwindigkeit + xBeschleunigungOhneG * 0.01
                yGeschwindigkeit = yGeschwindigkeit + yBeschleunigungOhneG * 0.01
                zGeschwindigkeit = zGeschwindigkeit + zBeschleunigungOhneG * 0.01
                
                gesammtGeschwindigkeit = sqrt(pow(xGeschwindigkeit, 2) + pow(yGeschwindigkeit, 2) + pow(zGeschwindigkeit, 2))
                
                xDistanz = xDistanz + xGeschwindigkeit * 0.01
                yDistanz = yDistanz + yGeschwindigkeit * 0.01
                zDistanz = zDistanz + zGeschwindigkeit * 0.01
            }
        }
    }

    func GPSberechnung() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
        
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
            MeterBewegungLG = abs(DeltaLG) * 111.319 * cos(BreitenGrad*Double.pi/180) //Radiant
            
            altBreitenGrad = BreitenGrad
            altLaengenGrad = LaengenGrad
            althoehe = hoehe
            
            //Strecke in Metern
            
            DeltaBewegung = sqrt((MeterBewegungBG * MeterBewegungBG) + (MeterBewegungLG * MeterBewegungLG) + (DeltaHoehe * DeltaHoehe)) // veränderung
            gesammtBewegung = gesammtBewegung + DeltaBewegung   // gesammt Strecke
            
        }
    }
}






#Preview {
    ContentView()
}






