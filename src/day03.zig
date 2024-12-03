const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const data = @embedFile("day03.txt");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("result: {d}\n", .{try part1(data)});
    try stdout.print("result: {d}\n", .{try part2(data)});
}

fn part1(input: []const u8) !u64 {
    var sum: u64 = 0;
    var i: u64 = 4;
    while (i < input.len - 3) {
        defer i += 1;
        const left = (std.fmt.parseInt(u64, input[i .. i + 3], 10)) catch blk: {
            break :blk std.fmt.parseInt(u64, input[i .. i + 2], 10) catch blk2: {
                break :blk2 std.fmt.parseInt(u64, input[i .. i + 1], 10) catch {
                    continue;
                };
            };
        };

        if (!std.mem.eql(u8, "mul(", input[i - 4 .. i])) {
            continue;
        }

        print("len: {d}\n", .{number_of_digits(left)});

        i += number_of_digits(left) + 1;
        print("left {d}\n", .{left});

        const right = (std.fmt.parseInt(u64, input[i .. i + 3], 10)) catch blk: {
            break :blk std.fmt.parseInt(u64, input[i .. i + 2], 10) catch blk2: {
                break :blk2 std.fmt.parseInt(u64, input[i .. i + 1], 10) catch {
                    continue;
                };
            };
        };

        i += number_of_digits(right);
        print("right {d}\n", .{right});

        if (!std.mem.eql(u8, ")", input[i .. i + 1])) {
            continue;
        }

        print("{d} * {d}\n", .{ left, right });

        sum += left * right;
    }

    return sum;
}

fn part2(input: []const u8) !u64 {
    var sum: u64 = 0;
    var i: u64 = 4;
    var enabled = true;
    while (i < input.len - 3) {
        defer i += 1;
        if (i + 7 <= input.len and std.mem.eql(u8, "don't()", input[i .. i + 7])) {
            i += 6;
            enabled = false;
            continue;
        } else if (i + 4 <= input.len and std.mem.eql(u8, "do()", input[i .. i + 4])) {
            i += 3;
            enabled = true;
            continue;
        }
        
        const left = (std.fmt.parseInt(u64, input[i .. i + 3], 10)) catch blk: {
            break :blk std.fmt.parseInt(u64, input[i .. i + 2], 10) catch blk2: {
                break :blk2 std.fmt.parseInt(u64, input[i .. i + 1], 10) catch {
                    continue;
                };
            };
        };

        if (!std.mem.eql(u8, "mul(", input[i - 4 .. i])) {
            continue;
        }

        print("len: {d}\n", .{number_of_digits(left)});

        i += number_of_digits(left) + 1;
        print("left {d}\n", .{left});

        const right = (std.fmt.parseInt(u64, input[i .. i + 3], 10)) catch blk: {
            break :blk std.fmt.parseInt(u64, input[i .. i + 2], 10) catch blk2: {
                break :blk2 std.fmt.parseInt(u64, input[i .. i + 1], 10) catch {
                    continue;
                };
            };
        };

        i += number_of_digits(right);
        print("right {d}\n", .{right});

        if (!std.mem.eql(u8, ")", input[i .. i + 1])) {
            continue;
        }

        print("{d} * {d}\n", .{ left, right });

        if (enabled) {
            sum += left * right;
        }
    }

    return sum;
}

fn number_of_digits(n: u64) u64 {
    var count: u64 = 0;
    var i: u64 = n;
    while (i != 0) {
        i /= 10;
        count += 1;
    }
    return count;
}

const example =
    \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
;

const example2 =
    \\xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
;
test "example part 1" {
    try std.testing.expectEqual(161, part1(example));
}

test "example part 2" {
    try std.testing.expectEqual(48, part2(example2));
}
