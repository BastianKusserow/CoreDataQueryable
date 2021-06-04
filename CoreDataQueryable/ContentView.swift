import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(fetchRequest: Item.defaultFetchRequest())
    private var fetchRequestItems: FetchedResults<Item>
    
    @Query(.all)
    private var queryItems: QueryResults<ItemModel>
    
    var body: some View {
        NavigationView {
            // Changing this to fetchRequestItems causes only necessary faults to fire
            List(queryItems) { item in
                Text("Item at \(item.timestamp!)")
            }
            .toolbar {
                ToolbarItemGroup {
                    Button(action: printData) {
                        Text("Print")
                    }
                }
            }
        }
    }

    private func printData() {
        print(fetchRequestItems)
        print(queryItems.results)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
