import SwiftUI
#if os(iOS)
import PencilKit
#else
import AppKit
#endif

struct Whiteboard: Identifiable, Codable {
    var id = UUID()
    var title: String
    var drawingData: Data
    var date: Date
}

struct WhiteboardView: View {
    @State private var whiteboards: [Whiteboard] = []
    @State private var showingAddWhiteboard = false
    @State private var searchText = ""
    
    var filteredWhiteboards: [Whiteboard] {
        if searchText.isEmpty {
            return whiteboards
        } else {
            return whiteboards.filter { whiteboard in
                whiteboard.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredWhiteboards) { whiteboard in
                    NavigationLink(destination: WhiteboardDetailView(whiteboard: whiteboard, onSave: { updatedWhiteboard in
                        if let index = whiteboards.firstIndex(where: { $0.id == updatedWhiteboard.id }) {
                            whiteboards[index] = updatedWhiteboard
                            saveWhiteboards()
                        }
                    })) {
                        WhiteboardRowView(whiteboard: whiteboard)
                    }
                }
                .onDelete(perform: deleteWhiteboards)
            }
            .searchable(text: $searchText, prompt: "Search whiteboards")
            .navigationTitle("Whiteboard")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddWhiteboard = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem {
                    Button(action: {
                        showingAddWhiteboard = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddWhiteboard) {
                WhiteboardDetailView(whiteboard: Whiteboard(
                    title: "New Whiteboard",
                    drawingData: Data(),
                    date: Date()
                ), onSave: { newWhiteboard in
                    whiteboards.append(newWhiteboard)
                    saveWhiteboards()
                })
            }
            .onAppear {
                loadWhiteboards()
            }
        }
    }
    
    private func deleteWhiteboards(at offsets: IndexSet) {
        whiteboards.remove(atOffsets: offsets)
        saveWhiteboards()
    }
    
    private func saveWhiteboards() {
        if let encoded = try? JSONEncoder().encode(whiteboards) {
            UserDefaults.standard.set(encoded, forKey: "Whiteboards")
        }
    }
    
    private func loadWhiteboards() {
        if let data = UserDefaults.standard.data(forKey: "Whiteboards"),
           let decoded = try? JSONDecoder().decode([Whiteboard].self, from: data) {
            whiteboards = decoded
        }
    }
}

struct WhiteboardRowView: View {
    let whiteboard: Whiteboard
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(whiteboard.title)
                .font(.headline)
            Text(whiteboard.date, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#if os(iOS)
struct WhiteboardDetailView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (Whiteboard) -> Void
    
    @State private var whiteboard: Whiteboard
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    
    init(whiteboard: Whiteboard, onSave: @escaping (Whiteboard) -> Void) {
        _whiteboard = State(initialValue: whiteboard)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Title", text: $whiteboard.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                CanvasView(canvasView: $canvasView, toolPicker: toolPicker)
                    .onAppear {
                        toolPicker.setVisible(true, forFirstResponder: canvasView)
                        canvasView.becomeFirstResponder()
                        
                        if let drawing = try? PKDrawing(data: whiteboard.drawingData) {
                            canvasView.drawing = drawing
                        }
                    }
            }
            .navigationTitle("Whiteboard")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        whiteboard.drawingData = canvasView.drawing.dataRepresentation()
                        onSave(whiteboard)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var toolPicker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 1)
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        
        init(_ parent: CanvasView) {
            self.parent = parent
        }
    }
}
#else
struct WhiteboardDetailView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (Whiteboard) -> Void
    
    @State private var whiteboard: Whiteboard
    
    init(whiteboard: Whiteboard, onSave: @escaping (Whiteboard) -> Void) {
        _whiteboard = State(initialValue: whiteboard)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Title", text: $whiteboard.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Text("Whiteboard drawing is not available on macOS")
                    .foregroundColor(.gray)
                    .padding()
            }
            .navigationTitle("Whiteboard")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(whiteboard)
                        dismiss()
                    }
                }
            }
        }
    }
}
#endif

#Preview {
    WhiteboardView()
} 