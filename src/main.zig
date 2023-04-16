const std = @import("std");
const App = @import("app.zig").App;
const Terminal = @import("terminal.zig");
const DB = @import("db.zig");
const ansi_term = @import("ansi-term");

const Actions = enum { add };
const Command = union(Actions) { add: []const u8 };
fn parseArgs(args: [][:0]const u8) ?Command {
    for (args[1..], 1..) |arg, idx| {
        if (std.mem.eql(u8, arg, "add") or std.mem.eql(u8, arg, "-a")) {
            if (idx + 1 >= args.len) {
                std.log.err("provide path to be added", .{});
                std.process.exit(1);
            }
            const dir = args[idx + 1];

            return Command{ .add = dir };
        }
    }

    return null;
}

pub fn main() !void {
    var arena_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_alloc.deinit();
    var alloc = arena_alloc.allocator();
    var db = try DB.init(alloc);

    var args = std.process.argsAlloc(alloc) catch return;
    defer std.process.argsFree(alloc, args);

    const writer = std.io.getStdOut().writer();
    if (args.len > 1) {
        const command = parseArgs(args).?;
        switch (command) {
            .add => |dir| {
                const real_path = db.addEntry(dir) catch {
                    std.log.err("unable to add entry", .{});
                    std.process.exit(1);
                };
                try writer.print("added {s}", .{real_path});
            },
        }

        return;
    }

    var term = try Terminal.init();
    var app = App.init(.num, term, db);
    try app.run(alloc);
}
