import SwiftUI

@main
struct CoreDataQueryableApp: App {
    let persistenceController = PersistenceController.preview

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.dataStore, persistenceController)
        }
    }
}

struct DataStoreKey: EnvironmentKey {
    static var defaultValue: PersistenceController = .preview
}

extension EnvironmentValues {
    var dataStore: PersistenceController {
        get { self[DataStoreKey.self] }
        set { self[DataStoreKey.self] = newValue }
    }
}
