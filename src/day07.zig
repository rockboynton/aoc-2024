const std = @import("std");
const print = std.debug.print;
const log = std.log;
const data = @embedFile("day07.txt");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;
const ArrayHashMap = std.AutoArrayHashMap;

pub fn main() !void {
    print("result: {d}\n", .{try solve(data)});
}

fn cartesianPower(map: *ArrayList([]u8), tmpArr: []u8, m: usize, n: usize, allocator: Allocator) !void {
    const arr = "*+";
    if (m == arr.len - 2 + n) {
        try map.*.append(try allocator.dupe(u8, tmpArr));
    } else {
        for (arr) |value| {
            tmpArr[m] = value;
            try cartesianPower(&map.*, tmpArr, m + 1, n, allocator);
        }
    }
}

fn solve(input: []const u8) !u64 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    var timer = std.time.Timer.start() catch unreachable;
    defer print("Took: {d} us\n", .{@as(f64, @floatFromInt(timer.read())) / 1000.0});

    var equations = std.mem.tokenizeScalar(u8, input, '\n');

    var calibration_result: u64 = 0;
    while (equations.next()) |equation| {
        var parts = std.mem.tokenizeScalar(u8, equation, ':');
        const target = try std.fmt.parseInt(u64, parts.next().?, 10);
        // print("target: {d}\n", .{target});
        var op_iter = std.mem.tokenizeScalar(u8, parts.next().?, ' ');

        var num_operands: u64 = 0;
        while (op_iter.next()) |_| {
            num_operands += 1;
        }
        num_operands -= 1;
        op_iter.reset();

        var m = ArrayList([]u8).init(allocator);
        defer {
            for (m.items) |item| {
            //     item.deinit();
            allocator.free(item);
            }
            m.deinit();
        }
        var tmpArr = ArrayList(u8).init(allocator);
        for (0..num_operands) |_| {
            try tmpArr.append(0);
        }
        defer tmpArr.deinit();

        try cartesianPower(&m, tmpArr.items[0..], 0, num_operands, allocator);

        for (m.items) |operators| {
            var res: u128 = try std.fmt.parseInt(u128, op_iter.next().?, 10); 
            // print("start: {d} ", .{res});
            defer op_iter.reset();
            
            var op_idx: u64 = 0;

            while (op_iter.next()) |operand_i| : (op_idx += 1) {
                if (op_idx == num_operands) {
                    break;
                }
                const operand_num: u128 = try std.fmt.parseInt(u128, operand_i, 10); 
                if (operators[op_idx] == '+') {
                    // print("+", .{});
                    res += operand_num;
                } else {
                    // print("*", .{});
                    res *= operand_num;
                }

                if (res > target) {
                    break;
                }
            }
            if (res == target) {
                calibration_result += target;
                print("{}\n", .{target});
                break;
            }
            // print("\n", .{});
        }
    }

    return calibration_result;
}

const example =
    \\190: 10 19
    \\3267: 81 40 27
    \\83: 17 5
    \\156: 15 6
    \\7290: 6 8 6 15
    \\161011: 16 10 13
    \\192: 17 8 14
    \\21037: 9 7 18 13
    \\292: 11 6 16 20
;

test "example part 1" {
    try std.testing.expectEqual(3749, solve(example));
}

