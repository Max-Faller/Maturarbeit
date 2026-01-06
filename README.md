# Geschwindigkeitsbestimmung mit iPhone-Sensoren 

Diese iOS-App erfasst Bewegungs-, Orientierungs- und GPS-Daten eines iPhones in Echtzeit.  
Sie nutzt die internen Sensoren des Geräts und speichert alle Messwerte zur späteren Auswertung in einer CSV-Datei.

Die App wurde mit SwiftUI, CoreMotion, CoreLocation und MapKit entwickelt.

---

## Funktionen

Die App erfasst und verarbeitet Folgende Daten:

Beschleunigung ohne Gravitation (x, y, z)  
Gravitationsvektor (x, y, z)  
Gyroskopdaten (Roll, Pitch, Yaw)  
Magnetfeld (x, y, z)  
GPS-Position, Geschwindigkeit und Höhe  

Zusätzlich werden folgende Werte berechnet:

Eulerwinkel (Roll, Pitch und Yaw) der Orientation im Vergleich zu einem Globalen Koordinatensystem
Geschwindigkeit aus Beschleunigunsintegration  
Momentan-, Durchschnitts- und Maximalgeschwindigkeit aus GPS  
Zurückgelegte Strecke in Metern  
Transformation der Beschleunigung in ein Globales Koordinatensystem

Alle Rohdaten werden während der Messung gespeichert und können exportiert werden.

---

## Sensorverarbeitung und Berechnung

Die Beschleunigungsdaten werden mit einem Tiefpassfilter von Offsets bereinigt.  
Die Winkelgeschwindigkeit wird integriert, um Eulerwinkel zu berechnen.  
Drift wird mithilfe des Gravitationsvektors und des Magnetfelds korrigiert.  
Die Beschleunigung wird über eine Rotationsmatrix in ein Globales Koorindattensystem transformiert.  
Die Geschwindigkeit wird durch zeitliche Integration der Beschleunigung berechnet.  

GPS-Daten werden verwendet, um Geschwindigkeit und Strecke unabhängig von der Beschleunigung zu bestimmen.  
Die Distanzberechnung berücksichtigt die Erdkrümmung über den Breitengrad.

---

## Gespeicherte Daten im CSV-Format

Die Datei heißt:

beschleunigung_messungen.csv

Gespeicherte Spalten:

Timestamp (Millisekunden)  
Gyroskop Roll, Pitch, Yaw  
Beschleunigung x, y, z  
Gravitation x, y, z  
Magnetfeld x, y, z  
GNSS-Geschwindigkeit in km/h  

Die Datei kann in der Dateien App gefunden werden, wenn exportiert.

---

## Bedienungsanleitung

App starten  
Einmal auf den Bildschirm tippen, um die Benutzeroberfläche zu öffnen  
Mit dem Play-Button die Messung starten  
Während der Messung werden Sensor- und GPS-Daten erfasst und verarbeitet 
Mit dem Stop-Button die Messung beenden oder mit dem export-Button im Menu oben rechts im CSV-Format exporieren

---

## Voraussetzungen

iPhone mit iOS 17 oder neuer  
Bewegungssensoren und GPS müssen verfügbar sein  
Standort- und Bewegungssensor-Berechtigungen müssen erlaubt werden  

---

## Apple Developer Account

Für die Entwicklung und Installation der App wird ein Apple Developer Account benötigt.

---

## Ziel des Projekts

Analyse und Vergleich von GNSS- und sensorbasierter Geschwindigkeit

---

## Autor

Max Faller  

