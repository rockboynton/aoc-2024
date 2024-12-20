const std = @import("std");
const print = std.debug.print;
const log = std.log;
const data = @embedFile("day05.txt");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;
const ArrayHashMap = std.AutoArrayHashMap;

pub fn main() !void {
    print("result: {d}\n", .{try solve(data, false)});
    print("result: {d}\n", .{try solve(data, true)});
}

fn print_map(map: HashMap(u8, HashMap(u8, void))) void {
    var items = map.iterator();
    while (items.next()) |item| {
        var values = item.value_ptr.*.keyIterator();
        print("key: {d}, values: ", .{item.key_ptr.*});
        while (values.next()) |value| {
            print("{d}, ", .{value.*});
        }
        print("\n", .{});
    }
}

fn solve(input: []const u8, sum_invalids: bool) !u64 {
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

    const update_section = sections.next().?;

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
        log.debug("u: {d}, v: {d}\n", .{u, v});

        const adjacency_list = try dag.getOrPutValue(u, HashMap(u8, void).init(allocator));
        try adjacency_list.value_ptr.*.put(v, {});
        if (dag.get(v) == null) {
            try dag.put(v, HashMap(u8, void).init(allocator));
        }
    }

    // print_map(dag);

    // get result
    var updates = std.mem.tokenizeScalar(u8, update_section, '\n');
    var sum: u64 = 0;
    var invalid_updates = ArrayList(ArrayList(u8)).init(allocator);
    defer {
        for (invalid_updates.items) |u| {
            u.deinit();
        }
        invalid_updates.deinit();
    }

    update_loop: while (updates.next()) |update| {
        log.debug("trying a update\n", .{});
        var pages = ArrayList(u8).init(allocator);

        var page_iter = std.mem.tokenizeScalar(u8, update, ',');
        var sub_dag = HashMap(u8, HashMap(u8, void)).init((allocator));
        defer {
            sub_dag.deinit();
        } 

        while (page_iter.next()) |page| {
            const p = try std.fmt.parseInt(u8, page, 10);
            const l = dag.get(p).?;
            try sub_dag.put(p, l);
            try pages.append(p);
        }

        // print_map(sub_dag);

        // topologically sort the DAG
        const sorted_pages = try topologicalSort(&sub_dag, allocator);
        defer sorted_pages.deinit();

        var index_map = HashMap(u8, u8).init(allocator);
        defer index_map.deinit();
    
        for (sorted_pages.items, 0..) |page, i| {
            log.debug("putting index map: k:{d}, v:{d}\n", .{page, i});
            try index_map.put(page, @intCast(i));
        }


        var edges = std.mem.window(u8, pages.items, 2, 1);
        log.debug("pages: {any}\n", .{pages.items});
        while (edges.next()) |pair| {
            if (index_map.get(pair[0]).? > index_map.get(pair[1]).?) {
                try invalid_updates.append(pages);
                continue :update_loop;
            }
        }

        log.debug("page item to sum: {d}\n", .{pages.items[pages.items.len / 2]});
        sum += pages.items[pages.items.len / 2];
        pages.deinit();
    }

    var invalid_sum: u64 = 0;
    for (invalid_updates.items) |update| {
        // print("update: {any}\n", .{update.items});
        var sub_dag = HashMap(u8, HashMap(u8, void)).init((allocator));
        defer {
            sub_dag.deinit();
        } 

        var page_set = HashMap(u8, void).init(allocator);
        defer page_set.deinit();
        for (update.items) |p| {
            try page_set.put(p, {});
            const l = dag.get(p).?;
            try sub_dag.put(p, l);
        }

        const sorted_pages = try topologicalSort(&sub_dag, allocator);
        defer sorted_pages.deinit();

        var orig_pages = ArrayHashMap(u8, void).init(allocator);
        defer orig_pages.deinit();

        for (sorted_pages.items) |page| {
            if (page_set.get(page) != null) {
                try orig_pages.put(page, {});
            }
        }

        // print("sorted update: {any}\n", .{orig_pages.keys()});

        invalid_sum += orig_pages.keys()[orig_pages.keys().len / 2];
    }
    

    return if (sum_invalids) invalid_sum else sum;
}

fn dfs(node: u8, dag: *HashMap(u8, HashMap(u8, void)), visited: *HashMap(u8, void), stack: *ArrayList(u8)) !void {
    try visited.*.put(node, {});

    if (dag.*.get(node)) |neighbors| {
        var iter = neighbors.keyIterator(); 
        while (iter.next()) |neighbor| {
            if (visited.get(neighbor.*) == null) {
                try dfs(neighbor.*, dag, visited, stack);
            }
        }
    }

    try stack.append(node);
}

fn topologicalSort(dag: *HashMap(u8, HashMap(u8, void)), allocator: Allocator) !ArrayList(u8) {
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
    try std.testing.expectEqual(143, solve(example, false));
}

test "example part 2" {
    try std.testing.expectEqual(123, solve(example, true));
}

