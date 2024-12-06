const std = @import("std");
const print = std.debug.print;
const log = std.log;
const data = @embedFile("day06.txt");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ArrayHashMap = std.AutoArrayHashMap;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const map, const guard_pos = try parse(data, allocator);
    defer map.deinit();

    print("result: {d}\n", .{try solve(map, guard_pos, allocator)});
}

fn parse(input: []const u8, allocator: Allocator) !struct { ArrayList([]const u8), struct { isize, isize } } {
    var timer = std.time.Timer.start() catch unreachable;
    defer print("Took: {d} us\n", .{@as(f64, @floatFromInt(timer.read())) / 1000.0});

    var map = ArrayList([]const u8).init(allocator);

    var row_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var guard_pos: struct { isize, isize } = .{ 0, 0 };
    var row_idx: usize = 0;
    while (row_iter.next()) |row| : (row_idx += 1) {
        try map.append(row);
        for (row, 0..) |char, col_idx| {
            if (char == '^') {
                guard_pos = .{ @intCast(row_idx), @intCast(col_idx) };
            }
        }
    }

    return .{map, guard_pos};
}

fn solve(map: ArrayList([]const u8), guard: struct { isize, isize }, allocator: Allocator) !u64 {
    var guard_pos = guard;
    const row_len = map.items.len;
    const col_len = map.items[0].len;

    const dirs = [_][2]isize{ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
    var dir_idx: usize = 0;
    var positions = ArrayHashMap(struct { isize, isize }, void).init(allocator);
    defer positions.deinit();
    while (inRange(guard_pos, row_len, col_len)) {
        try positions.put(guard_pos, {});
        const curr_dir = dirs[dir_idx];
        const next_pos = .{ guard_pos[0] + curr_dir[0], guard_pos[1] + curr_dir[1] };
        if (!inRange(next_pos, row_len, col_len)) {
            break;
        }
        const next_row_idx: usize = @intCast(next_pos[0]);
        const next_col_idx: usize = @intCast(next_pos[1]);
        const next_pos_item = map.items[next_row_idx][next_col_idx];
        if (next_pos_item == '#') {
            dir_idx = (dir_idx + 1) % dirs.len;
        } else {
            guard_pos = next_pos;
        }
    }

    return positions.count();
}

fn inRange(pos: anytype, rows: usize, cols: usize) bool {
    const row_idx, const col_idx = pos;

    return row_idx >= 0 and row_idx < rows and col_idx >= 0 and col_idx < cols;
}

const example =
    \\....#.....
    \\.........#
    \\..........
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
;

test "example part 1" {
    const allocator = std.testing.allocator;
    
    const map, const guard_pos = try parse(example, allocator);
    defer map.deinit();

    try std.testing.expectEqual(41, try solve(map, guard_pos, allocator));
}
