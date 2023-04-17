const std = @import("std");
const Terminal = @import("terminal.zig");
const Mode = enum { num, search };
const DB = @import("db.zig");
pub const App = struct {
    mode: Mode,
    term: Terminal,
    db: DB,
    entries: [][]const u8 = undefined,
    pub fn init(mode: Mode, term: Terminal, db: DB) App {
        return App{
            .mode = mode,
            .term = term,
            .db = db,
        };
    }

    pub fn run(self: *App, alloc: std.mem.Allocator) !void {
        defer self.deinit();
        self.entries = try self.db.read(alloc);
        for (self.entries, 0..) |dir, idx| {
            _ = self.term.writer.print("{}. {s}", .{ idx + 1, dir }) catch {};
            self.term.writeln("", .{});
        }

        self.term.write("=> ", .{});

        while (true) {
            const str = try self.term.read();
            var val = std.fmt.parseInt(usize, str, 0) catch {
                continue;
            };
            if (val > self.entries.len or val <= 0) {
                continue;
            }

            const white = .{ .RGB = .{ .r = 0xff, .g = 0xff, .b = 0xff } };
            self.term.setLineStyle(self.entries.len, val - 1, white, .Red, self.entries[val - 1]);
            std.time.sleep(60_000_000);
            self.term.clearLines(self.entries.len);
            try std.io.getStdOut().writeAll(self.entries[val - 1]);
            return;
        }
    }

    pub fn deinit(self: *App) void {
        self.term.deinit();
        self.db.deinit();
    }
};
