//
//  App_1.0
//
//  Created by Max Faller on 30.08.2025.
//
import MapKit
import SwiftUI

struct ContentView: View {
    
    @State private var Textfeld = false
    @State private var visibleButton = true
    var text = "Hallo"
    
    var body: some View {
 
        if visibleButton == true {
            Button {
                visibleButton = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Textfeld = true
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
        }
    }
}

#Preview {
    ContentView()
}
