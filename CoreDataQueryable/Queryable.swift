import CoreData
import Combine
import SwiftUI

protocol Queryable: Hashable {
    associatedtype Filter: QueryFilter
    init(result: Filter.ResultType)
}

protocol QueryFilter: Equatable {
    associatedtype ResultType: NSFetchRequestResult
    func fetchRequest(_ controller: PersistenceController) -> NSFetchRequest<ResultType>
}

struct ItemModel: Queryable, Equatable, Identifiable {
    public var id: Date? { timestamp }
    
    
    public typealias Filter = ItemFilter

    public let timestamp: Date?
}

extension ItemModel {
    init(result: Item) {
        print("mapped \(result.objectID)")
        self.timestamp = result.timestamp
    }
}

public struct ItemFilter: QueryFilter {
    public static let all = ItemFilter()
 
    func fetchRequest(_ controller: PersistenceController) -> NSFetchRequest<Item> {
        let f = Item.defaultFetchRequest()
//        f.fetchBatchSize = 50
        return f
    }
}

@propertyWrapper
struct Query<T: Queryable>: DynamicProperty {
    @Environment(\.dataStore) private var controller: PersistenceController
    @StateObject private var core: Core = Core()
    private let baseFilter: T.Filter
    
    init( _ baseFilter: T.Filter) {
        self.baseFilter = baseFilter
    }
    
    var wrappedValue: QueryResults<T> { core.results }
    
    func update() {
        if core.controller == nil { core.controller = controller }
        if core.filter == nil { core.filter = baseFilter }
        core.fetchIfNecessary()
    }
    
    private class Core: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        var controller: PersistenceController?
        
        private(set) var results: QueryResults<T> = QueryResults()
        var filter: T.Filter?
        
        private var frc: NSFetchedResultsController<T.Filter.ResultType>?
        
        func fetchIfNecessary() {
            guard let controller = controller else {
                fatalError("Attempting to execute a @Query but the DataStore is not in the environment")
            }
            guard let f = filter else {
                fatalError("Attempting to execute a @Query without a filter")
            }
            
            var shouldFetch = false
            
            let request = f.fetchRequest(controller)
            if let controller = frc {
                if controller.fetchRequest.predicate != request.predicate {
                    controller.fetchRequest.predicate = request.predicate
                    shouldFetch = true
                }
                if controller.fetchRequest.sortDescriptors != request.sortDescriptors {
                    controller.fetchRequest.sortDescriptors = request.sortDescriptors
                    shouldFetch = true
                }
            } else {
                let controller = NSFetchedResultsController(fetchRequest: request,
                                                            managedObjectContext: controller.container.viewContext,
                                                            sectionNameKeyPath: nil, cacheName: nil)
                controller.delegate = self
                frc = controller
                shouldFetch = true
            }
            
            if shouldFetch {
                try? frc?.performFetch()
                
                let resultsArray = (frc?.fetchedObjects as NSArray?) ?? NSArray()
                results = QueryResults(results: resultsArray)
            }
        }
        
        func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            objectWillChange.send()
        }
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            let resultsArray = (controller.fetchedObjects as NSArray?) ?? NSArray()
            results = QueryResults(results: resultsArray)
        }
    }
}

class QueryResults<T: Queryable>: RandomAccessCollection {
    
    public let results: NSArray
    
    
    public init(results: NSArray = NSArray()) {
        self.results = results
    }
    
    public var count: Int { results.count }
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }
    
    public subscript(position: Int) -> T {
        let object = results.object(at: position) as! T.Filter.ResultType
        return T(result: object)
    }
}

