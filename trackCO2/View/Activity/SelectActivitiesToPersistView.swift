import SwiftUI
import SwiftData

struct SelectActivitiesToPersistView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query var activities: [Activity]
    
    @State private var selectedTypes: Set<ActivityEmissionType> = []
    
    var unpersistedActivities: [Activity] {
        let persistedTypes = Set(activities.map { $0.type })
        return defaultActivities.filter { !persistedTypes.contains($0.type) }
    }
    
    var body: some View {
        NavigationStack {
            List(unpersistedActivities, id: \.type, selection: $selectedTypes) { activity in
                HStack {
                    Text(activity.type.emoji)
                    VStack(alignment: .leading) {
                        Text(activity.displayName).font(.headline)
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
                    .disabled(selectedTypes.isEmpty)
                }
            }
            .environment(\.editMode, .constant(.active))
        }
    }
    
    private func persistSelected() {
        for activity in unpersistedActivities where selectedTypes.contains(activity.type) {
            let newActivity = Activity(
                type: activity.type,
                name: activity.type.defaultNameKey,
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
