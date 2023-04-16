const std = @import("std");
const App = @import("app.zig").App;
const Terminal = @import("terminal.zig");
const DB = @import("db.zig");
const ansi_term = @import("ansi-term");

pub fn main() !void {
    var term = try Terminal.init();
    var arena_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var alloc = arena_alloc.allocator();
    defer arena_alloc.deinit();
    var db = try DB.init(alloc);
    var app = App.init(.num, term, db);
    try app.run(alloc);
}
