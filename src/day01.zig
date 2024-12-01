const std = @import("std");
const testing = std.testing;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("woohoo!", .{});
}

test "basic add functionality" {
    try testing.expect(true);
}
