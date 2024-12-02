
const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const data = @embedFile("day02.txt");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("result: {d}\n", .{try part1(data)});
}

fn part1(input: []const u8) !i64 {
    var reports = std.mem.splitSequence(u8, input, "\n");
    var safe_levels: i64 = 0;
    while (reports.next()) |report| {
        var levels = std.mem.splitSequence(u8, report, " ");
        const l1 = levels.next().?;
        var prev_level = try std.fmt.parseInt(i64, l1, 10);
        var increasing = true; 
        var decreasing = true; 
        var report_is_safe = true;
        while (levels.next()) |l| {
            const level = try std.fmt.parseInt(i64, l, 10);
            increasing = increasing and (level > prev_level);
            decreasing = decreasing and (prev_level > level);
            const delta = level - prev_level;
            const abs_delta = if (delta > 0) delta else -delta;
            const small_delta = abs_delta > 0 and abs_delta < 4;
            const level_is_safe = small_delta and (increasing or decreasing);
            if (!level_is_safe) {
                report_is_safe = false;
                break;
            }
            prev_level = level;
        }
        if (report_is_safe) {
            safe_levels += 1;
        }
    }

    return safe_levels;
}

const example =
    \\7 6 4 2 1
    \\1 2 7 8 9
    \\9 7 6 2 1
    \\1 3 2 4 5
    \\8 6 4 4 1
    \\1 3 6 7 9
;
test "example part 1" {
    try std.testing.expectEqual(2, part1(example));
}
