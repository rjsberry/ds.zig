// The contents of this file is dual-licensed under the MIT or 0BSD license.

//! A doubly linked list.

const std = @import("std");

const debug = std.debug;
const mem = std.mem;

/// A list node inside a `LinkedList`.
pub fn ListNode(comptime T: type) type {
    return struct {
        const Self = @This();

        /// A pointer to the previous list node.
        ///
        /// Null if this node is at the start of the linked list.
        prev: ?*ListNode(T) = null,
        /// A pointer to the next list node.
        ///
        /// Null if this node is at the end of the linked list.
        next: ?*ListNode(T) = null,
        /// The data contained within the node.
        data: T = undefined,
    };
}

/// A doubly linked list.
///
/// Unlike many other collections in this library the linked list does not
/// contain backing data for its list nodes. You should manage this yourself
/// with, for example, a deque as a FIFO node pointer "allocator".
pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        /// A pointer to the start of the nodes.
        head: ?*ListNode(T) = null,
        /// A pointer to the end of the nodes.
        tail: ?*ListNode(T) = null,
        /// The current length of the linked list.
        len: usize = 0,

        /// Initializes the linked list.
        pub fn init() Self {
            return Self{};
        }

        /// Pushes a node to the front of the linked list.
        ///
        /// Computes in constant time.
        pub fn pushFront(self: *Self, node: *ListNode(T)) void {
            debug.assert(node.prev == null);
            debug.assert(node.next == null);

            node.next = self.head;
            var head = self.head;
            self.head = node;
            self.len += 1;

            if (self.len == 1) {
                self.tail = node;
            } else {
                head.?.prev = node;
            }
        }

        /// Removes a node from the front of the linked list.
        ///
        /// Computes in constant time.
        pub fn popFront(self: *Self) ?*ListNode(T) {
            if (self.head) |head| {
                debug.assert(self.len > 0);
                self.len -= 1;

                if (head.next) |next| {
                    debug.assert(self.len > 0);
                    next.prev = null;
                    self.head = next;
                } else {
                    debug.assert(self.len == 0);
                    self.head = null;
                    self.tail = null;
                }

                head.prev = null;
                head.next = null;
                return head;
            }

            return null;
        }

        /// Pushes a node to the back of the linked list.
        ///
        /// Computes in constant time.
        pub fn pushBack(self: *Self, node: *ListNode(T)) void {
            debug.assert(node.prev == null);
            debug.assert(node.next == null);

            node.prev = self.tail;
            var tail = self.tail;
            self.tail = node;
            self.len += 1;

            if (self.len == 1) {
                self.head = node;
            } else {
                tail.?.next = node;
            }
        }

        /// Removes a node from the back of the linked list.
        ///
        /// Computes in constant time.
        pub fn popBack(self: *Self) ?*ListNode(T) {
            if (self.tail) |tail| {
                debug.assert(self.len > 0);
                self.len -= 1;

                if (tail.prev) |prev| {
                    debug.assert(self.len > 0);
                    prev.next = null;
                    self.tail = prev;
                } else {
                    debug.assert(self.len == 0);
                    self.head = null;
                    self.tail = null;
                }

                tail.prev = null;
                tail.next = null;
                return tail;
            }

            return null;
        }

        /// Insert a node at the given index into the linked list.
        ///
        /// Computes in linear time.
        pub fn insert(self: *Self, idx: usize, node: *ListNode(T)) void {
            debug.assert(idx <= self.len);

            if (self.len == 0 or idx == 0) {
                // Shortcut for empty linked lists or head insertion
                self.pushFront(node);
            } else if (idx == self.len) {
                // Shortcut for tail insertion
                self.pushBack(node);
            } else if (idx < (self.len / 2)) {
                // Forward traversal from head
                var loc = self.head.?;
                for (0..idx) |_| loc = loc.next.?;
                node.prev = loc;
                node.next = loc.next;
                loc.next.?.prev = node;
                loc.next = node;
                self.len += 1;
            } else {
                // Backward traversal from tail
                var loc = self.tail.?;
                for (0..self.len - idx - 1) |_| loc = loc.prev.?;
                node.next = loc;
                node.prev = loc.prev;
                loc.prev.?.next = node;
                loc.prev = node;
                self.len += 1;
            }
        }

        /// Remove a node from the given index in the linked list.
        ///
        /// Computes in linear time.
        pub fn remove(self: *Self, idx: usize) *ListNode(T) {
            debug.assert(idx < self.len);

            if (idx == 0) {
                // Shortcut head removal
                return self.popFront().?;
            } else if (idx == self.len - 1) {
                // Shortcut for tail removal
                return self.popBack().?;
            }

            var loc: *ListNode(T) = undefined;

            if (idx < (self.len / 2)) {
                // Forward traversal from head
                loc = self.head.?;
                for (0..idx) |_| loc = loc.next.?;
            } else {
                // Backward traversal from tail
                loc = self.tail.?;
                for (0..self.len - idx - 1) |_| loc = loc.prev.?;
            }

            var prev = loc.prev.?;
            var next = loc.next.?;
            prev.next = next;
            next.prev = prev;
            loc.prev = null;
            loc.next = null;
            self.len -= 1;
            return loc;
        }
    };
}
