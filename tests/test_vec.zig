// The contents of this file is dual-licensed under the MIT or 0BSD license.

const std = @import("std");

const mem = std.mem;
const testing = std.testing;

const Vec = @import("ds").Vec;

test "init from array" {
    // array length less than capacity
    const a1 = [_]i32{1};
    const v3 = Vec(i32, 3).initFromArray(1, &a1);
    try testing.expectEqual(@as(usize, 1), v3.len);
    try testing.expect(mem.eql(i32, v3.data[0..1], &a1));
    // array length equal to capacity
    const a2 = [_]f32{ 1.0, 2.0 };
    const v2 = Vec(f32, 2).initFromArray(2, &a2);
    try testing.expectEqual(@as(usize, 2), v2.len);
    try testing.expect(mem.eql(f32, v2.data[0..2], &a2));
}

test "init from slice" {
    // slice length less than capacity
    const a1 = [_]i32{1};
    const v3 = Vec(i32, 3).initFromSlice(&a1) orelse unreachable;
    try testing.expectEqual(@as(usize, 1), v3.len);
    try testing.expect(mem.eql(i32, v3.data[0..1], &a1));
    // slice length equal to capacity
    const a2 = [_]f32{ 1.0, 2.0 };
    const v2 = Vec(f32, 2).initFromSlice(&a2) orelse unreachable;
    try testing.expectEqual(@as(usize, 2), v2.len);
    try testing.expect(mem.eql(f32, v2.data[0..2], &a2));
    // slice length greater than capacity
    const a5 = [_]u8{ 1, 2, 3, 4, 5 };
    try testing.expectEqual(
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
    try testing.expect(mem.eql(u8, &data, s));
}

test "as slice" {
    var v = Vec(i16, 3).init();
    const data = [_]i16{ 1, 2 };
    @memcpy(v.data[0..2], &data);
    v.len = 2;
    const s = v.asSlice();
    try testing.expect(mem.eql(i16, &data, s));
}

test "as const array" {
    var v = Vec(u64, 3).init();
    const data = [_]u64{ 1, 2, 3 };
    v.data = data;
    v.len = 3;
    const a0 = v.asConstArray(0) orelse unreachable;
    try testing.expect(mem.eql(u64, &[_]u64{}, a0));
    const a1 = v.asConstArray(1) orelse unreachable;
    try testing.expect(mem.eql(u64, &[_]u64{1}, a1));
    const a2 = v.asConstArray(2) orelse unreachable;
    try testing.expect(mem.eql(u64, &[_]u64{ 1, 2 }, a2));
    const a3 = v.asConstArray(3) orelse unreachable;
    try testing.expect(mem.eql(u64, &[_]u64{ 1, 2, 3 }, a3));
}

test "as array" {
    var v = Vec(i32, 3).init();
    const data = [_]i32{ 1, 2, 3 };
    v.data = data;
    v.len = 3;
    const a0 = v.asArray(0) orelse unreachable;
    try testing.expect(mem.eql(i32, &[_]i32{}, a0));
    const a1 = v.asArray(1) orelse unreachable;
    try testing.expect(mem.eql(i32, &[_]i32{1}, a1));
    const a2 = v.asArray(2) orelse unreachable;
    try testing.expect(mem.eql(i32, &[_]i32{ 1, 2 }, a2));
    const a3 = v.asArray(3) orelse unreachable;
    try testing.expect(mem.eql(i32, &[_]i32{ 1, 2, 3 }, a3));
}

test "push" {
    var v = Vec(u16, 3).init();
    try v.push(1);
    try testing.expectEqual(@as(usize, 1), v.len);
    try testing.expect(mem.eql(u16, v.data[0..1], &[_]u16{1}));
    try v.push(2);
    try testing.expectEqual(@as(usize, 2), v.len);
    try testing.expect(mem.eql(u16, v.data[0..2], &[_]u16{ 1, 2 }));
    try v.push(3);
    try testing.expectEqual(@as(usize, 3), v.len);
    try testing.expect(mem.eql(u16, &v.data, &[_]u16{ 1, 2, 3 }));
    try testing.expectError(error.AtCapacity, v.push(4));
}

test "push from pointer" {
    var v = Vec(i8, 3).init();
    const x1 = @as(i8, 1);
    try v.pushFromPtr(&x1);
    try testing.expectEqual(@as(usize, 1), v.len);
    try testing.expect(mem.eql(i8, v.data[0..1], &[_]i8{1}));
    const x2 = @as(i8, 2);
    try v.pushFromPtr(&x2);
    try testing.expectEqual(@as(usize, 2), v.len);
    try testing.expect(mem.eql(i8, v.data[0..2], &[_]i8{ 1, 2 }));
    const x3 = @as(i8, 3);
    try v.pushFromPtr(&x3);
    try testing.expectEqual(@as(usize, 3), v.len);
    try testing.expect(mem.eql(i8, &v.data, &[_]i8{ 1, 2, 3 }));
    const x4 = @as(i8, 4);
    try testing.expectError(error.AtCapacity, v.pushFromPtr(&x4));
}

test "pop" {
    var v = Vec(f64, 3).init();
    v.data = [_]f64{ 1.0, 2.0, 3.0 };
    v.len = 3;
    try testing.expectEqual(@as(f64, 3.0), v.pop() orelse unreachable);
    v.len = 2;
    try testing.expectEqual(@as(f64, 2.0), v.pop() orelse unreachable);
    v.len = 1;
    try testing.expectEqual(@as(f64, 1.0), v.pop() orelse unreachable);
    v.len = 0;
    try testing.expectEqual(@as(?f64, null), v.pop());
    v.len = 0;
}

test "extend from slice" {
    var v = Vec(u8, 3).init();
    try v.extendFromSlice(&[_]u8{1});
    try testing.expectEqual(@as(usize, 1), v.len);
    try testing.expect(mem.eql(u8, v.data[0..1], &[_]u8{1}));
    try testing.expectError(error.AtCapacity, v.extendFromSlice(
        &[_]u8{ 4, 5, 6 },
    ));
    try v.extendFromSlice(&[_]u8{ 2, 3 });
    try testing.expectEqual(@as(usize, 3), v.len);
    try testing.expect(mem.eql(u8, &v.data, &[_]u8{ 1, 2, 3 }));
}

test "insert" {
    var v = Vec(u32, 3).init();
    try v.insert(0, 3);
    try testing.expectEqual(@as(usize, 1), v.len);
    try testing.expect(mem.eql(u32, v.data[0..1], &[_]u32{3}));
    try v.insert(0, 1);
    try testing.expectEqual(@as(usize, 2), v.len);
    try testing.expect(mem.eql(u32, v.data[0..2], &[_]u32{ 1, 3 }));
    try testing.expectEqual(@as(usize, 2), v.len);
    try v.insert(1, 2);
    try testing.expectEqual(@as(usize, 3), v.len);
    try testing.expect(mem.eql(u32, &v.data, &[_]u32{ 1, 2, 3 }));
}

test "remove" {
    var v = Vec(i64, 4).init();
    v.data = [_]i64{ 1, 2, 3, 4 };
    v.len = 4;
    try testing.expectEqual(@as(i64, 2), v.remove(1));
    try testing.expectEqual(@as(usize, 3), v.len);
    try testing.expectEqual(@as(i64, 1), v.remove(0));
    try testing.expectEqual(@as(usize, 2), v.len);
    try testing.expectEqual(@as(i64, 4), v.remove(1));
    try testing.expectEqual(@as(usize, 1), v.len);
    try testing.expectEqual(@as(i64, 3), v.remove(0));
    try testing.expectEqual(@as(usize, 0), v.len);
}

test "swap remove" {
    var v = Vec(i64, 4).init();
    v.data = [_]i64{ 1, 2, 3, 4 };
    v.len = 4;
    try testing.expectEqual(@as(i64, 2), v.swapRemove(1));
    try testing.expectEqual(@as(usize, 3), v.len);
    try testing.expectEqual(@as(i64, 4), v.swapRemove(1));
    try testing.expectEqual(@as(usize, 2), v.len);
    try testing.expectEqual(@as(i64, 1), v.swapRemove(0));
    try testing.expectEqual(@as(usize, 1), v.len);
    try testing.expectEqual(@as(i64, 3), v.swapRemove(0));
    try testing.expectEqual(@as(usize, 0), v.len);
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

    try testing.expectEqual(@as(usize, 3), v.len);
    try testing.expect(mem.eql(u8, v.data[0..3], &[_]u8{ 1, 3, 5 }));

    v.retain(
        struct {
            fn predicate(item: *u8) bool {
                return item.* != 3;
            }
        }.predicate,
    );

    try testing.expectEqual(@as(usize, 2), v.len);
    try testing.expect(mem.eql(u8, v.data[0..2], &[_]u8{ 1, 5 }));

    v.retain(
        struct {
            fn predicate(_: *u8) bool {
                return false;
            }
        }.predicate,
    );

    try testing.expectEqual(@as(usize, 0), v.len);
}
