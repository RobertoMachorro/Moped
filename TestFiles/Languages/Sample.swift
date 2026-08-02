// Sample.swift — exercises Moped's Swift tokenizer.
import Foundation

/// A tiny model for a to-do item.
struct TodoItem: Identifiable {
	let id: UUID = UUID()
	var title: String
	var isDone: Bool = false
	var priority: Int = 0
}

enum Priority: Int, CaseIterable {
	case low = 0, medium = 1, high = 2
}

final class TodoList {
	private(set) var items: [TodoItem] = []

	func add(_ title: String, priority: Int = 0) {
		let item = TodoItem(title: title, priority: priority)
		items.append(item)
	}

	func complete(id: UUID) {
		guard let index = items.firstIndex(where: { $0.id == id }) else { return }
		items[index].isDone = true
	}

	var pendingCount: Int {
		items.filter { !$0.isDone }.count
	}
}

let list = TodoList()
list.add("Write sample files", priority: Priority.high.rawValue)
list.add("Review syntax highlighting")
print("Pending: \(list.pendingCount)")
