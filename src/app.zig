const std = @import("std");
const Terminal = @import("terminal.zig");
const Mode = enum { num, search };
const DB = @import("db.zig");
pub const App = struct {
    mode: Mode,
    term: Terminal,
    db: DB,
    selection: usize = 0,

    const SelectionBackground = .{ .foreground = .{ .RGB = .{ .r = 0xff, .g = 0xff, .b = 0xff } }, .background = .Red };
    pub fn init(mode: Mode, term: Terminal, db: DB) App {
        return App{ .mode = mode, .term = term, .db = db, .selection = db.entries.len };
    }

    fn writeEntries(self: *App) void {
        const entries = self.db.entries;
        for (entries, 0..) |dir, idx| {
            if (idx == self.selection) {
                self.term.writer.print("* ", .{}) catch {};
            }
            _ = self.term.writer.print("{}. {s}", .{ idx + 1, dir }) catch {};
            self.term.writeln("", .{});
        }
        self.term.write("=> ", .{});
    }
    pub fn run(
        self: *App,
    ) ![]const u8 {
        defer self.deinit();

        const entries = self.db.entries;
        self.writeEntries();

        while (true) {
            const str = try self.term.read();
            var val: usize = 0;
            if (std.mem.eql(u8, str, "j")) {
                self.selectDown();
                continue;
            } else if (std.mem.eql(u8, str, "k")) {
                self.selectUp();
                continue;
            } else if (std.mem.eql(u8, str, "\r")) {
                val = self.selection + 1;
            } else {
                val = std.fmt.parseInt(usize, str, 0) catch 0;
            }
            if (val > self.db.entries.len or val <= 0) {
                continue;
            }

            self.term.setLineStyle(entries.len, val - 1, App.SelectionBackground.foreground, App.SelectionBackground.background, entries[val - 1]);

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

    fn cursorUp(self: *App) void {
        if (self.selection == 0) {
            return;
        }
        self.selection -= 1;
    }

    fn cursorDown(self: *App) void {
        if (self.selection >= self.db.entries.len) {
            return;
        }
        self.selection += 1;
    }

    fn selectUp(self: *App) void {
        self.term.clearLines(self.db.entries.len);
        self.cursorUp();
        self.writeEntries();
    }

    fn selectDown(self: *App) void {
        self.cursorDown();
        self.term.clearLines(self.db.entries.len);
        self.writeEntries();
    }
};
