//
//  CoreDataImporter.swift
//  JournalCoreData
//
//  Created by Andrew R Madsen on 9/10/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataImporter {
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        let startTime = Date()
        print("The start time: \(startTime)")
        let fetchQueue = DispatchQueue.global(qos: .background)
        
        self.context.perform {
            fetchQueue.async {
                for entryRep in entries {
                    guard let identifier = entryRep.identifier else { continue }
                    let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
                    if let entry = entry, entry != entryRep {
                        self.update(entry: entry, with: entryRep)
                    } else if entry == nil {
                        _ = Entry(entryRepresentation: entryRep, context: self.context)
                    }
                }
            }
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            print("The end time: \(endTime)")
            print("The run time: \(duration) seconds")
            completion(nil)
        }
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
        
        guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        
        var result: Entry? = nil
        do {
            result = try context.fetch(fetchRequest).first
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
}
