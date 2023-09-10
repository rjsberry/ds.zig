// The contents of this file is dual-licensed under the MIT or 0BSD license.

//! A fixed capacity heapless vector.

const std = @import("std");

const debug = std.debug;
const fmt = std.fmt;
const mem = std.mem;

/// The error returned by fallible operations on vectors.
const Error = error{AtCapacity};

/// A fixed capacity vector.
pub fn Vec(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();

        len: usize = 0,
        data: [capacity]T = undefined,

        /// Initialize an empty vector.
        pub fn init() Self {
            return Self{};
        }

        /// Initialize the vector from a slice.
        ///
        /// Returns `null` if the length of the slice is greater than the
        /// capacity of the vector.
        pub fn initFromSlice(slice: []const T) ?Self {
            if (slice.len > capacity) {
                return null;
            }

            var v = Self{};
            @memcpy(v.data[0..slice.len], slice);
            v.len = slice.len;
            return v;
        }

        /// Initialize the vector from an array.
        ///
        /// Generates a compile error if the length of the array is greater
        /// than the capacity of the vector.
        pub fn initFromArray(comptime n: usize, array: *const [n]T) Self {
            comptime if (n > capacity) {
                @compileError(fmt.comptimePrint(
                    "Vec::initFromArray: n ({}) > capacity ({})",
                    .{ n, capacity },
                ));
            };

            var v = Self{};
            @memcpy(v.data[0..n], array);
            v.len = n;
            return v;
        }

        /// Return all elements in the vector as a constant slice.
        pub fn asConstSlice(self: *const Self) []const T {
            return self.data[0..self.len];
        }

        /// Return all elements in the vector as a slice.
        pub fn asSlice(self: *Self) []T {
            return self.data[0..self.len];
        }

        /// Return the elements in the vector as an array.
        ///
        /// Returns `null` if `n` is greater than the current capacity.
        /// Generates a compile error if `n` is greater than the maximum
        /// capacity of the vector.
        pub fn asConstArray(self: *const Self, comptime n: usize) ?*const [n]T {
            comptime if (n > capacity) {
                @compileError(fmt.comptimePrint(
                    "Vec::asConstArray: n ({}) > capacity ({})",
                    .{ n, capacity },
                ));
            };

            if (n > self.len) {
                return null;
            }

            return self.data[0..n];
        }

        /// Return the elements in the vector as an array.
        ///
        /// Returns `null` if `n` is greater than the current capacity.
        /// Generates a compile error if `n` is greater than the maximum
        /// capacity of the vector.
        pub fn asArray(self: *Self, comptime n: usize) ?*[n]T {
            comptime if (n > capacity) {
                @compileError(fmt.comptimePrint(
                    "Vec::asArray: n ({}) > capacity ({})",
                    .{ n, capacity },
                ));
            };

            if (n > self.len) {
                return null;
            }

            return self.data[0..n];
        }

        /// Push an item to the back of the vector.
        pub fn push(self: *Self, item: T) Error!void {
            if (self.len == capacity) {
                return error.AtCapacity;
            }
            self.pushUnchecked(item);
        }

        /// Push an item to the back of the vector by pointer.
        pub fn pushFromPtr(self: *Self, item: *const T) Error!void {
            if (self.len == capacity) {
                return error.AtCapacity;
            }
            self.pushUnchecked(item.*);
        }

        /// Push an item to the back of the vector (unchecked).
        pub fn pushUnchecked(self: *Self, item: T) void {
            self.data[self.len] = item;
            self.len += 1;
        }

        /// Pop an item from the back of the vector.
        ///
        /// Returns `null` if the vector is empty.
        pub fn pop(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }
            return self.popUnchecked();
        }

        /// Pop an item from the back of the vector (unchecked).
        pub fn popUnchecked(self: *Self) T {
            self.len -= 1;
            return self.data[self.len];
        }

        /// Extends the vector from a slice.
        ///
        /// Pushes no items from the slice if the entire slice would not fit
        /// into the vector.
        pub fn extendFromSlice(self: *Self, slice: []const T) Error!void {
            if ((self.len + slice.len) > capacity) {
                return error.AtCapacity;
            }
            self.extendFromSliceUnchecked(slice);
        }

        /// Extends the vector from a slice (unchecked).
        pub fn extendFromSliceUnchecked(self: *Self, slice: []const T) void {
            @memcpy(self.data[self.len .. self.len + slice.len], slice);
            self.len += slice.len;
        }

        /// Inserts an item at the specified index.
        ///
        /// All other items shift one space to the right if there is capacity
        /// for the new item.
        pub fn insert(self: *Self, idx: usize, item: T) Error!void {
            if (self.len == capacity) {
                return error.AtCapacity;
            }

            debug.assert(idx <= self.len);

            if (self.len == 0 and capacity != 0) {
                self.pushUnchecked(item);
            } else {
                self.insertUnchecked(idx, item);
            }
        }

        /// Inserts an item at the specified index (unchecked).
        pub fn insertUnchecked(self: *Self, idx: usize, item: T) void {
            mem.copyForwards(
                T,
                self.data[idx + 1 .. self.len + 1],
                self.data[idx..self.len],
            );

            self.data[idx] = item;
            self.len += 1;
        }

        /// Removes the item at the specified index, preserving order.
        ///
        /// If you don't need to preserve order `swapRemove` is much faster.
        pub fn remove(self: *Self, idx: usize) T {
            debug.assert(idx < self.len);

            self.len -= 1;
            const item = self.data[idx];

            mem.copyForwards(
                T,
                self.data[idx..self.len],
                self.data[idx + 1 .. self.len + 1],
            );

            return item;
        }

        /// Removes the item at the specified index without preserving order.
        ///
        /// The item at the end of the vector replaces the item that is removed,
        /// thus the operation completes in constant time.
        pub fn swapRemove(self: *Self, idx: usize) T {
            debug.assert(idx < self.len);
            self.len -= 1;
            const item = self.data[idx];
            self.data[idx] = self.data[self.len];
            return item;
        }

        /// Retains items in the vector which match the predicate.
        ///
        /// Completes in linear time. Use this instead of calling `remove` in
        /// a loop which would be quadtratic time.
        ///
        /// The predicate will be called exactly once per item.
        pub fn retain(self: *Self, comptime predicate: fn (*T) bool) void {
            var num_to_delete: usize = 0;
            var first_pass_loc: usize = 0;
            var subslice = self.data[0..self.len];

            // stop after the first item that needs removal
            for (subslice) |*item| {
                first_pass_loc += 1;
                if (!predicate(item)) {
                    num_to_delete += 1;
                    break;
                }
            }

            // copy items to be retained backwards
            subslice = self.data[first_pass_loc..self.len];
            for (subslice, first_pass_loc..) |*item, idx| {
                if (!predicate(item)) {
                    num_to_delete += 1;
                    continue;
                }
                self.data[idx - num_to_delete] = item.*;
            }

            self.len -= num_to_delete;
        }
    };
}
