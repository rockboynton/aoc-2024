const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const data = @embedFile("day01.txt");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("result: {d}\n", .{try part1(data)});
    try stdout.print("result: {d}\n", .{try part2(data)});
}

fn part1(input: []const u8) !i64 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    var lefts = ArrayList(i64).init(allocator);
    defer lefts.deinit();

    var rights = ArrayList(i64).init(allocator);
    defer rights.deinit();

    var lines = std.mem.splitSequence(u8, input, "\n");
    while (lines.next()) |line| {
        var it = std.mem.splitSequence(u8, line, "   ");

        const left = it.next().?;
        try lefts.append(try std.fmt.parseInt(i64, left, 10));

        const right = it.next().?;
        try rights.append(try std.fmt.parseInt(i64, right, 10));
    }

    std.sort.heap(i64, lefts.items[0..lefts.items.len], {}, comptime std.sort.asc(i64));
    std.sort.heap(i64, rights.items[0..rights.items.len], {}, comptime std.sort.asc(i64));

    const len = lefts.items.len;

    var i: usize = 0;
    var sum: i64 = 0;
    while (i < len) : (i += 1) {
        const diff = rights.items[i] - lefts.items[i];
        const abs_diff = if (diff < 0) -diff else diff;
        sum += abs_diff;
    }

    return sum;
}

fn part2(input: []const u8) !i64 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    var lefts = ArrayList(i64).init(allocator);
    defer lefts.deinit();

    var rights = ArrayList(i64).init(allocator);
    defer rights.deinit();

    var right_map = std.AutoHashMap(i64, i64).init(allocator);
    defer right_map.deinit();

    var lines = std.mem.splitSequence(u8, input, "\n");
    while (lines.next()) |line| {
        var it = std.mem.splitSequence(u8, line, "   ");

        const left = it.next().?;
        try lefts.append(try std.fmt.parseInt(i64, left, 10));

        const right = it.next().?;
        try rights.append(try std.fmt.parseInt(i64, right, 10));

        const right_int = try std.fmt.parseInt(i64, right, 10);

        if (right_map.get(right_int)) |count| {
            try right_map.put(right_int, count + 1);
        } else {
            try right_map.put(right_int, 1);
        }

    }
    const len = lefts.items.len;

    var i: usize = 0;
    var sum: i64 = 0;
    while (i < len) : (i += 1) {
        const left = lefts.items[i];
        const similarity_score = left * (right_map.get(left) orelse 0);
        sum += similarity_score;
    }

    return sum;
}

const example =
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
;
test "example part 1" {
    try std.testing.expectEqual(11, part1(example));
}

test "example part 2" {
    try std.testing.expectEqual(31, part2(example));
}
