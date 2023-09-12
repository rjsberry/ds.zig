// The contents of this file is dual-licensed under the MIT or 0BSD license.

//! A fixed capacity heapless double-ended queue.

const std = @import("std");

const debug = std.debug;
const fmt = std.fmt;

/// A fixed capacity double-ended queue.
///
/// This offers constant time push and pop operations at both ends of the
/// collection. However, unlike contiguous collections such as vectors, it is
/// not possible to view the contents of the deque as a single slice.
pub fn Deque(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();

        head: usize = 0,
        tail: usize = 0,
        len: usize = 0,
        data: [capacity]T = undefined,

        inline fn wrappingIncrement(idx: usize) usize {
            return if ((idx + 1) == capacity) 0 else idx + 1;
        }

        inline fn wrappingDecremet(idx: usize) usize {
            return if (idx == 0) capacity - 1 else idx - 1;
        }

        inline fn incrementHead(self: *Self) void {
            self.head = @call(
                .always_inline,
                Self.wrappingIncrement,
                .{self.head},
            );
            self.len -= 1;
        }

        inline fn decrementHead(self: *Self) void {
            self.head = @call(
                .always_inline,
                Self.wrappingDecremet,
                .{self.head},
            );
            self.len += 1;
        }

        inline fn incrementTail(self: *Self) void {
            self.tail = @call(
                .always_inline,
                Self.wrappingIncrement,
                .{self.tail},
            );
            self.len += 1;
        }

        inline fn decrementTail(self: *Self) void {
            self.tail = @call(
                .always_inline,
                Self.wrappingDecremet,
                .{self.tail},
            );
            self.len -= 1;
        }

        /// Initialize an empty deque.
        pub fn init() Self {
            return Self{};
        }

        /// Initialize the deque from a slice.
        ///
        /// Returns `null` if the length of the slice is greater than the
        /// capacity of the deque.
        pub fn initFromSlice(slice: []const T) ?Self {
            if (slice.len > capacity) {
                return null;
            }

            var d = Self{};
            @memcpy(d.data[0..slice.len], slice);
            d.len = slice.len;
            d.tail = slice.len;
            return d;
        }

        /// Initialize the deque from an array.
        ///
        /// Generates a compile error if the length of the array is greater
        /// than the capacity of the deque.
        pub fn initFromArray(comptime n: usize, array: *const [n]T) Self {
            comptime if (n > capacity) {
                @compileError(fmt.comptimePrint(
                    "Deque::initFromArray: n ({}) > capacity ({})",
                    .{ n, capacity },
                ));
            };

            var d = Self{};
            @memcpy(d.data[0..n], array);
            d.len = n;
            d.tail = n;
            return d;
        }

        /// Pushes an item to the front of the deque.
        pub fn pushFront(self: *Self, item: T) !void {
            if (self.len == capacity) {
                return error.AtCapacity;
            }
            self.pushFrontUnchecked(item);
        }

        /// Pushes an item to the front of the deque (unchecked).
        pub fn pushFrontUnchecked(self: *Self, item: T) void {
            debug.assert(self.len < capacity);
            self.data[self.head] = item;
            self.decrementHead();
        }

        /// Pops an item from the front of the deque.
        pub fn popFront(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }
            return self.popFrontUnchecked();
        }

        /// Pops an item from the front of the deque (unchecked).
        pub fn popFrontUnchecked(self: *Self) T {
            debug.assert(self.len > 0);
            self.incrementHead();
            return self.data[self.head];
        }

        /// Pushes an item to the back of the deque.
        pub fn pushBack(self: *Self, item: T) !void {
            if (self.len == capacity) {
                return error.AtCapacity;
            }
            self.pushBackUnchecked(item);
        }

        /// Pushes an item to the back of the deque (unchecked).
        pub fn pushBackUnchecked(self: *Self, item: T) void {
            debug.assert(self.len < capacity);
            self.incrementTail();
            self.data[self.tail] = item;
        }

        /// Pops an item from the back of the deque.
        pub fn popBack(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }
            return self.popBackUnchecked();
        }

        /// Pops an item from the back of the deque (unchecked).
        pub fn popBackUnchecked(self: *Self) T {
            debug.assert(self.len > 0);
            const item = self.data[self.tail];
            self.decrementTail();
            return item;
        }

        /// Returns all data currently in the deque (const).
        pub fn asConstSlices(self: *const Self) [2][]const T {
            if (self.len == 0) {
                return [_][]const T{ &[_]T{}, &[_]T{} };
            } else if (self.head < self.tail) {
                // Not inverted -- data is actually contiguous
                return [_][]const T{
                    self.data[self.head..self.tail],
                    &[_]T{},
                };
            } else {
                // Inverted -- data is not contiguous
                return [_][]const T{
                    self.data[self.head..capacity],
                    self.data[0..self.tail],
                };
            }
        }

        /// Returns all data currently in the deque.
        pub fn asSlices(self: *Self) [2][]T {
            if (self.len == 0) {
                return [_][]T{ &[_]T{}, &[_]T{} };
            } else if (self.head < self.tail) {
                // Not inverted -- data is actually contiguous
                return [_][]T{
                    self.data[self.head..self.tail],
                    &[_]T{},
                };
            } else {
                // Inverted -- data is not contiguous
                return [_][]T{
                    self.data[self.head..capacity],
                    self.data[0..self.tail],
                };
            }
        }
    };
}
