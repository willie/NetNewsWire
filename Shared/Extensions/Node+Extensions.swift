//
//  Node-Extensions.swift
//  Local
//
//  Created by Brent Simmons on 8/10/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//

import Foundation
import RSTree
import Articles
import RSCore
import Account

@MainActor extension Array where Element == Node {

	func sortedAlphabetically() -> [Node] {

		return Node.nodesSortedAlphabetically(self)
	}

	func sortedAlphabeticallyWithFoldersAtEnd() -> [Node] {

		return Node.nodesSortedAlphabeticallyWithFoldersAtEnd(self)
	}

	func sortedByUnreadCountWithFoldersAtEnd(ascending: Bool) -> [Node] {

		Node.nodesSortedByCountWithFoldersAtEnd(self, ascending: ascending) { node in
			(node.representedObject as? UnreadCountProvider)?.unreadCount ?? 0
		}
	}

	func sortedByAttentionWithFoldersAtEnd(ascending: Bool) -> [Node] {

		Node.nodesSortedByCountWithFoldersAtEnd(self, ascending: ascending) { node in
			(node.representedObject as? Feed)?.attentionScore ?? 0
		}
	}

	func sorted(by sortType: SidebarSortType, ascending: Bool = true) -> [Node] {

		let sorted: [Node]
		switch sortType {
		case .alphabetically:
			sorted = sortedAlphabeticallyWithFoldersAtEnd()
		case .byUnreadCount:
			// Direction applies to the count only; ties stay alphabetical.
			return sortedByUnreadCountWithFoldersAtEnd(ascending: ascending)
		case .byAttention:
			return sortedByAttentionWithFoldersAtEnd(ascending: ascending)
		}

		if ascending {
			return sorted
		}

		// Reverse feeds and folders separately to keep folders at end
		let feeds: [Node] = sorted.filter { !$0.canHaveChildNodes }
		let folders: [Node] = sorted.filter { $0.canHaveChildNodes }
		return Array(feeds.reversed()) + Array(folders.reversed())
	}
}

@MainActor private extension Node {

	class func nodesSortedAlphabetically(_ nodes: [Node]) -> [Node] {

		return nodes.sorted { (node1, node2) -> Bool in

			guard let obj1 = node1.representedObject as? DisplayNameProvider, let obj2 = node2.representedObject as? DisplayNameProvider else {
				return false
			}

			let name1 = obj1.nameForDisplay
			let name2 = obj2.nameForDisplay

			return name1.localizedStandardCompare(name2) == .orderedAscending
		}
	}

	class func nodesSortedAlphabeticallyWithFoldersAtEnd(_ nodes: [Node]) -> [Node] {

		return nodes.sorted { (node1, node2) -> Bool in

			if node1.canHaveChildNodes != node2.canHaveChildNodes {
				if node1.canHaveChildNodes {
					return false
				}
				return true
			}

			guard let obj1 = node1.representedObject as? DisplayNameProvider, let obj2 = node2.representedObject as? DisplayNameProvider else {
				return false
			}

			let name1 = obj1.nameForDisplay
			let name2 = obj2.nameForDisplay

			return name1.localizedStandardCompare(name2) == .orderedAscending
		}
	}

	class func nodesSortedByCountWithFoldersAtEnd(_ nodes: [Node], ascending: Bool, count: (Node) -> Int) -> [Node] {

		// Alphabetical tiebreaker regardless of direction
		return nodes.sorted { (node1, node2) -> Bool in

			if node1.canHaveChildNodes != node2.canHaveChildNodes {
				if node1.canHaveChildNodes {
					return false
				}
				return true
			}

			let count1 = count(node1)
			let count2 = count(node2)

			if count1 != count2 {
				return ascending ? count1 < count2 : count1 > count2
			}

			guard let obj1 = node1.representedObject as? DisplayNameProvider, let obj2 = node2.representedObject as? DisplayNameProvider else {
				return false
			}

			return obj1.nameForDisplay.localizedStandardCompare(obj2.nameForDisplay) == .orderedAscending
		}
	}
}
