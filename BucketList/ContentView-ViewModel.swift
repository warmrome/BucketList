//
//  ContentView-ViewModel.swift
//  BucketList
//
//  Created by Jameson Hurst on 1/26/22.
//

import Foundation
import LocalAuthentication
import MapKit


extension ContentView {
    @MainActor class ViewModel: ObservableObject {
        @Published var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 50, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 25))
        @Published private(set) var locations: [Location]
        @Published var selectedPlace: Location?
        
        @Published var isUnlocked = false
        
        @Published var authenticationError = "Unknown error"
        @Published var isShowingAuthenticationError = false
        
        let savePath = FileManager.documentsDirectory.appendingPathComponent("SavedPlaces")
        
        init() {
            do {
                let data = try Data(contentsOf: savePath)
                locations = try JSONDecoder().decode([Location].self, from: data)
            } catch {
                locations = []
            }
        }
        
        func addLocation() {
            let newLocation = Location(id: UUID(),
                name: "New location",
                description: "",
                latitude: mapRegion.center.latitude,
                longitude: mapRegion.center.longitude)
            locations.append(newLocation)
            save()
        }
        
        func authenticate() {
            let context = LAContext()
            var error: NSError?
            
            // check whether biometric authentication is possible
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                // it's possible, so go ahead and use it
                let reason = "Please authenticate yourself to unlock your places."
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    // authentication has now completed
                    Task { @MainActor in
                        if success {
                            self.isUnlocked = true
                        } else {
                            self.authenticationError = "There was a problem authenticating; please try again."
                            self.isShowingAuthenticationError = true
                        }
                    }
                }
            } else {
                // no biometrics
                authenticationError = "Sorry, your device does not support biometric authentication."
                isShowingAuthenticationError = true
            }
        }
        
        func save() {
            do {
                let data = try JSONEncoder().encode(locations)
                try data.write(to: savePath, options: [.atomic, .completeFileProtection])
            } catch {
                print("Unable to save data.")
            }
        }
        
        func update(location: Location) {
            guard let selectedPlace = selectedPlace else { return }
            
            if let index = locations.firstIndex(of: selectedPlace) {
                locations[index] = location
                save()
            }
        }
        
    }
}
