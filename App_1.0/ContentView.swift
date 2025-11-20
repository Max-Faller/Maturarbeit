//
//  App_1.0
//
//  Created by Max Faller on 30.08.2025.
//
import MapKit
import SwiftUI
import CoreMotion
import CoreLocation



struct BeschleunigungMessung: Codable {  //fuer das Speichern der Datenb
    let timestamp: Date
    //Beschleunigung speichern
  
    // Rohdaten drehung
    let RollX, PitchY, YawZ: Double
    
    //Rohdaten Beschleunigung mit g
    let accX, accY, accZ: Double
    
    //Rohdaten G
    let gX, gY, gZ: Double
    
    //Daten Magnetfeld
    let magX, magY, magZ: Double

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
    @State var NameTextfeld = false
    @State private var visibleButton = true
    @State var text = "Beschleunigung:"
    @State var AppName = "App von Max"
    @State var start = false
    
    
    //Beschneunigung Variablen:
    
    let manager = CMMotionManager()
    
    @State var xBeschleunigung = 0.00
    @State var yBeschleunigung = 0.00
    @State var zBeschleunigung = 0.00
    @State var xWeltOhneG = 0.00
    @State var yWeltOhneG = 0.00
    @State var zWeltOhneG = 0.00
    @State var xBeschleunigungTotal = 0.00
    @State var yBeschleunigungTotal = 0.00
    @State var zBeschleunigungTotal = 0.00
    @State var maxBeschleunigung = 0.00
    
    @State var xWelt = 0.00
    @State var yWelt = 0.00
    @State var zWelt = 0.00
    @State var m = CMRotationMatrix( m11: 1.0, m12: 0.0, m13: 0.0,
                                     m21: 0.0, m22: 1.0, m23: 0.0,
                                     m31: 0.0, m32: 0.0, m33: 1.0 )

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
    @State var RadiantBreitenGrad = 0.00
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
    
    @State var DurchschnittGeschwindigkeitGPS = 0.00
    @State var MomentanGeschwindigkeitGPS = 0.00
    @State var Startzeit: Date = .now
    
    
    @State var einmalig = 0
    
    
    //UI:
    
    var body: some View {
        ZStack {
            
            VStack {
                
                //Start Button
                if visibleButton == true {
                    Button {
                        visibleButton = false
                        NameTextfeld = true
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
            
            
            VStack {   //linke Ecke oben
                HStack {
                    Text("")
                    Spacer()
                }
                Spacer()
            }
            
            VStack {    //rechte Ecke oben
                HStack {
                    Spacer()
                    Text(AppName)
                        .font(.title)
                        .font(.system(size: 15))
                        .padding()
                }
                Spacer()
            }
        }
        
        
        .onAppear { //sobald App gestartet wird, wird GPS ausgelesen
        
        }
        
        .onChange(of: start) { newValue in
            if newValue == true {
                startMessung() //Beschleunigunssensoren
    
                locationDelegate.onLocationUpdate = { lat, lon, alt in // GPS auslesen
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
        
        let header = "Timestamp,RollGyroX,PitchGyroY,YawGyroZ,accX,accY,accZ,gX,gY,gZ\n"
        var csvText = header
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "SSS"     //soll nur in Milisekunden Gespeichert werden
        
        
        
        // Daten im CVS-Format --- Hilfe von ChatGPT
        for messung in beschleunigungMessungen {
            let timestamp = dateFormatter.string(from: messung.timestamp)
            let line = "\(timestamp),\(messung.RollX),\(messung.PitchY),\(messung.YawZ)," +
                       "\(messung.accX),\(messung.accY),\(messung.accZ)," +
                       "\(messung.gX),\(messung.gY),\(messung.gZ)," + "\(messung.magX),\(messung.magY),\(messung.magZ)\n"
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
    
    
    
    
    
    
    
    
    //FUnktion: auslesen und integrieren der Beschleunigungsdaten:
    
    private func startMessung() {
        
        //Sensoren pruefen
        guard manager.isDeviceMotionAvailable else {
            text = "Sensor geht nicht"
            return
        }
        
        //INtervall
        manager.deviceMotionUpdateInterval = 0.01
        
        // Start Messung
        manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { motion, error in
            guard let motion = motion else { return }
                
            let quat = motion.attitude.quaternion //Drehung wird in Quaternion ausgelesen weil es mit Drehmatrix nicht geklappt hat
            let m = quat.RotationMatrix()   // wird im Matrix umgewandelt

            
            // Beschleunigung im Weltkoordinatensistem:(mit Drehmatrix gedreht)
            xWelt = m.m11 * xBeschleunigung + m.m12 * yBeschleunigung + m.m13 * zBeschleunigung
            yWelt = m.m21 * xBeschleunigung + m.m22 * yBeschleunigung + m.m23 * zBeschleunigung
            zWelt = m.m31 * xBeschleunigung + m.m32 * yBeschleunigung + m.m33 * zBeschleunigung
        
            
            //Beschleunigungsdaten in g ohne g
            let acc = motion.userAcceleration
            xBeschleunigung = acc.x
            yBeschleunigung = acc.y
            zBeschleunigung = acc.z
            
             //rohes g
            let gx = motion.gravity.x
            let gy = motion.gravity.y
            let gz = motion.gravity.z
            
            let raw_accX = xBeschleunigung //+ gx
            let raw_accY = xBeschleunigung //+ gy
            let raw_accZ = xBeschleunigung //+ gz
            
            //Magnetfeld
            let magnetfeld = motion.magneticField
            let magX = magnetfeld.field.x
            let magY = magnetfeld.field.y
            let magZ = magnetfeld.field.z
            
            
            // Beschleunigung in Weltkoordinaten drehen
            xWelt = m.m11 * xBeschleunigung + m.m12 * yBeschleunigung + m.m13 * zBeschleunigung
            yWelt = m.m21 * xBeschleunigung + m.m22 * yBeschleunigung + m.m23 * zBeschleunigung
            zWelt = m.m31 * xBeschleunigung + m.m32 * yBeschleunigung + m.m33 * zBeschleunigung
            
            
            xWeltOhneG = xWelt*9.81
            yWeltOhneG = yWelt*9.81
            zWeltOhneG = zWelt*9.81
    
            
            //Daten speichern
        
            let neueMessung = BeschleunigungMessung(
                timestamp: Date(),
                
                // Rohdaten
                RollX: motion.rotationRate.x,
                PitchY: motion.rotationRate.y,
                YawZ: motion.rotationRate.z,
                
                accX: raw_accX,
                accY: raw_accY,
                accZ: raw_accZ,
                
                gX: gx,
                gY: gy,
                gZ: gz,
                
                magX: magX,
                magY: magY,
                magZ: magZ
            
            )
            beschleunigungMessungen.append(neueMessung)
            speichernBeschleunigungsDaten()
            
            //Integrieren      ---erst mit bereinigten daten

    
        }
    }

    
    func GPSberechnung() {                 //Funktion fuer die berechnung mit GPS
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            
            if einmalig == 1 {                   //Starzeit
                Startzeit = Date()
                einmalig = 2
            }
            
            if einmalig == 0 {                  // altBreitenGrad definieren - erster durchgang misst nichts
                altBreitenGrad = BreitenGrad
                altLaengenGrad = LaengenGrad
                althoehe = hoehe
                einmalig = 1
            }
            
            
            DeltaBG = BreitenGrad - altBreitenGrad //111.133m pro Breitengrad veränderung
            DeltaLG = LaengenGrad - altLaengenGrad //111.319m * cos(BreitenGrad) pro Längengrad veränderung
            DeltaHoehe = hoehe - althoehe
            
            RadiantBreitenGrad = BreitenGrad*Double.pi/180 //wird in Radiant umgerechnet damit cos funktion benutzt werden kann
            
            MeterBewegungBG = abs(DeltaBG) * 111.133
            MeterBewegungLG = abs(DeltaLG) * 111.319 * cos(RadiantBreitenGrad)
            
            altBreitenGrad = BreitenGrad
            altLaengenGrad = LaengenGrad
            althoehe = hoehe
            
            //Strecke in Metern
            
            DeltaBewegung = sqrt((MeterBewegungBG * MeterBewegungBG) + (MeterBewegungLG * MeterBewegungLG) + (DeltaHoehe * DeltaHoehe)) // veränderung
            gesammtBewegung = gesammtBewegung + DeltaBewegung   // gesammt Strecke
            
            DurchschnittGeschwindigkeitGPS = gesammtBewegung / (Date().timeIntervalSince(Startzeit))
            MomentanGeschwindigkeitGPS = DeltaBewegung / 1
            
        }
    }
}





extension CMQuaternion {   //Quaternion in Matrize umwandeln
    func RotationMatrix() -> CMRotationMatrix {
        var m = CMRotationMatrix()
        let xx = x*x, yy = y*y, zz = z*z
        let xy = x*y, xz = x*z, yz = y*z
        let wx = w*x, wy = w*y, wz = w*z
        
        m.m11 = 1 - 2*(yy + zz);        m.m12 = 2*(xy - wz);            m.m13 = 2*(xz + wy)
        m.m21 = 2*(xy + wz);            m.m22 = 1 - 2*(xx + zz);        m.m23 = 2*(yz - wx)
        m.m31 = 2*(xz - wy);            m.m32 = 2*(yz + wx);            m.m33 = 1 - 2*(xx + yy)
        
        return m
    }
}







#Preview {
    ContentView()
}






