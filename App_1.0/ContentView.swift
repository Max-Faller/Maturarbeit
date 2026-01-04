//
//  App_1.0
//
//  Created by Max Faller on 30.08.2025.
//
import MapKit
import SwiftUI
import CoreMotion
import CoreLocation






//-----------------------------------------------------------------------------------------------------------------------------
// Variabeln um Daten zu speichern
//-----------------------------------------------------------------------------------------------------------------------------

// aus ChatGPT uebernommen siehe schriftliche Arbeit

struct BeschleunigungMessung: Codable {
    let timestamp: Date
    
    // Rohdaten Beschleunigung (unbereinigt)
    let accX, accY, accZ: Double
    
    //gefilterte Beschleunigungsdaten
    let accX_filt, accY_filt, accZ_filt: Double
    
    // Eulerwinkel integriert
    let roll_int, pitch_int, yaw_int: Double
    
    // Eulerwinkel berechnet (aus Gravitation/Magnetfeld)
    let roll_calc, pitch_calc, yaw_calc: Double
    
    // Eulerwinkel bereinigt (nach Komplementärfilter)
    let roll_clean, pitch_clean, yaw_clean: Double
    
    // Geschwindigkeiten gefiltert
    let vx, vy, vz: Double  // Einzelkomponenten aus Beschleunigung
    
    //ungefilterte Geschwindigkeiten (was waere ohne Tiefpass aber mit Eulerwinkel etc.)
    let vx_ungefiltert, vy_ungefiltert, vz_ungefiltert: Double
    
    //GNSS-Geschwindigkeit
    let gpsGeschwindigkeit: Double
    
}




//-----------------------------------------------------------------------------------------------------------------------------
// Klasse wird erstellt um GNSS/GPS-DAten auszulesen  >>> Laengen- & Breitengrad, m.ue.M und Geschwindigketi wird ausgelesen
//-----------------------------------------------------------------------------------------------------------------------------

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var onLocationUpdate: ((Double, Double, Double, Double) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            onLocationUpdate?(location.coordinate.latitude, location.coordinate.longitude, location.altitude, location.speed)
        }
    }
}


//-----------------------------------------------------------------------------------------------------------------------------
// ContentView wird erstellt >> interface und alle berechnungen
//-----------------------------------------------------------------------------------------------------------------------------

struct ContentView: View {
    
    //-----------------------------------------------------------------------------------------------------------------------------
    // Variabeln:
    //-----------------------------------------------------------------------------------------------------------------------------
    
    
    // Variabeln fuer UI:
    
    @State private var visibleButton = true
    @State private var showMenu = false
    @State private var showUI = false
    @State private var StartStopp = false       //fuer starten und stoppen der APp
    @State private var totalreset = false       //Alles reseten oder nur Daten zur Beschleunigung und Orientation den iPhones
    
    
    
    //-----------------------------------------------------------------------------------------------------------------------------
    // Variebaln fuer Beschleunigunssensor und deren berechnungen
    //-----------------------------------------------------------------------------------------------------------------------------
    
    let manager = CMMotionManager()
    
    // Rohwert der BEschleunigung
    @State private var accX = 0.00
    @State private var accY = 0.00
    @State private var accZ = 0.00
    @State private var acc_betrag = 0.00
    
    // ungefilterter aber gedrehter Wert der Beschleunigung
    @State private var xWelt_ungefiltert = 0.00
    @State private var yWelt_ungefiltert = 0.00
    @State private var zWelt_ungefiltert = 0.00
    
    // Gefilterter und gedrehter Wert der Beschleunigung
    @State private var xWelt = 0.00
    @State private var yWelt = 0.00
    @State private var zWelt = 0.00
    
    // Reine Erdbeschneunigung wird ausgelesen
    @State private var gx = 0.00
    @State private var gy = 0.00
    @State private var gz = 0.00
    
    // Magnetfeld wird ausgelesen
    @State private var magnetfeld = 0.00
    @State private var magX = 0.00
    @State private var magY = 0.00
    @State private var magZ = 0.00
    
    //-----------------------------------------------------------------------------------------------------------------------------
    // Variebeln zu den Eulerwinkeln
    //-----------------------------------------------------------------------------------------------------------------------------
    
    // Winkelgeschwindigkeit in rad/s vom Gyrometer ausgelesen
    @State private var rollX = 0.00
    @State private var pitchY = 0.00
    @State private var yawZ = 0.00
    
    // Rotationsmatrize zur Drehung der Beschleunigunsvektoren
    @State var m = CMRotationMatrix( m11: 1.0, m12: 0.0, m13: 0.0,
                                     m21: 0.0, m22: 1.0, m23: 0.0,
                                     m31: 0.0, m32: 0.0, m33: 1.0 )
    
    // Eulerwinkel in rad integriert aus den Winkelgeshwindigkeiten
    @State var roll = 0.00
    @State var pitch = 0.00
    @State var yaw = 0.00
    
    //-----------------------------------------------------------------------------------------------------------------------------
    // Komplementaerfilter: Filter zur bereinigung der integrierten Eulerwinkel
    //-----------------------------------------------------------------------------------------------------------------------------
    // zur Bereinigung der Eulerwinkel:
    
    @State private var defEul = 0.00
    @State private var roll_Offset = 0.00
    @State private var pitch_Offset = 0.00
    @State private var yaw_Offset = 0.00
    @State private var trustMag = true
    @State private var hx = 0.00
    @State private var hy = 0.00
    
    // Ableitungen der Eulerwinkel
    
    @State private var roll_dot = 0.00
    @State private var pitch_dot = 0.00
    @State private var yaw_dot = 0.00

    // Berechnete Eulerwinkel aus Sensorfusion
    @State private var rollG = 0.00
    @State private var pitchG = 0.00
    @State private var yawMag = 0.00
    
    // Drift der Eulerwinkel
    @State private var roll_drift = 0.00
    @State private var pitch_drift = 0.00
    @State private var yaw_drift = 0.00
    
    //Variabeln zum vergleich mit den Ungefilterten Daten
    
    //Ableitungen der Eulerwinkel
    @State private var roll_dot_u = 0.00
    @State private var pitch_dot_u = 0.00
    @State private var yaw_dot_u = 0.00
    
    //Ungefilterte driftende Eulerwinkel:
    @State var roll_u = 0.00
    @State var pitch_u = 0.00
    @State var yaw_u = 0.00
    
    
    //-----------------------------------------------------------------------------------------------------------------------------
    // Tiefpassfilter: schaetzung des Sensoroffsets der Beschleunigunssensoren
    //-----------------------------------------------------------------------------------------------------------------------------
    
    // Offset der Beschleunigung
    @State var a_offset_x: Double = 0.00
    @State var a_offset_y: Double = 0.00
    @State var a_offset_z: Double = 0.00
    
    // Bereinigte Beschleunigung
    @State var accX_real = 0.00
    @State var accY_real = 0.00
    @State var accZ_real = 0.00
    
    //adapriver Tiefpass
    @State private var accX_filt = 0.00
    @State private var accY_filt = 0.00
    @State private var accZ_filt = 0.00
    
    //-----------------------------------------------------------------------------------------------------------------------------
    // Variebeln fuer die Geschwindigkeit integriert aus der gemessenen Beschleunigung
    //-----------------------------------------------------------------------------------------------------------------------------
    
    @State var Vx = 0.00
    @State var Vy = 0.00
    @State var Vz = 0.00
    @State var Vgesammt = 0.00
    
    //ungefilterte Geschwindigkeiten:
    
    @State private var Vx_ungefiltert = 0.00
    @State private var Vy_ungefiltert = 0.00
    @State private var Vz_ungefiltert = 0.00
    
    @State var timer: Timer?
    
    //-----------------------------------------------------------------------------------------------------------------------------
    // Speichern der ausgelesenen Daten
    //-----------------------------------------------------------------------------------------------------------------------------
    
    // Liste zum speichern
    @State private var beschleunigungMessungen: [BeschleunigungMessung] = []
    
    
    
    //-----------------------------------------------------------------------------------------------------------------------------
    // GNSS(GPS)-Variabeln:
    //-----------------------------------------------------------------------------------------------------------------------------
    
    
    @State private var locationManager = CLLocationManager()
    @State private var locationDelegate = LocationDelegate()
    @State private var BreitenGrad = 0.00
    @State private var RadiantBreitenGrad = 0.00
    @State private var LaengenGrad = 0.00
    @State private var altBreitenGrad = 0.00
    @State private var altLaengenGrad = 0.00
    @State private var Location = false
    
    // Bewegun zwischen zwei Messungen
    @State private var DeltaBG = 0.00
    @State private var DeltaLG = 0.00
    @State private var MeterBewegungBG = 0.00
    @State private var MeterBewegungLG = 0.00
    
    // Hoehe
    @State private var hoehe = 0.00 // in m.ü.M
    @State private var althoehe = 0.00 // in m.ü.M
    @State private var DeltaHoehe = 0.00
    
    // Gesammt Bewegung
    @State private var DeltaBewegung = 0.00
    @State private var gesammtBewegung = 0.00
    
    // Geschwindigkeit
    @State private var DurchschnittGeschwindigkeitGPS = 0.00
    @State private var MomentanGeschwindigkeitGPS = 0.00
    @State private var MomentanGeschwindigkeitGPS_raw = 0.00
    @State private var MaxGeschwindigkeit = 0.00
    @State private var Startzeit: Date = .now
    
    
    @State private var einmalig = 0         // GPS wird in ersten par milisekunden nich nicht zur Distanzmessung benutzt, ausserdem wird die Distanzessung ungenauer wenn sie mit einer Frequenz von 100hzausgefuehrt wird -> Sensorrauschen addiert sich schneller auf
    
    //-----------------------------------------------------------------------------------------------------------------------------
    //Variabeln zur Karte/Apple Maps: aus Quelle: https://bugfender.com/blog/mapkit-swiftui/
    //-----------------------------------------------------------------------------------------------------------------------------
    
    @State var position = MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0.00, longitude: 0.00), span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)))
    @State var userLocation: CLLocationCoordinate2D?
    
    
    
    
    
    //-----------------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------------------------
    //UserInterface: >>>>
    //-----------------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------------------------
    
    
    var body: some View {
        
        
        ZStack {
            
            //-----------------------------------------------------------------------------------------------------------------------------
            // Startbildschirm
            //-----------------------------------------------------------------------------------------------------------------------------
            
            if showUI == false {
                if visibleButton == true {
                    Text("Tippe um zu starten")
                        .font(.title)
                        .bold()
                }
            }
            
            //-----------------------------------------------------------------------------------------------------------------------------
            //KArte/Apple Maps wird angezeigt
            //-----------------------------------------------------------------------------------------------------------------------------
            
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
                
                //-------------------------------------------------------------------------------------------------------------------------
                // Buttons und funktionen des UI
                //-------------------------------------------------------------------------------------------------------------------------
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        
                        //-----------------------------------------------------------------------------------------------------------------
                        // Daten werden ausgegeben
                        //-----------------------------------------------------------------------------------------------------------------
                        
                        HStack {        //nebeneinander
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
                        
                        //-----------------------------------------------------------------------------------------------------------------
                        // Start-Stopp-Button >> um Messungen zu starten und zu stoppen
                        //-----------------------------------------------------------------------------------------------------------------
                        
                        Button {
                            StartStopp.toggle()
                            
                            if StartStopp == false {
                                //Siehe in change of ->>
                            }
                            
                            if StartStopp == true {
                                totalreset = false
                                resetMessung()
                                
                            }
                            
                        } label: {
                            
                            Image(systemName: StartStopp ? "stop.circle" : "play.circle")           // Passendes Bild wird gezeigt >> aus SF Symbols Beta
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
                
                //-----------------------------------------------------------------------------------------------------------------
                // Menu fuer zusaetzliche Funktionen wie export der ausgelesenen und verarbeiteten Daten
                //-----------------------------------------------------------------------------------------------------------------
                
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 10) {
                            Button {
                                withAnimation {
                                    showMenu.toggle()
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")      //Bild von Swift gegeben
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.9))
                                    .clipShape(Circle())
                            }
                            
                            if showMenu {
                                VStack(alignment: .trailing, spacing: 10) {
                                    Button("Reset") {
                                        totalreset = true       //alles wird resetet auch messung und GPS
                                        resetMessung()
                                    }
                                    .padding(8)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 3)
                                    
                                    Button("Daten exportieren") {       //Button fuer den Export der Daten
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
        
        //-----------------------------------------------------------------------------------------------------------------
        // Beim ersten Tippen auf den Startbildschirm: >>>>>
        //-----------------------------------------------------------------------------------------------------------------
        
        .onTapGesture {                                         //App wird gestartet beim tippen
            if showUI == false && visibleButton == true {
                visibleButton = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {     //0.5 sek Delay einbauen >> sieht besser aus
                    showUI = true
                 
                    // Daten fuer GPS werden ausgelesen (Updates etwa mit Frequenz 1Hz)
                    locationDelegate.onLocationUpdate = { lat, lon, alt, speed in               // GPS komponente zuweisen(breitengrad, laengengrad, m.ue.M, Geschwindigkeit)
                        BreitenGrad = lat
                        LaengenGrad = lon
                        hoehe = alt
                        Maps()      //Laengen und Breitengrad fuer Karte wird hier ausgelesen
                        MomentanGeschwindigkeitGPS_raw = speed
                        userLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)    //Standort auf der Karte
                    }
                    
                    locationManager.delegate = locationDelegate
                    locationManager.desiredAccuracy = kCLLocationAccuracyBest
                    locationManager.requestWhenInUseAuthorization()
                    locationManager.startUpdatingLocation()
                }
            }
        }
        
        .onAppear {                     //Was Passieren soll wenn App gestartet wird -- nichts
        }
        
        //-----------------------------------------------------------------------------------------------------------------
        // Start-Stopp-Button >>> was Passiert >>>
        //-----------------------------------------------------------------------------------------------------------------
        
        .onChange(of: StartStopp) {
            if StartStopp == true {
                startMessung()
                
                //App lauft auch im Hintergrund weiter
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.pausesLocationUpdatesAutomatically = false
            }
            
            if StartStopp == false {
                manager.stopDeviceMotionUpdates()       //Beschleunigungsmessungen hoehren auf
                
            }

            
            
            
        }
        
        //-----------------------------------------------------------------------------------------------------------------
        //App lauft beim schliessen im Hinterdrung weiter  ->> siehe Signing & Capibilities unter AppName -- Dort mussten neue Einstellungen gemacht werden damit sie im Hintergrund laufen kann
        //-----------------------------------------------------------------------------------------------------------------
        
        .onDisappear {      //Wenn App nicht mehr offen ist >> App lauft auch im Hintergrund
            speichernBeschleunigungsDaten()
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    //-----------------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------------------------
    //Funktionen: Karte, speichern der Daten, auslesen der Sensoren & Filterung der Sensordaten & GNSS-berechnengen, Matrizenberechnungen, Reset und Stopp der Messung
    //-----------------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------------------------
    
    
    
    //-----------------------------------------------------------------------------------------------------------------------------
    //Funktion: AppleMaps Karte
    //-----------------------------------------------------------------------------------------------------------------------------
    
    
    
    private func Maps() {    //Funktion um Daten zu akktualisieren          Quelle: https://bugfender.com/blog/mapkit-swiftui/ Bemerkung: nicht Eins zu Eins jedoch wurden Elemente uebernommen
        position = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: BreitenGrad, longitude: LaengenGrad),      //Position
                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)))               //Massstab wie weit soll standartmaessig hineingezoomt werden
    }
    
    
    
    
    
    //-----------------------------------------------------------------------------------------------------------------------------
    //Funktion zum speichern der Daten in einer CSV-Datei
    //-----------------------------------------------------------------------------------------------------------------------------
    
    
    private func speichernBeschleunigungsDaten() {              // Grossteile von ChatGPT uebernommen, siehe schriftliche Arbeit
        let fileManager = FileManager.default
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("beschleunigung_messungen.csv")
        let header = "Timestamp,accX,accY,accZ,accX_gefiltert,accY_gefiltert,accZ_gefiltert,Roll_Integriert,Pitch_Integriert,Yaw_Integriert,Roll_Berechnet,Pitch_Berechnet,Yaw_Berechnet,Roll_Bereinigt,Pitch_Bereinigt,Yaw_Bereinigt,Vx,Vy,Vz,Vx_ungefiltert,Vy_ungefiltert,Vz_ungefiltert,V_GPS\n"
        
            var csvText = header
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "SSS"
            
            for messung in beschleunigungMessungen {
                let timestamp = dateFormatter.string(from: messung.timestamp)
                let line = "\(timestamp)," +
                "\(messung.accX),\(messung.accY),\(messung.accZ)," +
                "\(messung.accX_filt),\(messung.accY_filt),\(messung.accZ_filt)," +
                "\(messung.roll_int),\(messung.pitch_int),\(messung.yaw_int)," +
                "\(messung.roll_calc),\(messung.pitch_calc),\(messung.yaw_calc)," +
                "\(messung.roll_clean),\(messung.pitch_clean),\(messung.yaw_clean)," +
                "\(messung.vx),\(messung.vy),\(messung.vz)," +
                "\(messung.vx_ungefiltert),\(messung.vy_ungefiltert),\(messung.vz_ungefiltert),\(messung.gpsGeschwindigkeit)\n"
                csvText.append(line)
        }
        do {
            try csvText.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Fehler beim speichern")
        }
    }
    
    private func teileDatei() {             //Ebenfalls aus teile aus ChatGPT uebernommen
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
    
    
    
    
    
    
    //-----------------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------------------------
    //Funktion: Daten werden ausgelesen, bereinigt und integriert
    //-----------------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------------------------
    
    func startMessung() {
        
        //Sensoren pruefen
        guard manager.isDeviceMotionAvailable else {
            print("Acc-Sensor geht nicht")
            return
        }
        
        // Intervall
        manager.deviceMotionUpdateInterval = 0.01
        
        
        // Messung
        manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { motion, error in
            guard let motion = motion else { return }       // nur Wenn Daten Ausgelesen werden koennen Quelle: https://www.hackingwithswift.com/quick-start/understanding-swift/when-to-use-guard-let-rather-than-if-let
            
            guard self.StartStopp else { return }   //Funktion funktioniert nur wenn Start button gedrueckt ist Quelle: https://www.hackingwithswift.com/quick-start/understanding-swift/when-to-use-guard-let-rather-than-if-let
            
            //Beschleunigungsdaten in Einheit g, aber bereits ohne g werden ausgelesen
            accX = motion.userAcceleration.x
            accY = motion.userAcceleration.y
            accZ = motion.userAcceleration.z
            
            acc_betrag = sqrt(accX*accX + accY*accY + accZ*accZ)
            
            
            //rohes g wird ausgelesen
            gx = motion.gravity.x
            gy = motion.gravity.y
            gz = motion.gravity.z
            
            
            //Magnetfeld wird ausgelesen um Magnetischen Nordpol zu bestimmen
            magX = motion.magneticField.field.x
            magY = motion.magneticField.field.y
            magZ = motion.magneticField.field.z
            
            magnetfeld = sqrt(magX*magX + magY*magY + magZ*magZ)        //Betrag des MAgnetfeldes um zu pruefen ob es ungestoert ist
            
            
            //Winkelgeschwindigkeit in rad/s ---- Achtung das sind nicht die Eulerwinkel heissen aber so der Logik halber
            rollX = motion.rotationRate.x
            pitchY = motion.rotationRate.y
            yawZ = motion.rotationRate.z
            
            
            
            //-----------------------------------------------------------------------------------------------------------------------------
            // Berechnungen: Filter und Vektortransvormation
            //-----------------------------------------------------------------------------------------------------------------------------
            //-----------------------------------------------------------------------------------------------------------------------------
            // Tiefpassfilter erster Ordunung (im Ruhezustand thr < 0.01): Offset wird geschaetzt und wegerechnet
            //-----------------------------------------------------------------------------------------------------------------------------
            
            
            // Variabeln:
            
            let alpha_offset = 0.01     //Vergessensfaktor fuer offset schaetzung
            let remove_offset = 1       // 0 - Offset nicht wegrechnen 1 - Offset wegrechnen (zum ausprobieren)
            let thr_offset = 0.015      // Grenzwert in g  >> soll sich in der Ruhelage befinden
            let delta_t = 0.01          //100HZ
            
            // Offset schätzen (wenn das iPhone sich praktisch in der Ruhelage befindet):
            
            if abs(accX) < thr_offset {
                a_offset_x = (1 - alpha_offset) * accX + alpha_offset * a_offset_x
            }
            if abs(accY) < thr_offset {
                a_offset_y = (1 - alpha_offset) * accY + alpha_offset * a_offset_y
            }
            if abs(accZ) < thr_offset {
                a_offset_z = (1 - alpha_offset) * accZ + alpha_offset * a_offset_z
            }
            
            // Offset wegrechnen
            if remove_offset == 1 {
                accX_real = accX - a_offset_x
                accY_real = accY - a_offset_y
                accZ_real = accZ - a_offset_z
            }
            
            //-----------------------------------------------------------------------------------------------------------------------------
            // adaptiver Tiefpass: Sensorrauschen verringern
            //-----------------------------------------------------------------------------------------------------------------------------
            
            let betaMin = 0.0      // schwache Filterung, alles wird durchgelassen
            let betaMax = 0.7       // starke Filterung,
            // mit beiden wurde experimentell gespielt mit diesen funktionierte es am besten
            
            let acc_abs = sqrt( accX_real * accX_real + accY_real * accY_real + accZ_real * accZ_real ) // Betrag der BEschleunigung
            
            let beta = betaMin + (betaMax - betaMin) * exp(-10.0 * acc_abs)        // je nach beschleunigung anderes Beta -- adaptiv an Beschleunigung
            
            accX_filt = beta * accX_filt + (1 - beta) * accX_real
            accY_filt = beta * accY_filt + (1 - beta) * accY_real
            accZ_filt = beta * accZ_filt + (1 - beta) * accZ_real
            
            
            
            
            
            //-----------------------------------------------------------------------------------------------------------------------------
            //Komplementaerfilter:
            //-----------------------------------------------------------------------------------------------------------------------------
            //QUelle1 fuer die berechung der Ableitungen der Eulerwinkel: https://www.wikiwand.com/de/articles/Eulersche_Winkel
            //Quelle2 fuer die berechnung der Eulerwinkel aus g und MAgnetfeld: https://www.st.com/resource/en/design_tip/dt0058-computing-tilt-measurement-and-tiltcompensated-ecompass-stmicroelectronics.pdf
            //>>>>>> DAbei muss beachtete werdebn das die Eulerwinkel leicht anders ausgerichtet sind in iOS
            //-----------------------------------------------------------------------------------------------------------------------------
            
            
            //Berechnung der Ableitungen der Eulerwinkel mit den bereinigten Eulerwinkeln roll, pitch, yaw (siehe Quelle 1)
            roll_dot = rollX + sin(roll) * tan(pitch) * pitchY + cos(roll) * tan(pitch) * yawZ
            pitch_dot = cos(roll) * pitchY - sin(roll) * yawZ
            yaw_dot = sin(roll) / cos(pitch) * pitchY + cos(roll) / cos(pitch) * yawZ
            
            //integration mit der Zeit der Ableitungen --> Eulerwinkel
            roll = roll + delta_t * roll_dot
            pitch = pitch + delta_t * pitch_dot
            yaw = yaw + delta_t * yaw_dot
            
            
            
            //Berechnung der Ableitungen der Eulerwinkel ohne die Bereinigten Eulerwinkel (zum Vergleich) (Quelle 1)
            roll_dot_u = rollX + sin(roll_u) * tan(pitch_u) * pitchY + cos(roll_u) * tan(pitch_u) * yawZ
            pitch_dot_u = cos(roll_u) * pitchY - sin(roll_u) * yawZ
            yaw_dot_u = sin(roll_u) / cos(pitch) * pitchY + cos(roll_u) / cos(pitch_u) * yawZ
            
            
            //integration mit der Zeit der Ableitungen --> Eulerwinkel aber mit Drift zum Vergleich mit den obigen
            roll_u = roll_u + delta_t * roll_dot_u
            pitch_u = pitch_u + delta_t * pitch_dot_u
            yaw_u = yaw_u + delta_t * yaw_dot_u
            
            
            
            
            //Orientierung im Raum mit Sensorfusion bstimmen um berechnete Eulerwinkel auzupassen an diejenige die integriert wurden:
            
            if defEul == 0 && abs(magnetfeld) < 55 {    //Yaw wird nur korrigiert wenn Magnetfeld ungestoerrt ist
                
                hx = magX * cos(pitch) + magZ * sin(pitch)  //Nach norden zeigende Komponente
                hy = magX * sin(pitch) * sin(roll) + magY * cos(roll) - magZ * sin(pitch) * cos(roll)   //nach osten zeigende Komponente
                
                yaw_Offset = atan2(-hy, hx)
                trustMag = true     //Dem Magnetfeld wird vertraut solange es ungestoert bleibt
                
            }
            else if defEul == 0 && abs(magnetfeld) > 55 {
                trustMag = false        //Dem Magnetfeld wird fuer die gesammte Messung nicht vertraut, weil der anfangswert gebraucht wird fuer weitere Berechnungen
            }
            
            if defEul == 0 {        //Handy am anfang in Ruhelage --> g ist ungestoert wodrurch praezise roll und pitch berechnet werden koennen
                roll_Offset = atan2(-gy, -gz)
                pitch_Offset = atan2(gx, sqrt(gy*gy + gz*gz))
                
                defEul = 1
            }
            
            
            
            
            //Driften vermeiden:
            var alpha = 0.01            //Wie stark berechnete Eulerwinkel gewertet werden, alpha wird angepasst an die staerke der Beschleunigung, weil hohe Beschleunigung zu ungenaueren Gravitationsdaten fuehrt
            
            alpha = alpha * exp(-30.0 * acc_betrag)    //Staerte wird kontinuierlich angepasst bei acc = 0 ist alpha 0.01
            
            rollG = atan2(-gy, -gz)
            pitchG = atan2(gx, sqrt(gy*gy + gz*gz))
            
            if abs(magnetfeld) < 55 && trustMag == true {            //die Korrektur mit dem Magnetfeld wird nur benutzt wenn Magnetfeld ungestoert ist und auch am anfang ungestoert war
                
                hx = magX * cos(pitchG) + magZ * sin(pitchG)      //Nach norden zeigende Komponente

                hy = magX * sin(pitchG) * sin(rollG) + magY * cos(rollG) - magZ * sin(pitchG) * cos(rollG)   //nach Osten zeigende Komponente
                
                yawMag = atan2(-hy, hx)
                
            } else {
                yawMag = yaw
            }
            
            // Berechnete Roll Pitch Yaw richtig "drehen" damit sie auch im Geraetekoorinadteszstem sind
            rollG = rollG - roll_Offset
            pitchG = pitchG - pitch_Offset
            yawMag = yawMag - yaw_Offset        //Offset gleich Null wenn Magnetfeld nicht verwertbar ist
            
            
            //Filter anwenden mit gewichtungsfaktor alpha
            roll = roll * (1-alpha) + rollG * alpha
            pitch = pitch * (1-alpha) + pitchG * alpha
            yaw = yaw * (1-alpha) + yawMag * alpha
            

            
            
            
            //-----------------------------------------------------------------------------------------------------------------------------
            //Transforamtion der Beschleunigungsvektoren und deren zeitliche integration      >>>> Geschwindigkeitsberechnung
            //-----------------------------------------------------------------------------------------------------------------------------
            
            let m = eulerToRotationMatrix(roll: roll, pitch: pitch, yaw: yaw)       //Eulerwinkel in Drehmatrize (siehe Funktion)
            
            
            // Beschleunigung im Weltkoordinatensistem:(mit Drehmatrix gedreht)
            xWelt = m.m11 * accX_filt + m.m12 * accY_filt + m.m13 * accZ_filt
            yWelt = m.m21 * accX_filt + m.m22 * accY_filt + m.m23 * accZ_filt
            zWelt = m.m31 * accX_filt + m.m32 * accY_filt + m.m33 * accZ_filt
            
            // INtegration: Geschwindigkeiten in km/h
            
            Vx = Vx + delta_t * xWelt * 9.81 * 3.6
            Vy = Vy + delta_t * yWelt * 9.81 * 3.6
            Vz = Vz + delta_t * zWelt * 9.81 * 3.6
        
            
            Vgesammt = sqrt(Vx * Vx + Vy * Vy + Vz * Vz)       // Geschwindigkeit in km/h
            
            
            //Verarbeitung der ungefiilterten Beschleunigungen:
            
            xWelt_ungefiltert = m.m11 * accX + m.m12 * accY + m.m13 * accZ
            yWelt_ungefiltert = m.m21 * accX + m.m22 * accY + m.m23 * accZ
            zWelt_ungefiltert = m.m31 * accX + m.m32 * accY + m.m33 * accZ
            
            Vx_ungefiltert = Vx_ungefiltert + delta_t * xWelt_ungefiltert * 9.81 * 3.6
            Vy_ungefiltert = Vy_ungefiltert + delta_t * yWelt_ungefiltert * 9.81 * 3.6
            Vz_ungefiltert = Vz_ungefiltert + delta_t * zWelt_ungefiltert * 9.81 * 3.6
            
            
            

            //-----------------------------------------------------------------------------------------------------------------------------
            //GNSS(GPS)-Empfaenger: GNSS(GPS)-Daten werden verwertet
            //-----------------------------------------------------------------------------------------------------------------------------
            //GPS geschwindigkeit wird im schnelleren Intervall Bearbeitet weil es sonst asynroch zur Beschleunigungsmessung und Ausgabe waere, so koennten sie nicht in derselben Liste gespeichert werden
            //Auch die anderen Werte wie distanz und postion werden hier berechnet

            

            //-----------------------------------------------------------------------------------------------------------------------------
            //Geschwindigkeit
            //-----------------------------------------------------------------------------------------------------------------------------
            
            if MomentanGeschwindigkeitGPS_raw <= 0 {                //GNSS-Epfaenger hat teilweise leicht negative Werte ausgegeben werden so entfernt
                MomentanGeschwindigkeitGPS = 0.00
            } else {
                MomentanGeschwindigkeitGPS = MomentanGeschwindigkeitGPS_raw * 3.6           //in km/h
            }

            if MomentanGeschwindigkeitGPS > MaxGeschwindigkeit {                           //Maximalgeschwindigkeit wird gespeichert
                MaxGeschwindigkeit = MomentanGeschwindigkeitGPS
            }


            
            //-----------------------------------------------------------------------------------------------------------------------------
            //Distanzberechnung weil Gps-Werte Hoechstens in einer Frequenz von 10Hz ausgeegeben werden (normalerweise etwa 1Hz) addiert sich sensorrauschen kaum auf - um optimale Resultate zu erhlaten wird GPS trotzdem nur jede s aktualisiert
            //-----------------------------------------------------------------------------------------------------------------------------

            if einmalig == 0 {                          // altBreitenGrad definieren - erster durchgang misst nichts
                altBreitenGrad = BreitenGrad
                altLaengenGrad = LaengenGrad
                althoehe = hoehe
            }

            if einmalig == 1 {                          //Starzeit wird Definiert
                Startzeit = Date()
            }

            
            //Distanzberechnungen sollten jede Sekunde Stadtfinden -> Parallel zur Akktualisation der Daten mit 1HZ
            einmalig = einmalig + 1

            if einmalig >= 102 {                        //jede Sekunde wird Distanz akktualisiert
                einmalig = 2
                
                
                //Distanzberechnung:
                
                DeltaBG = BreitenGrad - altBreitenGrad      //111133m pro Breitengrad veränderung
                DeltaLG = LaengenGrad - altLaengenGrad      //111319m * cos(BreitenGrad) pro Längengrad veränderung
                DeltaHoehe = hoehe - althoehe               //bereits in Metern gegeben
                
                //Bewegung in Metern
                RadiantBreitenGrad = BreitenGrad*Double.pi/180      //wird in Radiant umgerechnet damit cos funktion benutzt werden kann
                
                MeterBewegungBG = abs(DeltaBG) * 111133                                     //Distanz in m entlang des Breitengrads
                MeterBewegungLG = abs(DeltaLG) * 111319 * cos(RadiantBreitenGrad)           //Distanz in m entlang des Laengengrads
                
                //altxxx wird neu definierte fuer naechsten Durchgang
                altBreitenGrad = BreitenGrad
                altLaengenGrad = LaengenGrad
                althoehe = hoehe
                
                //Strecke in Metern:
                
                DeltaBewegung = sqrt((MeterBewegungBG * MeterBewegungBG) + (MeterBewegungLG * MeterBewegungLG) + (DeltaHoehe * DeltaHoehe)) // gesammte Bewegung
                gesammtBewegung = gesammtBewegung + DeltaBewegung       // gesammt Strecke
                
                DurchschnittGeschwindigkeitGPS = gesammtBewegung / (Date().timeIntervalSince(Startzeit))    //Fuer durchschnittsgeschwindigkeit wird Distanz genommen

            }

            
            
            
            //-----------------------------------------------------------------------------------------------------------------------------
            //Daten speichern in CSV-Datei
            //-----------------------------------------------------------------------------------------------------------------------------
            
            //Daten muessen nochmal ungespeichert werden >> ansonsten compilerfehler
             
            let axx = xWelt_ungefiltert
            let ayy = yWelt_ungefiltert
            let azz = zWelt_ungefiltert
            
            let axr = xWelt
            let ayr = yWelt
            let azr = zWelt
            
            let rrr = roll_u
            let ppp = pitch_u
            let yyy = yaw_u
            
            let rrc = rollG
            let ppc = pitchG
            let yyc = yawMag
            
            let rcl = roll
            let pcl = pitch
            let ycl = yaw
            
            let vxx = Vx
            let vyy = Vy
            let vzz = Vz
            
            let vxu = Vx_ungefiltert
            let vyu = Vy_ungefiltert
            let vzu = Vz_ungefiltert
            
            let mgs = MomentanGeschwindigkeitGPS
            
            
            
            //Speichern in einer Liste:
            
            let neueMessung = BeschleunigungMessung(
                
                //Zeit
                timestamp: Date(),
                
                //Rohe Beschleunigung
                accX: axx,
                accY: ayy,
                accZ: azz,
                
                //gefilterte Beschleunigung
                accX_filt: axr,
                accY_filt: ayr,
                accZ_filt: azr,
                
                //ungefilterte Eulerwinkel
                roll_int: rrr,
                pitch_int: ppp,
                yaw_int: yyy,
                
                //berechnete Eulerwinkel
                roll_calc: rrc,
                pitch_calc: ppc,
                yaw_calc: yyc,
                
                //gefilterte Eulerwinkel
                roll_clean: rcl,
                pitch_clean: pcl,
                yaw_clean: ycl,
                
                //Geschwindigkeit integriete und GPS
                vx: vxx,
                vy: vyy,
                vz: vzz,
                
                //Geschwindigkeit ungefiltert zum vergleich
                vx_ungefiltert: vxu,
                vy_ungefiltert: vyu,
                vz_ungefiltert: vzu,
                
                //GPS/Geschwindigkeit
                gpsGeschwindigkeit: mgs
            )
            beschleunigungMessungen.append(neueMessung)
            speichernBeschleunigungsDaten()
            
            
            
        }
    }
    
    
    //-----------------------------------------------------------------------------------------------------------------------------
    //Funktion: Eulerwinkel zu Matrix
    //-----------------------------------------------------------------------------------------------------------------------------
    
    
    func eulerToRotationMatrix(roll: Double, pitch: Double, yaw: Double) -> CMRotationMatrix {          // aus Quelle: https://matheplanet.com/default3.html?call=viewtopic.php?topic=170601&ref=https%3A%2F%2Fwww.google.com%2F
        
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
    
    
    
    //-----------------------------------------------------------------------------------------------------------------------------
    //FUnktion: start- und Stoppbutton & Resetbutton funktion -> alles wird zuerueckgesetzt und Liste mit gespeicherten Daten wird geleehrt
    //-----------------------------------------------------------------------------------------------------------------------------
    
    func resetMessung() {                   //alles zuruecksetzten gps nicht immer
        
        // Beschleunigungsdaten zurücksetzen -- nicht wirkliche relevant, sollten sowieso null sein
        accX = 0.00
        accY = 0.00
        accZ = 0.00
        
        accX_real = 0.00
        accY_real = 0.00
        accZ_real = 0.00
        
        xWelt = 0.00
        yWelt = 0.00
        zWelt = 0.00
        
        // Geschwindigkeiten zurücksetzen
        Vx = 0.00
        Vy = 0.00
        Vz = 0.00
        Vgesammt = 0.00
        
        // Eulerwinkel zurücksetzen
        roll = 0.00
        pitch = 0.00
        yaw = 0.00
        
        // Offset zurücksetzen
        a_offset_x = 0.00
        a_offset_y = 0.00
        a_offset_z = 0.00
        
        // GPS-Daten zurücksetzen nur wenn reset gedrueckt wird
        if totalreset == true {
            gesammtBewegung = 0.00
            MaxGeschwindigkeit = 0.00
            DurchschnittGeschwindigkeitGPS = 0.00
            einmalig = 0
        }
       
        // Gespeicherte Messungen löschen (Liste wird geleert)
        beschleunigungMessungen.removeAll()
    }
}







#Preview {
    ContentView()
}























