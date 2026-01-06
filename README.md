# Geschwindigkeitsbestimmung mit iPhone-Sensoren 

Diese iOS-App erfasst Bewegungs-, Orientierungs- und GPS-Daten eines iPhones in Echtzeit.  
Sie nutzt die internen Sensoren des Geräts und speichert alle Messwerte zur späteren Auswertung in einer CSV-Datei.

Die App wurde mit SwiftUI, CoreMotion, CoreLocation und MapKit entwickelt.

---

## Funktionen

Die App erfasst und verarbeitet folgende Daten:

Beschleunigung ohne Gravitation (x, y, z)  
Gravitationsvektor (x, y, z)  
Gyroskopdaten (Roll, Pitch, Yaw)  
Magnetfeld (x, y, z)  
GPS-Position, Geschwindigkeit und Höhe  

Zusätzlich werden folgende Werte berechnet:

Eulerwinkel (Roll, Pitch, Yaw)  
Geschwindigkeit aus Beschleunigungsintegration  
Momentan-, Durchschnitts- und Maximalgeschwindigkeit aus GPS  
Zurückgelegte Strecke in Metern  
Transformation der Beschleunigung in das Weltkoordinatensystem  

Alle Rohdaten werden während der Messung gespeichert.

---

## Sensorverarbeitung und Berechnung

Die Beschleunigungsdaten werden mit einem Tiefpassfilter von Offsets bereinigt.  
Die Winkelgeschwindigkeit wird integriert, um Eulerwinkel zu berechnen.  
Drift wird mithilfe des Gravitationsvektors und des Magnetfelds korrigiert.  
Die Beschleunigung wird über eine Rotationsmatrix in das Weltkoordinatensystem transformiert.  
Die Geschwindigkeit wird durch zeitliche Integration der Beschleunigung berechnet.  

GPS-Daten werden verwendet, um Geschwindigkeit und Strecke unabhängig von der Beschleunigung zu bestimmen.  
Die Distanzberechnung berücksichtigt die Erdkrümmung über den Breitengrad.

---

## Gespeicherte Daten (CSV)

Die Datei heißt:

beschleunigung_messungen.csv

Gespeicherte Spalten:

Timestamp (Millisekunden)  
Gyroskop Roll, Pitch, Yaw  
Beschleunigung x, y, z  
Gravitation x, y, z  
Magnetfeld x, y, z  
GPS-Geschwindigkeit in km/h  

Die Datei wird im Dokumentenverzeichnis der App gespeichert und kann exportiert werden.

---

## Bedienungsanleitung

App starten  
Einmal auf den Bildschirm tippen, um die Benutzeroberfläche zu öffnen  
Mit dem Play-Button die Messung starten  
Während der Messung werden Sensor- und GPS-Daten erfasst  
Mit dem Stop-Button die Messung beenden  

Über das Menü oben rechts kann:

Die Messung vollständig zurückgesetzt werden  
Die CSV-Datei exportiert und geteilt werden  

---

## Voraussetzungen

iPhone mit iOS 17 oder neuer  
Bewegungssensoren und GPS müssen verfügbar sein  
Standort- und Bewegungssensor-Berechtigungen müssen erlaubt werden  

---

## Apple Developer Account

Für die Entwicklung und Installation der App wird ein Apple Developer Account benötigt.

Ein kostenloser Apple-ID-Account reicht aus, um:

Die App in Xcode zu kompilieren  
Die App auf einem eigenen iPhone zu installieren  
Sensor- und GPS-Funktionen zu testen  

Einschränkungen des kostenlosen Accounts:

Die App ist nur auf eigenen Geräten lauffähig  
Das Zertifikat ist zeitlich begrenzt und muss regelmäßig erneuert werden  
Keine Veröffentlichung im App Store möglich  

Ein kostenpflichtiger Apple Developer Account (99 USD pro Jahr) wird benötigt, um:

Die App im App Store zu veröffentlichen  
TestFlight für externe Tester zu nutzen  
Langfristig gültige Zertifikate zu verwenden  
Erweiterte App-Dienste zu aktivieren  

---

## Ziel des Projekts

Analyse und Vergleich von GPS- und inertialer Bewegungserfassung  
Untersuchung von Sensorrauschen und Drift  
Grundlagen der Sensorfusion und Signalverarbeitung  
Export von Messdaten für externe Auswertung in Python, MATLAB oder Excel  

---

## Autor

Max Faller  

