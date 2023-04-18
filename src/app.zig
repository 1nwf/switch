const std = @import("std");
const Terminal = @import("terminal.zig");
const Mode = enum { num, search };
const DB = @import("db.zig");
pub const App = struct {
    mode: Mode,
    term: Terminal,
    db: DB,
    selection: usize = 0,

    const HighlightStyle = .{ .foreground = .Red, .background = .Default };
    const SelectionStyle = .{ .foreground = .{ .RGB = .{ .r = 0xff, .g = 0xff, .b = 0xff } }, .background = .Red };
    pub fn init(mode: Mode, term: Terminal, db: DB) App {
        return App{ .mode = mode, .term = term, .db = db };
    }

    fn writeEntries(self: *App) void {
        const entries = self.db.entries;
        for (entries, 0..) |dir, idx| {
            _ = self.term.writer.print("{}. {s}", .{ idx + 1, dir }) catch {};
            self.term.writeln("\n-------------------------------------------", .{});
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
            if (std.mem.eql(u8, str, "j")) {
                self.selectDown();
                continue;
            } else if (std.mem.eql(u8, str, "k")) {
                self.selectUp();
                continue;
            } else if (std.mem.eql(u8, str, "\r")) {
                if (self.selection == 0) {
                    self.selection += 1;
                }
            } else {
                var val = std.fmt.parseInt(usize, str, 0) catch 0;
                if (val > self.db.entries.len or val <= 0) {
                    continue;
                }
                self.selection = val;
            }

            self.term.setLineStyle(self.db.entries.len * 2 + 1, self.getSelectionLine(), App.SelectionStyle, self.db.entries[self.selection - 1]);

            self.term.write("{}", .{self.selection});
            std.time.sleep(50_000_000);

            self.term.clearLines(entries.len * 2);
            return entries[self.selection - 1];
        }
    }

    pub fn deinit(self: *App) void {
        self.term.deinit();
        self.db.deinit();
    }

    fn selectUp(self: *App) void {
        self.restoreSelectionStyle();
        if (self.selection <= 1) {
            self.selection = self.db.entries.len;
        } else {
            self.selection -= 1;
        }

        self.updateHighlight();
    }

    fn selectDown(self: *App) void {
        self.restoreSelectionStyle();
        if (self.selection + 1 > self.db.entries.len) {
            self.selection = 1;
        } else {
            self.selection += 1;
        }

        self.updateHighlight();
    }

    fn restoreSelectionStyle(self: *App) void {
        if (self.selection == 0) {
            return;
        }
        self.term.setLineStyle(self.db.entries.len * 2 + 1, self.getSelectionLine(), null, self.db.entries[self.selection - 1]);
    }

    fn updateHighlight(self: *App) void {
        self.term.setLineStyle(self.db.entries.len * 2 + 1, self.getSelectionLine(), App.HighlightStyle, self.db.entries[self.selection - 1]);
    }

    fn getSelectionLine(self: *App) usize {
        return self.selection * 2 - 1;
    }
};
