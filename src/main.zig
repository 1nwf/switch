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
    for (entries, 0..) |i, idx| {
        term.writeln("{}. {s}", .{ idx + 1, i });
    }

    while (true) {
        const str = try term.read();
        var val = std.fmt.parseInt(usize, str, 0) catch {
            continue;
        };
        if (val > entries.len or val <= 0) {
            continue;
        }
        term.deinit();
        try std.io.getStdOut().writeAll(entries[val - 1]);
        return;
    }
}
