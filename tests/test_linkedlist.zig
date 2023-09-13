// The contents of this file is dual-licensed under the MIT or 0BSD license.

const std = @import("std");

const testing = std.testing;

const LinkedList = @import("ds").LinkedList;
const ListNode = @import("ds").ListNode;

test "push/pop front" {
    var a = ListNode(u8){ .data = 1 };
    var b = ListNode(u8){ .data = 2 };
    var c = ListNode(u8){ .data = 3 };

    var list = LinkedList(u8).init();

    try testing.expectEqual(@as(?*ListNode(u8), null), list.popFront());
    list.pushFront(&c);
    try testing.expectEqual(@as(usize, 1), list.len);
    list.pushFront(&b);
    try testing.expectEqual(@as(usize, 2), list.len);
    list.pushFront(&a);
    try testing.expectEqual(@as(usize, 3), list.len);

    try testing.expectEqual(@as(u8, 1), list.popFront().?.data);
    try testing.expectEqual(@as(usize, 2), list.len);
    try testing.expectEqual(@as(u8, 2), list.popFront().?.data);
    try testing.expectEqual(@as(usize, 1), list.len);
    try testing.expectEqual(@as(u8, 3), list.popFront().?.data);
    try testing.expectEqual(@as(usize, 0), list.len);

    try testing.expectEqual(@as(?*ListNode(u8), null), list.popFront());
}

test "push/pop back" {
    var a = ListNode(u8){ .data = 1 };
    var b = ListNode(u8){ .data = 2 };
    var c = ListNode(u8){ .data = 3 };

    var list = LinkedList(u8).init();

    try testing.expectEqual(@as(?*ListNode(u8), null), list.popBack());
    list.pushBack(&a);
    try testing.expectEqual(@as(usize, 1), list.len);
    list.pushBack(&b);
    try testing.expectEqual(@as(usize, 2), list.len);
    list.pushBack(&c);
    try testing.expectEqual(@as(usize, 3), list.len);

    try testing.expectEqual(@as(u8, 3), list.popBack().?.data);
    try testing.expectEqual(@as(usize, 2), list.len);
    try testing.expectEqual(@as(u8, 2), list.popBack().?.data);
    try testing.expectEqual(@as(usize, 1), list.len);
    try testing.expectEqual(@as(u8, 1), list.popBack().?.data);
    try testing.expectEqual(@as(usize, 0), list.len);

    try testing.expectEqual(@as(?*ListNode(u8), null), list.popBack());
}

test "insert/remove" {
    var a = ListNode(u8){ .data = 1 };
    var b = ListNode(u8){ .data = 2 };
    var c = ListNode(u8){ .data = 3 };
    var d = ListNode(u8){ .data = 4 };
    var e = ListNode(u8){ .data = 5 };

    var list = LinkedList(u8).init();

    list.insert(0, &a);
    try testing.expectEqual(@as(usize, 1), list.len);
    list.insert(1, &e);
    try testing.expectEqual(@as(usize, 2), list.len);
    list.insert(1, &b);
    try testing.expectEqual(@as(usize, 3), list.len);
    list.insert(2, &d);
    try testing.expectEqual(@as(usize, 4), list.len);
    list.insert(2, &c);
    try testing.expectEqual(@as(usize, 5), list.len);

    try testing.expectEqual(@as(u8, 3), list.remove(2).data);
    try testing.expectEqual(@as(usize, 4), list.len);
    try testing.expectEqual(@as(u8, 1), list.remove(0).data);
    try testing.expectEqual(@as(usize, 3), list.len);
    try testing.expectEqual(@as(u8, 5), list.remove(2).data);
    try testing.expectEqual(@as(usize, 2), list.len);
    try testing.expectEqual(@as(u8, 2), list.remove(0).data);
    try testing.expectEqual(@as(usize, 1), list.len);
    try testing.expectEqual(@as(u8, 4), list.remove(0).data);
    try testing.expectEqual(@as(usize, 0), list.len);
}
