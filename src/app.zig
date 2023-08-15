const std = @import("std");
const Style = @import("ansi-term").style.Style;
const Terminal = @import("terminal.zig");
const DB = @import("db.zig");
const util = @import("util.zig");
const Filter = @import("Filter.zig");

pub const App = struct {
    term: Terminal,
    db: DB,
    selection: usize = 0,
    filtered_items: std.ArrayList([]const u8),
    filter: Filter,
    height: usize = 0,

    const HighlightStyle = .{ .foreground = .Red, .background = .Default };
    const SelectionStyle = .{ .foreground = .{ .RGB = .{ .r = 0xff, .g = 0xff, .b = 0xff } }, .background = .Red };

    pub fn init(term: Terminal, db: DB) !App {
        return App{
            .term = term,
            .db = db,
            .filtered_items = try std.ArrayList([]const u8).initCapacity(db.alloc, db.entries.len),
            .filter = try Filter.init(db.entries),
        };
    }

    pub fn writeAllEntries(self: *App) void {
        for (self.db.entries) |val| {
            self.height += 1;
            self.term.clearLine();
            self.term.write("{}. {s}\n", .{ self.height, val });
            self.filtered_items.append(val) catch {};
        }
        self.term.write("=> ", .{});
    }

    pub fn run(self: *App) !?[]const u8 {
        var redraw = true;
        self.writeAllEntries();

        while (true) {
            const input = try self.term.read() orelse continue;

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
                    self.selection = 0;
                },
                .select => {
                    if (self.height == 0) {
                        return null;
                    }
                    if (self.selection == 0) {
                        self.selection += 1;
                    }
                    self.term.setLineStyle(self.filtered_items.items.len, self.getSelectionLine(), App.SelectionStyle, self.filtered_items.items[self.selection - 1]);
                    std.time.sleep(40_000_000);
                    return self.filtered_items.items[self.selection - 1];
                },
                .delete => {
                    if (self.term.index == 0) continue;
                    self.term.delete();
                    try self.draw(self.term.getInput());
                    if (self.term.empty()) {
                        redraw = false;
                    }
                },
                .down => self.selectDown(),
                .up => self.selectUp(),
                .quit => return null,
            }
        }
    }

    fn writeEntries(self: *App) void {
        var len: usize = 0;
        while (self.filter.next()) |val| {
            if (self.filtered_items.items.len > len) {
                const curr_value = self.filtered_items.items[len];
                if (curr_value.len > val.value.len) self.term.clearLine();
                self.filtered_items.items[len] = val.value;
            } else {
                self.filtered_items.append(val.value) catch {};
            }
            self.term.write("{}. ", .{len + 1});
            self.term.writeHighlight(App.HighlightStyle, val.value, val.match.start, val.match.end);
            len += 1;
        }

        self.filtered_items.shrinkRetainingCapacity(len);

        if (self.height > len) {
            self.term.clearDown(self.height - len);
        }

        self.height = len;
        self.term.clearLine();
        self.term.write("=> ", .{});
    }

    pub fn draw(self: *App, input: []const u8) !void {
        const trimmed_input = std.mem.trim(u8, input, " ");
        if (self.filter.value != null and std.mem.eql(u8, self.filter.value.?, trimmed_input)) {
            self.term.clearLine();
            self.term.setCursorColumn(0);
            if (input.len != 0) {
                self.term.write("=> {s}", .{input});
            } else {
                self.term.write("=> ", .{});
            }
            return;
        }

        self.term.hideCursor();
        defer self.term.showCursor();
        if (self.height > 0) {
            self.term.cursorUp(self.height) catch {};
        }
        self.term.setCursorColumn(0);

        if (trimmed_input.len == 0) {
            self.filter.value = trimmed_input;
            self.height = 0;
            self.filtered_items.clearRetainingCapacity();
            self.writeAllEntries();
        } else {
            self.filter.filter(trimmed_input);
            self.writeEntries();
        }

        if (input.len != 0) {
            self.term.write("{s}", .{input});
        }
    }

    pub fn deinit(self: *App) !void {
        self.filtered_items.deinit();
        self.term.clearLines(self.height);
        try self.term.deinit();
        self.db.deinit();
    }

    fn selectUp(self: *App) void {
        self.updateHighlight(null);
        if (self.selection <= 1) {
            self.selection = self.filtered_items.items.len;
        } else {
            self.selection -= 1;
        }

        self.updateHighlight(HighlightStyle);
    }

    fn selectDown(self: *App) void {
        self.updateHighlight(null);
        if (self.selection + 1 > self.filtered_items.items.len) {
            self.selection = 1;
        } else {
            self.selection += 1;
        }

        self.updateHighlight(HighlightStyle);
    }

    fn updateHighlight(self: *App, style: ?Style) void {
        if (self.selection == 0 or self.filtered_items.items.len == 0) return;
        self.term.setLineStyle(self.filtered_items.items.len, self.getSelectionLine(), style, self.filtered_items.items[self.selection - 1]);
    }

    fn getSelectionLine(self: *App) usize {
        return self.selection - 1;
    }
};

test "no memory leaks" {
    var allocator = std.testing.allocator;
    var db = try DB.init(allocator);
    var term = try Terminal.init();
    var app = try App.init(term, db);
    defer app.deinit() catch @panic("deint error");
    try app.draw("t");
}
