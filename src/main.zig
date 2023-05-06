const std = @import("std");
const App = @import("app.zig").App;
const Terminal = @import("terminal.zig");
const DB = @import("db.zig");
const ansi_term = @import("ansi-term");

const Command = union(enum) { add: []const u8, rm: []const u8, reset, help, sync };

const helpMenu =
    \\Usage: sw [options]
    \\ 
    \\add/a [directory] - adds a directory to the list
    \\remove/rm [directory] - removes a directory from the list
    \\help -- shows this help menu
;

fn parseArgs(args: *std.process.ArgIterator) !?Command {
    _ = args.skip();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "add") or std.mem.eql(u8, arg, "a")) {
            if (args.next()) |dir| {
                return Command{ .add = dir };
            } else {
                std.log.err("provide path to be added", .{});
                return error.InvalidCmd;
            }
        } else if (std.mem.eql(u8, arg, "remove") or std.mem.eql(u8, arg, "rm")) {
            if (args.next()) |dir| {
                return Command{ .rm = dir };
            } else {
                std.log.err("provide path to be removed", .{});
                return error.InvalidCmd;
            }
        } else if (std.mem.eql(u8, arg, "reset")) {
            return .reset;
        } else if (std.mem.eql(u8, arg, "help")) {
            return .help;
        } else if (std.mem.eql(u8, arg, "sync")) {
            return .sync;
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
    const command = parseArgs(&args) catch {
        return;
    };
    if (command) |cmd| {
        switch (cmd) {
            .add => |dir| {
                const real_path = db.addEntry(dir) catch {
                    std.log.err("unable to add entry", .{});
                    return;
                };
                try stdout.print("added {s}", .{real_path});
            },
            .rm => |dir| {
                const real_path = db.removeEntry(dir) catch {
                    std.log.err("unable to remove entry", .{});
                    return;
                };
                try stdout.print("removed {s}", .{real_path});
            },
            .reset => {
                try db.deleteAll();
            },
            .help => {
                try stdout.print("{s}\n", .{helpMenu});
            },
            .sync => {
                try db.sync();
            },
        }
        return;
    }

    var term = try Terminal.init();
    var app = try App.init(term, db);

    const selection = try app.run();
    if (selection) |val| {
        try stdout.print("{s}\n", .{val});
    }
}
