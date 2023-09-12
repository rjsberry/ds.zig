// The contents of this file is dual-licensed under the MIT or 0BSD license.

const std = @import("std");

const mem = std.mem;
const rand = std.rand;
const testing = std.testing;
const time = std.time;

const Deque = @import("ds").Deque;

test "push/pop front" {
    var d = Deque(u8, 3).init();
    try testing.expectEqual(@as(?u8, null), d.popFront());
    try d.pushFront(3);
    try d.pushFront(2);
    try d.pushFront(1);
    try testing.expectEqual(@as(u8, 1), d.popFront().?);
    try testing.expectEqual(@as(u8, 2), d.popFront().?);
    try testing.expectEqual(@as(u8, 3), d.popFront().?);
    try testing.expectEqual(@as(?u8, null), d.popFront());
}

test "push/pop back" {
    var d = Deque(u8, 3).init();
    try testing.expectEqual(@as(?u8, null), d.popBack());
    try d.pushBack(1);
    try d.pushBack(2);
    try d.pushBack(3);
    try testing.expectEqual(@as(u8, 3), d.popBack().?);
    try testing.expectEqual(@as(u8, 2), d.popBack().?);
    try testing.expectEqual(@as(u8, 1), d.popBack().?);
    try testing.expectEqual(@as(?u8, null), d.popBack());
}

test "smoke" {
    const capacity: usize = 32;

    var d1 = Deque(u8, capacity).init();
    var prng = rand.DefaultPrng.init(@bitCast(time.timestamp()));
    var random = prng.random();

    for (0..1024) |_| {
        var d2 = Deque(u8, capacity).init();

        // Push to front/back in some random order
        for (0..capacity) |i| {
            try testing.expectEqual(i, d1.len);
            try testing.expectEqual(i, d2.len);
            const x = random.int(u8);
            if (random.boolean()) {
                try d1.pushFront(x);
                try d2.pushFront(x);
            } else {
                try d1.pushBack(x);
                try d2.pushBack(x);
            }
        }

        try testing.expectEqual(capacity, d1.len);
        try testing.expectEqual(capacity, d2.len);

        // The internal state of the deques might be different but once
        // remapped to contiguous space the data should be identical
        //
        // Also, check equality of the const and non-const functions
        var d1_contiguous: [capacity]u8 = undefined;
        var d2_contiguous: [capacity]u8 = undefined;
        if (random.boolean()) {
            const d1_parts = d1.asConstSlices();
            const d2_parts = d2.asSlices();
            @memcpy(d1_contiguous[0..d1_parts[0].len], d1_parts[0]);
            @memcpy(d1_contiguous[capacity - d1_parts[1].len ..], d1_parts[1]);
            @memcpy(d2_contiguous[0..d2_parts[0].len], d2_parts[0]);
            @memcpy(d2_contiguous[capacity - d2_parts[1].len ..], d2_parts[1]);
        } else {
            const d1_parts = d1.asSlices();
            const d2_parts = d2.asConstSlices();
            @memcpy(d1_contiguous[0..d1_parts[0].len], d1_parts[0]);
            @memcpy(d1_contiguous[capacity - d1_parts[1].len ..], d1_parts[1]);
            @memcpy(d2_contiguous[0..d2_parts[0].len], d2_parts[0]);
            @memcpy(d2_contiguous[capacity - d2_parts[1].len ..], d2_parts[1]);
        }
        try testing.expect(mem.eql(u8, &d1_contiguous, &d2_contiguous));

        // Pop from front/back in some random order
        for (0..capacity) |i| {
            try testing.expectEqual(capacity - i, d1.len);
            try testing.expectEqual(capacity - i, d2.len);
            if (random.boolean()) {
                try testing.expectEqual(d1.popFront().?, d2.popFront().?);
            } else {
                try testing.expectEqual(d1.popBack().?, d2.popBack().?);
            }
        }

        try testing.expectEqual(@as(usize, 0), d1.len);
        try testing.expectEqual(@as(usize, 0), d2.len);

        try testing.expectEqual(@as(usize, 0), d1.asConstSlices()[0].len);
        try testing.expectEqual(@as(usize, 0), d1.asConstSlices()[1].len);
        try testing.expectEqual(@as(usize, 0), d1.asSlices()[0].len);
        try testing.expectEqual(@as(usize, 0), d1.asSlices()[1].len);
        try testing.expectEqual(@as(usize, 0), d2.asConstSlices()[0].len);
        try testing.expectEqual(@as(usize, 0), d2.asConstSlices()[1].len);
        try testing.expectEqual(@as(usize, 0), d2.asSlices()[0].len);
        try testing.expectEqual(@as(usize, 0), d2.asSlices()[1].len);
    }
}
