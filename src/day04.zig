const std = @import("std");
const print = std.debug.print;
const data = @embedFile("day04.txt");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("result: {d}\n", .{try solve(data)});
}

fn solve(input: []const u8) !u64 {
    var timer = std.time.Timer.start() catch unreachable;
    defer print("Took: {d}\n", .{timer.read()});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    var rows = ArrayList([]const u8).init(allocator);
    defer rows.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try rows.append(line);
    }

    const grid = rows.items;
    
    return countWordOccurances(grid, "XMAS");
}
fn searchInDirection(grid: [][]const u8, row: usize, col: usize, rowDir: isize, colDir: isize, word: []const u8) bool {
    const row_count = grid.len;
    const col_count = grid[0].len;

    for (0..word.len) |i| {
        const nrow = @as(isize, @as(isize, @intCast(row)) + @as(isize, @intCast(i)) * rowDir);
        if (nrow < 0) {
            return false;
        }
        const newRow: usize = @intCast(@as(isize, @as(isize, @intCast(row)) + @as(isize, @intCast(i)) * rowDir));
        const ncol = @as(isize, @as(isize, @intCast(col)) + @as(isize, @intCast(i)) * colDir);
        if (ncol < 0) {
            return false;
        }
        const newCol: usize = @intCast(@as(isize, @as(isize, @intCast(col)) + @as(isize, @intCast(i)) * colDir));
        if (newRow >= row_count or newCol >= col_count or grid[newRow][newCol] != word[i]) {
            return false;
        }
    }
    return true;
}

fn countWordOccurances(grid: [][]const u8, word: []const u8) u64 {
    var count: u64 = 0;

    for (0..grid.len) |row| {
        for (0..grid[0].len) |col| {
            if (grid[row][col] == word[0]) {
                if (searchInDirection(grid, row, col, 0, 1, word)) {
                    count += 1;
                } // Horizontal right
                if (searchInDirection(grid, row, col, 0, -1, word)) {
                    count += 1;
                } // Horizontal left
                if (searchInDirection(grid, row, col, 1, 0, word)) {
                    count += 1;
                } // Vertical down
                if (searchInDirection(grid, row, col, -1, 0, word)) {
                    count += 1;
                } // Vertical up
                if (searchInDirection(grid, row, col, 1, 1, word)) {
                    count += 1;
                } // Diagonal down-right
                if (searchInDirection(grid, row, col, -1, -1, word)) {
                    count += 1;
                } // Diagonal up-left
                if (searchInDirection(grid, row, col, 1, -1, word)) {
                    count += 1;
                } // Diagonal down-left
                if (searchInDirection(grid, row, col, -1, 1, word)) {
                    count += 1;
                }// Diagonal up-right
            }
        }
    }
    return count;
}

const example =
    \\MMMSXXMASM
    \\MSAMXMSMSA
    \\AMXSXMAAMM
    \\MSAMASMSMX
    \\XMASAMXAMM
    \\XXAMMXXAMA
    \\SMSMSASXSS
    \\SAXAMASAAA
    \\MAMMMXMMMM
    \\MXMXAXMASX
;
test "example part 1" {
    try std.testing.expectEqual(18, solve(example));
}
