//
//  App_1.0
//
//  Created by Max Faller on 30.08.2025.
//
import MapKit
import SwiftUI
import CoreMotion
import CoreLocation







//Variabeln um Daten zu speichern
struct BeschleunigungMessung: Codable {  //fuer das Speichern der Daten werden Variabeln definiert
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
    
    //Daten GPS

}
    


    
class LocationDelegate: NSObject, CLLocationManagerDelegate {           //klasse wird erstellt -> fuer die GPS Daten
    var onLocationUpdate: ((Double, Double, Double, Double) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            onLocationUpdate?(location.coordinate.latitude, location.coordinate.longitude, location.altitude, location.speed)
        }
    }
}





struct ContentView: View {
    
    
    
    
    
    // Variabeln Allgemein:
    
    @State private var Textfeld = false
    @State var NameTextfeld = false
    @State private var visibleButton = true
    @State var text = "Beschleunigung:"
    @State var AppName = "App von Max"
    @State var start = false
    @State var showMenu = false
    @State var showUI = false
    @State private var StartStopp = false

    
    
    
    //Beschneunigung Variablen:
    
    let manager = CMMotionManager()
    
    //Beschleunigungsdaten
    @State private var accX = 0.00
    @State private var accY = 0.00
    @State private var accZ = 0.00
    
    @State var xWelt = 0.00
    @State var yWelt = 0.00
    @State var zWelt = 0.00
    
    
    //rohes g
    @State private var gx = 0.00
    @State private var gy = 0.00
    @State private var gz = 0.00

   //Magnetfeld
    @State private var magnetfeld = 0.00
    @State private var magX = 0.00
    @State private var magY = 0.00
    @State private var magZ = 0.00
    
    //Eulerwinkel
    @State private var rollX = 0.00
    @State private var pitchY = 0.00
    @State private var yawZ = 0.00
    
    @State var m = CMRotationMatrix( m11: 1.0, m12: 0.0, m13: 0.0,
                                     m21: 0.0, m22: 1.0, m23: 0.0,
                                     m31: 0.0, m32: 0.0, m33: 1.0 )
    


    @State var Zaeler = 0
    @State var reset = false
    
    //Gyrovariablen
    
    @State var roll = 0.00
    @State var pitch = 0.00
    @State var yaw = 0.00
    
    //Berechnungen:
    
    @State var a_offset_x: Double = 0.00
    @State var a_offset_y: Double = 0.00
    @State var a_offset_z: Double = 0.00
    
    @State var accX_real = 0.00
    @State var accY_real = 0.00
    @State var accZ_real = 0.00

    
    
    //Geschwindikeit Variabeln:
    
    @State var Vx = 0.00
    @State var Vy = 0.00
    @State var Vz = 0.00
    @State var Vgesammt = 0.00
    
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
    @State var MaxGeschwindigkeit = 0.00
    @State var Startzeit: Date = .now
    
    
    @State var einmalig = 0
    
    
    //Variabeln zur Karte:
    
    @State var position = MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0.00, longitude: 0.00), span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)))
    @State var userLocation: CLLocationCoordinate2D?
    
    //UI:
    
    var body: some View {
        
        
        ZStack {
            if showUI == false {                                        //Startbildschirm
                if visibleButton == true {
                    Text("Tippe um zu starten")
                        .font(.title)
                        .bold()
                }
            }
            else {
                Map(position: $position) {                              //Karte wird angezeigt
                    if let userLocation = userLocation {
                        Annotation("", coordinate: userLocation) {      //Standort wird angezeigt
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                                .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3))
                        }
                    }
                }
                    
                .ignoresSafeArea()
                
                
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        
                        HStack {
                            Text(String(format: "%.1f", Vgesammt))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f", MaxGeschwindigkeit))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: 150)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f", MomentanGeschwindigkeitGPS))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                        
                        
                        
                        Button {
                            StartStopp.toggle()
                            
                            if StartStopp == false {
                                
                            }
                            
                            if StartStopp == true {
                                
                            }
                            
                        } label: {
                            
                            Image(systemName: StartStopp ? "stop.circle" : "play.circle")           // Passendes Bild wird gezeigt
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 60)
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, 30)
                    }
                    .background(Color.black)
                    .cornerRadius(30)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }
                
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 10) {
                            Button {
                                withAnimation {
                                    showMenu.toggle()
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.9))
                                    .clipShape(Circle())
                            }
                            
                            if showMenu {
                                VStack(alignment: .trailing, spacing: 10) {
                                    Button("Reset") {
                                        accX = 0.00
                                        accY = 0.00
                                        accZ = 0.00
                                        Vx = 0.00
                                        Vy = 0.00
                                        Vz = 0.00
                                    }
                                        .padding(8)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        .shadow(radius: 3)
                                        
                                    Button("Daten exportieren") {
                                        teileDatei()
                                    }
                                        .padding(8)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        .shadow(radius: 3)
                                }
                                .transition(.opacity)
                            }
                        }
                        .padding(.trailing, 10)
                        .padding(.top, 10)
                    }
                    Spacer()
                }
            }
        }
        .onTapGesture {
            if showUI == false && visibleButton == true {
                visibleButton = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Textfeld = true
                    start = true
                    showUI = true
                }
            }
        }
        
        .onAppear {    //Was Passieren soll wenn App gestartet wird
        }
        
        .onChange(of: start) {
            startMessung()              //Beschleunigunssensoren
            GPSberechnung()             //GPS Funktion
            Maps()                      //Funktion fuer die karte

            
            
            // Daten fuer GPS
            locationDelegate.onLocationUpdate = { lat, lon, alt, speed in               // GPS komponente zuweisen
                BreitenGrad = lat
                LaengenGrad = lon
                hoehe = alt
                MomentanGeschwindigkeitGPS = speed
                Maps()
                userLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon) //Standort auf der Karte
            }
            
            locationManager.delegate = locationDelegate
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()

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
    
    //AppleMaps Karte
    
    private func Maps() {    //Funktion um Daten zu akktualisieren          Quelle: https://bugfender.com/blog/mapkit-swiftui/ Bemerkung: nicht Eins zu Eins jedoch wurden Elemente uebernommen
        position = .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: BreitenGrad, longitude: LaengenGrad),
                        span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)))
    }
    
    
    
    
    
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
    
    func startMessung() {
        
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
  
            
            //Beschleunigungsdaten in g ohne g
            accX = motion.userAcceleration.x
            accY = motion.userAcceleration.y
            accZ = motion.userAcceleration.z
            
            
            //rohes g
            gx = motion.gravity.x
            gy = motion.gravity.y
            gz = motion.gravity.z
        
            
            //Magnetfeld
            magX = motion.magneticField.field.x
            magY = motion.magneticField.field.y
            magZ = motion.magneticField.field.z
            
            magnetfeld = sqrt(magX*magX + magY*magY + magZ*magZ)
            
            
            //Drehdaten mit Gyroskop
            rollX = motion.rotationRate.x
            pitchY = motion.rotationRate.y
            yawZ = motion.rotationRate.z
            
            //Berechnungen:
            
            //Tiefpassfilter:
            //Variabeln:
            
            let alpha_offset = 0.99     //Vergessensfaktor fuer offset schaetzung
            let remove_offset = 1    // 0 - Offset nicht wegrechnen 1 - Offset wegrechnen
            let thr_offset = 0.01       // m/s/s Grenze
            let delta_t = 0.01
            
    
   
            
            // Offset schätzen (läuft immer)
            if abs(accX) < thr_offset {
                a_offset_x = (1 - alpha_offset) * accX + alpha_offset * a_offset_x
            }
            if abs(accY) < thr_offset {
                a_offset_y = (1 - alpha_offset) * accY + alpha_offset * a_offset_y
            }
            if abs(accZ) < thr_offset {
                a_offset_z = (1 - alpha_offset) * accZ + alpha_offset * a_offset_z
            }

            // Offset wegrechnen (nur wenn remove_offset == 1)
            if remove_offset == 1 {
                accX_real = accX - a_offset_x
                accY_real = accY - a_offset_y
                accZ_real = accZ - a_offset_z
            }
            
            //integreiren der Eulerwinkel sind in rad/s gegeben
            roll = roll + delta_t * rollX
            pitch = pitch + delta_t * pitchY
            yaw = yaw + delta_t * yawZ
            
            let m = eulerToRotationMatrix(roll: roll, pitch: pitch, yaw: yaw)
            
            
            
            // Beschleunigung im Weltkoordinatensistem:(mit Drehmatrix gedreht)
            xWelt = m.m11 * accX_real + m.m12 * accY_real + m.m13 * accZ_real
            yWelt = m.m21 * accX_real + m.m22 * accY_real + m.m23 * accZ_real
            zWelt = m.m31 * accX_real + m.m32 * accY_real + m.m33 * accZ_real
        
            //INtegration:
            
            Vx = Vx + delta_t * xWelt * 9.81
            Vy = Vy + delta_t * yWelt * 9.81
            Vz = Vz + delta_t * zWelt * 9.81
            
            Vgesammt = sqrt(Vx * Vx + Vy * Vy + Vz * Vz)
            
            //Daten speichern
        
            let neueMessung = BeschleunigungMessung(
                timestamp: Date(),
                
                // Rohdaten
                RollX: rollX,
                PitchY: pitchY,
                YawZ: yawZ,
                
                accX: accX,
                accY: accY,
                accZ: accZ,
                
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
    
    //Eulerwinkel zu MAtrix
    
    func eulerToRotationMatrix(roll: Double, pitch: Double, yaw: Double) -> CMRotationMatrix {
        
        let cr = cos(roll),  sr = sin(roll)
        let cp = cos(pitch), sp = sin(pitch)
        let cy = cos(yaw),   sy = sin(yaw)
        
        return CMRotationMatrix(
            m11: cy * cp,
            m12: cy * sp * sr - sy * cr,
            m13: cy * sp * cr + sy * sr,
            
            m21: sy * cp,
            m22: sy * sp * sr + cy * cr,
            m23: sy * sp * cr - cy * sr,
            
            m31: -sp,
            m32: cp * sr,
            m33: cp * cr
        )
    }

    
    func GPSberechnung() {                              //Funktion fuer die berechnung mit GPS
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
        
            
            if einmalig == 0 {                          // altBreitenGrad definieren - erster durchgang misst nichts
                altBreitenGrad = BreitenGrad
                altLaengenGrad = LaengenGrad
                althoehe = hoehe
                einmalig = 1
            }
            
            if einmalig == 1 {                          //Starzeit
                Startzeit = Date()
                einmalig = 2

            }
            
            
            
            DeltaBG = BreitenGrad - altBreitenGrad      //111133m pro Breitengrad veränderung
            DeltaLG = LaengenGrad - altLaengenGrad      //111319m * cos(BreitenGrad) pro Längengrad veränderung
            DeltaHoehe = hoehe - althoehe
            
            RadiantBreitenGrad = BreitenGrad*Double.pi/180      //wird in Radiant umgerechnet damit cos funktion benutzt werden kann
            
            MeterBewegungBG = abs(DeltaBG) * 111133                                     //Distanz in m
            MeterBewegungLG = abs(DeltaLG) * 111319 * cos(RadiantBreitenGrad)           //Distanz in m
            
            altBreitenGrad = BreitenGrad
            altLaengenGrad = LaengenGrad
            althoehe = hoehe
            
            
            //Strecke in Metern
            
            DeltaBewegung = sqrt((MeterBewegungBG * MeterBewegungBG) + (MeterBewegungLG * MeterBewegungLG) + (DeltaHoehe * DeltaHoehe)) // gesammte Bewegung
            gesammtBewegung = gesammtBewegung + DeltaBewegung   // gesammt Strecke
            
            DurchschnittGeschwindigkeitGPS = gesammtBewegung / (Date().timeIntervalSince(Startzeit))
            
            
            //Geschwindigkeit
            
            if MomentanGeschwindigkeitGPS <= 0 {                //hat teilweise leicht negative Werte ausgegeben werden so entfernt
                MomentanGeschwindigkeitGPS = 0.00
            }
            else {
                MomentanGeschwindigkeitGPS = MomentanGeschwindigkeitGPS*3.6         //in km/h
            }
            
            if MomentanGeschwindigkeitGPS > MaxGeschwindigkeit {
                MaxGeschwindigkeit = MomentanGeschwindigkeitGPS
                
            }
        }
    }
}





#Preview {
    ContentView()
}






