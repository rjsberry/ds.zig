pub const test_deque = @import("test_deque.zig");
pub const test_linkedlist = @import("test_linkedlist.zig");
pub const test_vec = @import("test_vec.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
