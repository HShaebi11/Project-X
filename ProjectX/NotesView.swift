import SwiftUI

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
    var date: Date
}

struct NotesView: View {
    @State private var notes: [Note] = []
    @State private var showingAddNote = false
    @State private var searchText = ""
    
    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notes
        } else {
            return notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredNotes) { note in
                    NavigationLink(destination: NoteDetailView(note: note, onSave: { updatedNote in
                        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
                            notes[index] = updatedNote
                            saveNotes()
                        }
                    })) {
                        VStack(alignment: .leading) {
                            Text(note.title)
                                .font(.headline)
                            Text(note.content)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                            Text(note.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: deleteNotes)
            }
            .searchable(text: $searchText, prompt: "Search notes")
            .navigationTitle("Notes")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddNote = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem {
                    Button(action: {
                        showingAddNote = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddNote) {
                NoteDetailView(note: Note(title: "", content: "", date: Date()), onSave: { newNote in
                    notes.append(newNote)
                    saveNotes()
                })
            }
            .onAppear {
                loadNotes()
            }
        }
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        saveNotes()
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: "Notes")
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: "Notes"),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
    }
}

struct NoteDetailView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (Note) -> Void
    
    @State private var note: Note
    
    init(note: Note, onSave: @escaping (Note) -> Void) {
        _note = State(initialValue: note)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $note.title)
                TextEditor(text: $note.content)
                    .frame(minHeight: 200)
            }
            .navigationTitle(note.id == UUID() ? "New Note" : "Edit Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(note)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        NotesView()
    }
} 