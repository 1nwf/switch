const std = @import("std");
const Terminal = @import("terminal.zig");
const DB = @import("db.zig");
const util = @import("util.zig");

pub const App = struct {
    term: Terminal,
    db: DB,
    selection: usize = 0,
    filters: std.ArrayList([]const u8),
    active: [][]const u8,

    const HighlightStyle = .{ .foreground = .Red, .background = .Default };
    const SelectionStyle = .{ .foreground = .{ .RGB = .{ .r = 0xff, .g = 0xff, .b = 0xff } }, .background = .Red };

    pub fn init(term: Terminal, db: DB) !App {
        return App{ .term = term, .db = db, .filters = try std.ArrayList([]const u8).initCapacity(db.alloc, db.entries.len), .active = db.entries };
    }

    fn writeEntries(self: *App) void {
        for (self.active, 0..) |dir, idx| {
            _ = self.term.writer.print("{}. {s}\n", .{ idx + 1, dir }) catch {};
        }
        self.term.write("=> ", .{});
    }

    pub fn run(
        self: *App,
    ) !?[]const u8 {
        defer self.deinit() catch {};
        self.writeEntries();

        var redraw = true;

        while (true) {
            const input = try self.term.read();

            if (self.term.index > 0) {
                redraw = true;
            }
            switch (input) {
                .str => |s| {
                    if (!redraw) {
                        continue;
                    }

                    try self.draw(s);
                    if (self.term.empty()) {
                        redraw = false;
                    }

                    continue;
                },

                .quit => {
                    return null;
                },
                .select => {
                    if (self.selection == 0) {
                        self.selection += 1;
                    }
                },
                .delete => {
                    self.term.delete();
                    try self.draw(self.term.getInput());
                    if (self.term.empty()) {
                        redraw = false;
                    }

                    continue;
                },
                else => unreachable,
            }

            if (self.active.len == 0) {
                return null;
            }

            self.term.setLineStyle(self.active.len, self.getSelectionLine(), App.SelectionStyle, self.active[self.selection - 1]);
            std.time.sleep(50_000_000);
            return self.active[self.selection - 1];
        }
    }

    pub fn draw(self: *App, input: []const u8) !void {
        var entries = try self.filterEntries(input);
        self.term.clearLines(self.active.len);
        self.active = entries;
        self.writeEntries();
        self.term.write("{s}", .{input});
    }

    pub fn deinit(self: *App) !void {
        self.term.clearLines(self.active.len);
        try self.term.deinit();
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
        self.term.setLineStyle(self.db.entries.len, self.getSelectionLine(), null, self.db.entries[self.selection - 1]);
    }

    fn updateHighlight(self: *App) void {
        self.term.setLineStyle(self.db.entries.len, self.getSelectionLine(), App.HighlightStyle, self.db.entries[self.selection - 1]);
    }

    fn getSelectionLine(self: *App) usize {
        return self.selection - 1;
    }

    fn filterEntries(self: *App, text: []const u8) ![][]const u8 {
        self.filters.clearRetainingCapacity();
        for (self.db.entries) |e| {
            const contains = util.contains(e, text);
            if (contains) {
                try self.filters.append(e);
            }
        }

        return self.filters.items;
    }
};
