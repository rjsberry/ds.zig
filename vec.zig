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

//
//
// Tests
//
//

test "init from array" {
    // array length less than capacity
    const a1 = [_]i32{1};
    const v3 = Vec(i32, 3).initFromArray(1, &a1);
    try std.testing.expectEqual(@as(usize, 1), v3.len);
    try std.testing.expect(mem.eql(i32, v3.data[0..1], &a1));
    // array length equal to capacity
    const a2 = [_]f32{ 1.0, 2.0 };
    const v2 = Vec(f32, 2).initFromArray(2, &a2);
    try std.testing.expectEqual(@as(usize, 2), v2.len);
    try std.testing.expect(mem.eql(f32, v2.data[0..2], &a2));
}

test "init from slice" {
    // slice length less than capacity
    const a1 = [_]i32{1};
    const v3 = Vec(i32, 3).initFromSlice(&a1) orelse unreachable;
    try std.testing.expectEqual(@as(usize, 1), v3.len);
    try std.testing.expect(mem.eql(i32, v3.data[0..1], &a1));
    // slice length equal to capacity
    const a2 = [_]f32{ 1.0, 2.0 };
    const v2 = Vec(f32, 2).initFromSlice(&a2) orelse unreachable;
    try std.testing.expectEqual(@as(usize, 2), v2.len);
    try std.testing.expect(mem.eql(f32, v2.data[0..2], &a2));
    // slice length greater than capacity
    const a5 = [_]u8{ 1, 2, 3, 4, 5 };
    try std.testing.expectEqual(
        @as(?Vec(u8, 4), null),
        Vec(u8, 4).initFromSlice(&a5),
    );
}

test "as const slice" {
    var v = Vec(u8, 3).init();
    const data = [_]u8{ 1, 2 };
    @memcpy(v.data[0..2], &data);
    v.len = 2;
    const s = v.asConstSlice();
    try std.testing.expect(mem.eql(u8, &data, s));
}

test "as slice" {
    var v = Vec(i16, 3).init();
    const data = [_]i16{ 1, 2 };
    @memcpy(v.data[0..2], &data);
    v.len = 2;
    const s = v.asSlice();
    try std.testing.expect(mem.eql(i16, &data, s));
}

test "as const array" {
    var v = Vec(u64, 3).init();
    const data = [_]u64{ 1, 2, 3 };
    v.data = data;
    v.len = 3;
    const a0 = v.asConstArray(0) orelse unreachable;
    try std.testing.expect(mem.eql(u64, &[_]u64{}, a0));
    const a1 = v.asConstArray(1) orelse unreachable;
    try std.testing.expect(mem.eql(u64, &[_]u64{1}, a1));
    const a2 = v.asConstArray(2) orelse unreachable;
    try std.testing.expect(mem.eql(u64, &[_]u64{ 1, 2 }, a2));
    const a3 = v.asConstArray(3) orelse unreachable;
    try std.testing.expect(mem.eql(u64, &[_]u64{ 1, 2, 3 }, a3));
}

test "as array" {
    var v = Vec(i32, 3).init();
    const data = [_]i32{ 1, 2, 3 };
    v.data = data;
    v.len = 3;
    const a0 = v.asArray(0) orelse unreachable;
    try std.testing.expect(mem.eql(i32, &[_]i32{}, a0));
    const a1 = v.asArray(1) orelse unreachable;
    try std.testing.expect(mem.eql(i32, &[_]i32{1}, a1));
    const a2 = v.asArray(2) orelse unreachable;
    try std.testing.expect(mem.eql(i32, &[_]i32{ 1, 2 }, a2));
    const a3 = v.asArray(3) orelse unreachable;
    try std.testing.expect(mem.eql(i32, &[_]i32{ 1, 2, 3 }, a3));
}

test "push" {
    var v = Vec(u16, 3).init();
    try v.push(1);
    try std.testing.expectEqual(@as(usize, 1), v.len);
    try std.testing.expect(mem.eql(u16, v.data[0..1], &[_]u16{1}));
    try v.push(2);
    try std.testing.expectEqual(@as(usize, 2), v.len);
    try std.testing.expect(mem.eql(u16, v.data[0..2], &[_]u16{ 1, 2 }));
    try v.push(3);
    try std.testing.expectEqual(@as(usize, 3), v.len);
    try std.testing.expect(mem.eql(u16, &v.data, &[_]u16{ 1, 2, 3 }));
    try std.testing.expectError(error.AtCapacity, v.push(4));
}

test "push from pointer" {
    var v = Vec(i8, 3).init();
    const x1 = @as(i8, 1);
    try v.pushFromPtr(&x1);
    try std.testing.expectEqual(@as(usize, 1), v.len);
    try std.testing.expect(mem.eql(i8, v.data[0..1], &[_]i8{1}));
    const x2 = @as(i8, 2);
    try v.pushFromPtr(&x2);
    try std.testing.expectEqual(@as(usize, 2), v.len);
    try std.testing.expect(mem.eql(i8, v.data[0..2], &[_]i8{ 1, 2 }));
    const x3 = @as(i8, 3);
    try v.pushFromPtr(&x3);
    try std.testing.expectEqual(@as(usize, 3), v.len);
    try std.testing.expect(mem.eql(i8, &v.data, &[_]i8{ 1, 2, 3 }));
    const x4 = @as(i8, 4);
    try std.testing.expectError(error.AtCapacity, v.pushFromPtr(&x4));
}

test "pop" {
    var v = Vec(f64, 3).init();
    v.data = [_]f64{ 1.0, 2.0, 3.0 };
    v.len = 3;
    try std.testing.expectEqual(@as(f64, 3.0), v.pop() orelse unreachable);
    v.len = 2;
    try std.testing.expectEqual(@as(f64, 2.0), v.pop() orelse unreachable);
    v.len = 1;
    try std.testing.expectEqual(@as(f64, 1.0), v.pop() orelse unreachable);
    v.len = 0;
    try std.testing.expectEqual(@as(?f64, null), v.pop());
    v.len = 0;
}

test "extend from slice" {
    var v = Vec(u8, 3).init();
    try v.extendFromSlice(&[_]u8{1});
    try std.testing.expectEqual(@as(usize, 1), v.len);
    try std.testing.expect(mem.eql(u8, v.data[0..1], &[_]u8{1}));
    try std.testing.expectError(error.AtCapacity, v.extendFromSlice(
        &[_]u8{ 4, 5, 6 },
    ));
    try v.extendFromSlice(&[_]u8{ 2, 3 });
    try std.testing.expectEqual(@as(usize, 3), v.len);
    try std.testing.expect(mem.eql(u8, &v.data, &[_]u8{ 1, 2, 3 }));
}

test "insert" {
    var v = Vec(u32, 3).init();
    try v.insert(0, 3);
    try std.testing.expectEqual(@as(usize, 1), v.len);
    try std.testing.expect(mem.eql(u32, v.data[0..1], &[_]u32{3}));
    try v.insert(0, 1);
    try std.testing.expectEqual(@as(usize, 2), v.len);
    try std.testing.expect(mem.eql(u32, v.data[0..2], &[_]u32{ 1, 3 }));
    try std.testing.expectEqual(@as(usize, 2), v.len);
    try v.insert(1, 2);
    try std.testing.expectEqual(@as(usize, 3), v.len);
    try std.testing.expect(mem.eql(u32, &v.data, &[_]u32{ 1, 2, 3 }));
}

test "remove" {
    var v = Vec(i64, 4).init();
    v.data = [_]i64{ 1, 2, 3, 4 };
    v.len = 4;
    try std.testing.expectEqual(@as(i64, 2), v.remove(1));
    try std.testing.expectEqual(@as(usize, 3), v.len);
    try std.testing.expectEqual(@as(i64, 1), v.remove(0));
    try std.testing.expectEqual(@as(usize, 2), v.len);
    try std.testing.expectEqual(@as(i64, 4), v.remove(1));
    try std.testing.expectEqual(@as(usize, 1), v.len);
    try std.testing.expectEqual(@as(i64, 3), v.remove(0));
    try std.testing.expectEqual(@as(usize, 0), v.len);
}

test "swap remove" {
    var v = Vec(i64, 4).init();
    v.data = [_]i64{ 1, 2, 3, 4 };
    v.len = 4;
    try std.testing.expectEqual(@as(i64, 2), v.swapRemove(1));
    try std.testing.expectEqual(@as(usize, 3), v.len);
    try std.testing.expectEqual(@as(i64, 4), v.swapRemove(1));
    try std.testing.expectEqual(@as(usize, 2), v.len);
    try std.testing.expectEqual(@as(i64, 1), v.swapRemove(0));
    try std.testing.expectEqual(@as(usize, 1), v.len);
    try std.testing.expectEqual(@as(i64, 3), v.swapRemove(0));
    try std.testing.expectEqual(@as(usize, 0), v.len);
}

test "retain" {
    var v = Vec(u8, 5).init();
    v.data = [_]u8{ 1, 2, 3, 4, 5 };
    v.len = 5;

    v.retain(
        struct {
            fn predicate(item: *u8) bool {
                return (item.* % 2) != 0;
            }
        }.predicate,
    );

    try std.testing.expectEqual(@as(usize, 3), v.len);
    try std.testing.expect(mem.eql(u8, v.data[0..3], &[_]u8{ 1, 3, 5 }));

    v.retain(
        struct {
            fn predicate(item: *u8) bool {
                return item.* != 3;
            }
        }.predicate,
    );

    try std.testing.expectEqual(@as(usize, 2), v.len);
    try std.testing.expect(mem.eql(u8, v.data[0..2], &[_]u8{ 1, 5 }));

    v.retain(
        struct {
            fn predicate(_: *u8) bool {
                return false;
            }
        }.predicate,
    );

    try std.testing.expectEqual(@as(usize, 0), v.len);
}
