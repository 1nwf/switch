const std = @import("std");
const Terminal = @import("terminal.zig");
const Mode = enum { num, search };
const DB = @import("db.zig");
pub const App = struct {
    mode: Mode,
    term: Terminal,
    db: DB,
    pub fn init(mode: Mode, term: Terminal, db: DB) App {
        return App{
            .mode = mode,
            .term = term,
            .db = db,
        };
    }

    pub fn run(
        self: *App,
    ) ![]const u8 {
        defer self.deinit();

        const entries = self.db.entries;
        for (entries, 0..) |dir, idx| {
            _ = self.term.writer.print("{}. {s}", .{ idx + 1, dir }) catch {};
            self.term.writeln("", .{});
        }

        self.term.write("=> ", .{});

        while (true) {
            const str = try self.term.read();
            var val = std.fmt.parseInt(usize, str, 0) catch {
                continue;
            };
            if (val > self.db.entries.len or val <= 0) {
                continue;
            }

            const white = .{ .RGB = .{ .r = 0xff, .g = 0xff, .b = 0xff } };
            self.term.setLineStyle(entries.len, val - 1, white, .Red, entries[val - 1]);
            self.term.write("{}", .{val});
            std.time.sleep(50_000_000);
            self.term.clearLines(entries.len);
            return entries[val - 1];
        }
    }

    pub fn deinit(self: *App) void {
        self.term.deinit();
        self.db.deinit();
    }
};
