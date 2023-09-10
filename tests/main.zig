pub const test_vec = @import("test_vec.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
