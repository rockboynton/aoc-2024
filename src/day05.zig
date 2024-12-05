const std = @import("std");
const print = std.debug.print;
const data = @embedFile("day05.txt");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("result: {d}\n", .{try solve(data)});
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

    var sections = std.mem.tokenizeSequence(u8, input, "\n\n");

    const rule_section = sections.next().?;
    // print("rules: {s}\n", .{rules});

    const update_section = sections.next().?;
    // print("pages: {s}\n", .{pages});

    var rules = std.mem.tokenizeScalar(u8, rule_section, '\n');
    // build the DAG
    var dag = HashMap(u8, HashMap(u8, void)).init((allocator));
    defer {
        var values = dag.valueIterator();
        while (values.next()) |value| {
            value.deinit();
        }
        
        dag.deinit();
    } 

    while (rules.next()) |rule| {
        var pages = std.mem.tokenizeScalar(u8, rule, '|');
        const u = try std.fmt.parseInt(u8, pages.next().?, 10);
        const v = try std.fmt.parseInt(u8, pages.next().?, 10);

        const adjacency_list = try dag.getOrPutValue(u, HashMap(u8, void).init(allocator));
        try adjacency_list.value_ptr.*.put(v, {});
    }

    var items = dag.iterator();
    while (items.next()) |item| {
        var values = item.value_ptr.*.keyIterator();
        print("key: {d}, values: ", .{item.key_ptr.*});
        while (values.next()) |value| {
            print("{d}, ", .{value.*});
        }
        print("\n", .{});
        
    }

    // topologically sort the DAG
    const sorted_pages = try topologicalSort(&dag, allocator);

    var index_map = HashMap(u8, u8).init(allocator);
    defer index_map.deinit();
    
    for (sorted_pages.items, 0..) |page, i| {
        try index_map.put(page, @intCast(i));
    }

    // get result
    var updates = std.mem.tokenizeScalar(u8, update_section, '\n');
    var sum: u64 = 0;
    update_loop: while (updates.next()) |update| {
        var pages = ArrayList(u8).init(allocator);
        defer pages.deinit();

        var page_iter = std.mem.tokenizeScalar(u8, update, ',');
        while (page_iter.next()) |page| {
            const p = try std.fmt.parseInt(u8, page, 10);
            try pages.append(p);
        }

        var edges = std.mem.window(u8, pages.items, 2, 1);
        while (edges.next()) |pair| {
            if (index_map.get(pair[0]) != null and index_map.get(pair[1]) != null) {
                if (index_map.get(pair[0]).? > index_map.get(pair[1]).?) {
                    continue :update_loop;
                }
            }
        }

        sum += pages.items[pages.items.len / 2];
    }
    

    return sum;
}

fn dfs(node: u8, dag: *HashMap(u8, HashMap(u8, void)), visited: *HashMap(u8, void), stack: *ArrayList(u8)) !void {
    const res = try visited.*.getOrPut(node);
    if (res.found_existing) {
        return;
    }

    print("{d}\n", .{node});
    const n = dag.*.get(node) orelse return;
    var neighbors = n.keyIterator();
    while (neighbors.next()) |neighbor| {
        try dfs(neighbor.*, dag, visited, stack);
    }

    try stack.append(node);
}

fn topologicalSort(dag: *HashMap(u8, HashMap(u8, void)), allocator: Allocator) !std.ArrayList(u8) {
    var visited = HashMap(u8, void).init(allocator);
    defer visited.deinit();

    var stack = std.ArrayList(u8).init(allocator);

    // Perform DFS for each node
    var keys = dag.*.keyIterator();
    while (keys.next()) |key| {
        if (visited.get(key.*) == null) {
            try dfs(key.*, dag, &visited, &stack);
        }
    }

    // Reverse the stack to get the topological order
    std.mem.reverse(u8, stack.items);

    return stack;
}

const example =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;

test "example part 1" {
    try std.testing.expectEqual(143, solve(example));
}

