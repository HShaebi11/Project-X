import SwiftUI
import PhotosUI
import AVFoundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct Capture: Identifiable, Codable {
    var id = UUID()
    var title: String
    var type: CaptureType
    var content: String
    var imageData: Data?
    var audioURL: URL?
    var date: Date
}

enum CaptureType: String, Codable {
    case text
    case photo
    case audio
}

struct CaptureView: View {
    @State private var captures: [Capture] = []
    @State private var showingAddCapture = false
    @State private var selectedType: CaptureType = .text
    @State private var searchText = ""
    
    var filteredCaptures: [Capture] {
        if searchText.isEmpty {
            return captures
        } else {
            return captures.filter { capture in
                capture.title.localizedCaseInsensitiveContains(searchText) ||
                capture.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredCaptures) { capture in
                    NavigationLink(destination: CaptureDetailView(capture: capture, onSave: { updatedCapture in
                        if let index = captures.firstIndex(where: { $0.id == updatedCapture.id }) {
                            captures[index] = updatedCapture
                            saveCaptures()
                        }
                    })) {
                        CaptureRowView(capture: capture)
                    }
                }
                .onDelete(perform: deleteCaptures)
            }
            .searchable(text: $searchText, prompt: "Search captures")
            .navigationTitle("Capture")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            selectedType = .text
                            showingAddCapture = true
                        }) {
                            Label("Text Note", systemImage: "text.bubble")
                        }
                        
                        Button(action: {
                            selectedType = .photo
                            showingAddCapture = true
                        }) {
                            Label("Photo", systemImage: "camera")
                        }
                        
                        Button(action: {
                            selectedType = .audio
                            showingAddCapture = true
                        }) {
                            Label("Audio Note", systemImage: "mic")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem {
                    Menu {
                        Button(action: {
                            selectedType = .text
                            showingAddCapture = true
                        }) {
                            Label("Text Note", systemImage: "text.bubble")
                        }
                        
                        Button(action: {
                            selectedType = .photo
                            showingAddCapture = true
                        }) {
                            Label("Photo", systemImage: "camera")
                        }
                        
                        Button(action: {
                            selectedType = .audio
                            showingAddCapture = true
                        }) {
                            Label("Audio Note", systemImage: "mic")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddCapture) {
                CaptureDetailView(capture: Capture(
                    title: "",
                    type: selectedType,
                    content: "",
                    date: Date()
                ), onSave: { newCapture in
                    captures.append(newCapture)
                    saveCaptures()
                })
            }
            .onAppear {
                loadCaptures()
            }
        }
    }
    
    private func deleteCaptures(at offsets: IndexSet) {
        captures.remove(atOffsets: offsets)
        saveCaptures()
    }
    
    private func saveCaptures() {
        if let encoded = try? JSONEncoder().encode(captures) {
            UserDefaults.standard.set(encoded, forKey: "Captures")
        }
    }
    
    private func loadCaptures() {
        if let data = UserDefaults.standard.data(forKey: "Captures"),
           let decoded = try? JSONDecoder().decode([Capture].self, from: data) {
            captures = decoded
        }
    }
}

struct CaptureRowView: View {
    let capture: Capture
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(capture.title)
                    .font(.headline)
                Text(capture.content)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                Text(capture.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var iconName: String {
        switch capture.type {
        case .text:
            return "text.bubble"
        case .photo:
            return "photo"
        case .audio:
            return "mic"
        }
    }
}

struct CaptureDetailView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (Capture) -> Void
    
    @State private var capture: Capture
    @State private var selectedImage: PhotosPickerItem?
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    
    init(capture: Capture, onSave: @escaping (Capture) -> Void) {
        _capture = State(initialValue: capture)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $capture.title)
                
                switch capture.type {
                case .text:
                    TextEditor(text: $capture.content)
                        .frame(minHeight: 200)
                    
                case .photo:
                    if let imageData = capture.imageData {
                        #if os(iOS)
                        if let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                        }
                        #else
                        if let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                        }
                        #endif
                    }
                    
                    PhotosPicker(selection: $selectedImage,
                               matching: .images) {
                        Label("Select Photo", systemImage: "photo")
                    }
                    
                case .audio:
                    if let audioURL = capture.audioURL {
                        Button(action: {
                            playAudio(url: audioURL)
                        }) {
                            Label("Play Recording", systemImage: "play.circle")
                        }
                    }
                    
                    Button(action: {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }) {
                        Label(isRecording ? "Stop Recording" : "Start Recording",
                              systemImage: isRecording ? "stop.circle" : "mic.circle")
                    }
                }
            }
            .navigationTitle("New Capture")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(capture)
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedImage) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        capture.imageData = data
                    }
                }
            }
        }
    }
    
    private func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            capture.audioURL = audioFilename
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    private func playAudio(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Could not play audio: \(error)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

#Preview {
    CaptureView()
} 