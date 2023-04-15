const std = @import("std");
const Terminal = @import("terminal.zig");
const DB = @import("db.zig");
const ansi_term = @import("ansi-term");

pub fn main() !void {
    var term = try Terminal.init();
    var arena_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var alloc = arena_alloc.allocator();

    defer arena_alloc.deinit();

    var db = try DB.init(alloc);
    defer db.deinit();

    const entries = try db.read(alloc);
    for (entries) |i| {
        term.writeln("{s}", .{i});
    }

    term.write("\n--> ");

    while (true) {
        const str = try term.read();
        term.write(str);
    }
}
