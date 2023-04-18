const std = @import("std");
const App = @import("app.zig").App;
const Terminal = @import("terminal.zig");
const DB = @import("db.zig");
const ansi_term = @import("ansi-term");

const Command = union(enum) {
    add: []const u8,
    rm: []const u8,
    reset,
};
fn parseArgs(args: *std.process.ArgIterator) ?Command {
    _ = args.skip();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "add") or std.mem.eql(u8, arg, "a")) {
            if (args.next()) |dir| {
                return Command{ .add = dir };
            } else {
                std.log.err("provide path to be added", .{});
                std.process.exit(1);
            }
        } else if (std.mem.eql(u8, arg, "remove") or std.mem.eql(u8, arg, "rm")) {
            if (args.next()) |dir| {
                return Command{ .rm = dir };
            } else {
                std.log.err("provide path to be removed", .{});
                std.process.exit(1);
            }
        } else if (std.mem.eql(u8, arg, "reset")) {
            return .reset;
        }
    }

    return null;
}

pub fn main() !void {
    var arena_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_alloc.deinit();
    var alloc = arena_alloc.allocator();
    var db = try DB.init(alloc);

    var args = std.process.argsWithAllocator(alloc) catch unreachable;
    defer args.deinit();

    const stdout = std.io.getStdOut().writer();
    const command = parseArgs(&args);
    if (command) |cmd| {
        switch (cmd) {
            .add => |dir| {
                const real_path = db.addEntry(dir) catch {
                    std.log.err("unable to add entry", .{});
                    std.process.exit(1);
                };
                try stdout.print("added {s}", .{real_path});
            },
            .rm => |dir| {
                const real_path = db.removeEntry(dir) catch {
                    std.log.err("unable to remove entry", .{});
                    std.process.exit(1);
                };
                try stdout.print("removed {s}", .{real_path});
            },
            .reset => {
                try db.deleteAll();
            },
        }
        return;
    }

    var term = try Terminal.init();
    var app = App.init(.num, term, db);

    const selection = try app.run();
    try stdout.print("{s}\n", .{selection});
}
