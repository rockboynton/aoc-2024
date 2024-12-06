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

    var obstructed_map = ArrayList(ArrayList(u8)).init(allocator);
    defer {
        for (obstructed_map.items) |*row| {
            row.*.deinit();
        } 
        obstructed_map.deinit();
    }

    for (map.items) |row| {
        var orow = ArrayList(u8).init(allocator);
        for (row) |char| {
            try orow.append(char);
        }
        try obstructed_map.append(orow);
    }

    const res, _ = try solve(obstructed_map, guard_pos, allocator);

    var timer = std.time.Timer.start() catch unreachable;

    print("result: {d}\n", .{res});
    print("Took: {d} us\n", .{@as(f64, @floatFromInt(timer.read())) / 1000.0});
    timer = std.time.Timer.start() catch unreachable;
    print("result: {d}\n", .{try solve2(obstructed_map, guard_pos, allocator)});
    print("Took: {d} us\n", .{@as(f64, @floatFromInt(timer.read())) / 1000.0});
}

fn parse(input: []const u8, allocator: Allocator) !struct { ArrayList([]const u8), struct { isize, isize } } {
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

const dirs = [_][2]isize{ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };

fn solve(map: ArrayList(ArrayList(u8)), initial_guard_pos: struct { isize, isize }, allocator: Allocator) !struct {u64, bool}  {
    var guard_pos = initial_guard_pos;
    const row_len = map.items.len;
    const col_len = map.items[0].items.len;

    var dir_idx: usize = 0;
    var positions_with_dir = ArrayHashMap([2]struct { isize, isize }, void).init(allocator);
    var positions = ArrayHashMap(struct { isize, isize }, void).init(allocator);
    defer positions.deinit();
    var would_cycle = false;
    var iter: u64 = 0;
    while (inRange(guard_pos, row_len, col_len))  {
        defer iter += 1;
        if (positions_with_dir.get(.{guard_pos, .{ dirs[dir_idx][0], dirs[dir_idx][1]}}) != null) {
            would_cycle = true;
            break;
        }
        try positions.put(guard_pos, {});
        try positions_with_dir.put(.{guard_pos, .{ dirs[dir_idx][0], dirs[dir_idx][1]}}, {});
        guard_pos, dir_idx = getNextPosition(map, guard_pos, dir_idx);
        // print("{d}: guard pos: {d},{d}, dir {any}\n", .{iter, guard_pos[0], guard_pos[1], dirs[dir_idx]});
        // print("guard pos: {any}\n", .{positions.keys()});
    }

    return .{positions.count(), would_cycle};
}

fn getNextPosition(map: ArrayList(ArrayList(u8)), initial_guard_pos: struct { isize, isize }, initial_dir_idx: usize) struct {struct {isize, isize}, usize}  {
    var next_pos = initial_guard_pos;
    var next_dir_idx = initial_dir_idx;

    var forward_pos_item: u8 = '#';
    var forward_dir = dirs[next_dir_idx];
    var forward_pos = .{ initial_guard_pos[0] + forward_dir[0], initial_guard_pos[1] + forward_dir[1] };
    while (true) {
        forward_dir = dirs[next_dir_idx];
        forward_pos = .{ initial_guard_pos[0] + forward_dir[0], initial_guard_pos[1] + forward_dir[1] };
        const next_row_idx: usize = @intCast(forward_pos[0]);
        const next_col_idx: usize = @intCast(forward_pos[1]);
        if (!inRange(forward_pos, map.items.len, map.items[0].items.len)) {
            return .{forward_pos, next_dir_idx};
        }
        forward_pos_item = map.items[next_row_idx].items[next_col_idx]; 
        if (forward_pos_item == '#') {
            // print("forward pos: {d},{d}, dir {any}\n", .{forward_pos[0], forward_pos[1], forward_dir});
            next_dir_idx = (next_dir_idx + 1) % dirs.len;
        } else {
            next_pos = forward_pos;
            break;
        }
    }
    return .{next_pos, next_dir_idx};
}

fn solve2(obstructed_map: ArrayList(ArrayList(u8)), initial_guard_pos: struct { isize, isize }, allocator: Allocator) !u64 {
    var solves_with_cycles: u64 = 0;
    var solves: u64 = 0;
    for (0..obstructed_map.items.len) |r| {
        for (0..obstructed_map.items[0].items.len) |p| {
            const val = obstructed_map.items[r].items[p];
            if (val != '^') {
                obstructed_map.items[r].items[p] = '#';
                _, const cycle_detected = try solve(obstructed_map, initial_guard_pos, allocator);
                solves += 1;
                // print("num solves: {d}\n", .{solves});
                if (cycle_detected) {
                    // print("cycle det when obs at {d},{d}\n", .{r, p});
                    solves_with_cycles += 1;
                }
                obstructed_map.items[r].items[p] = val;
            }
        }
    }

    return solves_with_cycles;
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

    var obstructed_map = ArrayList(ArrayList(u8)).init(allocator);
    defer {
        for (obstructed_map.items) |*row| {
            row.*.deinit();
        } 
        obstructed_map.deinit();
    }
    for (map.items) |row| {
        var orow = ArrayList(u8).init(allocator);
        for (row) |char| {
            try orow.append(char);
        }
        try obstructed_map.append(orow);
    }
    const res, _ = try solve(obstructed_map, guard_pos, allocator);

    try std.testing.expectEqual(41, res);
}

test "example part 2" {
    const allocator = std.testing.allocator;
    
    const map, const guard_pos = try parse(example, allocator);
    defer map.deinit();

    var obstructed_map = ArrayList(ArrayList(u8)).init(allocator);
    defer {
        for (obstructed_map.items) |*row| {
            row.*.deinit();
        } 
        obstructed_map.deinit();
    }

    print("trying part 2", .{});
    for (map.items) |row| {
        var orow = ArrayList(u8).init(allocator);
        for (row) |char| {
            try orow.append(char);
        }
        try obstructed_map.append(orow);
    }

    print("trying part 2, 2", .{});
    try std.testing.expectEqual(6, try solve2(obstructed_map, guard_pos, allocator));
}
