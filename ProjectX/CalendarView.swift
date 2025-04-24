import SwiftUI
import EventKit

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var events: [EKEvent] = []
    @State private var showingAddEvent = false
    
    private let eventStore = EKEventStore()
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                List {
                    ForEach(events, id: \.eventIdentifier) { event in
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.headline)
                            Text(event.startDate, style: .time)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddEvent = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem {
                    Button(action: {
                        showingAddEvent = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(eventStore: eventStore)
            }
            .onAppear {
                requestAccess()
            }
        }
    }
    
    private func requestAccess() {
        #if os(iOS)
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                loadEvents()
            }
        }
        #else
        eventStore.requestFullAccessToEvents { granted, error in
            if granted {
                loadEvents()
            }
        }
        #endif
    }
    
    private func loadEvents() {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: selectedDate)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )
        
        events = eventStore.events(matching: predicate)
    }
}

struct AddEventView: View {
    @Environment(\.dismiss) var dismiss
    let eventStore: EKEventStore
    
    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Event Title", text: $title)
                DatePicker("Start Time", selection: $startDate)
                DatePicker("End Time", selection: $endDate)
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvent()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveEvent() {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Error saving event: \(error)")
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
} 