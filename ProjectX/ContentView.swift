//
//  ContentView.swift
//  ProjectX
//
//  Created by Hamza Shaebi on 24/04/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(0)
            
            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(1)
            
            CaptureView()
                .tabItem {
                    Label("Capture", systemImage: "camera")
                }
                .tag(2)
            
            WhiteboardView()
                .tabItem {
                    Label("Whiteboard", systemImage: "pencil.and.ruler")
                }
                .tag(3)
        }
    }
}

struct CalendarView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Calendar")
                    .font(.largeTitle)
                    .bold()
                // Calendar implementation will go here
            }
            .navigationTitle("Calendar")
        }
    }
}

struct NotesView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Notes")
                    .font(.largeTitle)
                    .bold()
                // Notes implementation will go here
            }
            .navigationTitle("Notes")
        }
    }
}

struct CaptureView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Capture")
                    .font(.largeTitle)
                    .bold()
                // Capture implementation will go here
            }
            .navigationTitle("Capture")
        }
    }
}

struct WhiteboardView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Whiteboard")
                    .font(.largeTitle)
                    .bold()
                // Whiteboard implementation will go here
            }
            .navigationTitle("Whiteboard")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
