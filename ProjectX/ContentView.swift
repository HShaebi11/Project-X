//
//  ContentView.swift
//  ProjectX
//
//  Created by Hamza Shaebi on 24/04/2025.
//

import SwiftUI

struct TodoItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool
    var date: Date
}

struct ContentView: View {
    @State private var todos: [TodoItem] = []
    @State private var newTodoTitle = ""
    @State private var showingAddTodo = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(todos) { todo in
                    TodoRowView(todo: todo) { updatedTodo in
                        if let index = todos.firstIndex(where: { $0.id == updatedTodo.id }) {
                            todos[index] = updatedTodo
                            saveTodos()
                        }
                    }
                }
                .onDelete(perform: deleteTodos)
            }
            .navigationTitle("Todo List")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTodo = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem {
                    Button(action: {
                        showingAddTodo = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddTodo) {
                AddTodoView { newTodo in
                    todos.append(newTodo)
                    saveTodos()
                }
            }
            .onAppear {
                loadTodos()
            }
        }
    }
    
    private func deleteTodos(at offsets: IndexSet) {
        todos.remove(atOffsets: offsets)
        saveTodos()
    }
    
    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: "Todos")
        }
    }
    
    private func loadTodos() {
        if let data = UserDefaults.standard.data(forKey: "Todos"),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todos = decoded
        }
    }
}

struct TodoRowView: View {
    let todo: TodoItem
    let onUpdate: (TodoItem) -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                var updatedTodo = todo
                updatedTodo.isCompleted.toggle()
                onUpdate(updatedTodo)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .gray : .primary)
                Text(todo.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct AddTodoView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (TodoItem) -> Void
    
    @State private var title = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Task Title", text: $title)
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newTodo = TodoItem(
                            title: title,
                            isCompleted: false,
                            date: Date()
                        )
                        onSave(newTodo)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
