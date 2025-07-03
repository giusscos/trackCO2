import SwiftUI
import SwiftData

struct SelectActivitiesToPersistView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query var activities: [Activity]
    
    @State private var selectedIDs: Set<UUID> = []
    
    var unpersistedActivities: [Activity] {
        let persistedNames = Set(activities.map { $0.name })
        return defaultActivities.filter { !persistedNames.contains($0.name) }
    }
    
    var body: some View {
        NavigationStack {
            List(unpersistedActivities, id: \.id, selection: $selectedIDs) { activity in
                HStack {
                    Text(activity.type.emoji)
                    VStack(alignment: .leading) {
                        Text(activity.name).font(.headline)
                        if !activity.activityDescription.isEmpty {
                            Text(activity.activityDescription).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Select Activities")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        persistSelected()
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
            .environment(\.editMode, .constant(.active))
        }
    }
    
    private func persistSelected() {
        for activity in unpersistedActivities where selectedIDs.contains(activity.id) {
            let newActivity = Activity(
                type: activity.type,
                name: activity.name,
                activityDescription: activity.activityDescription,
                quantityUnit: activity.quantityUnit,
                emissionUnit: activity.emissionUnit,
                co2Emission: activity.co2Emission
            )
            
            modelContext.insert(newActivity)
            
            dismiss()
        }
    }
}

#Preview {
    SelectActivitiesToPersistView()
} 
