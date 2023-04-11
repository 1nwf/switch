const std = @import("std");
const Terminal = @import("terminal.zig");

pub fn main() !void {
    var term = try Terminal.init();

    var dirs: [10][47]u8 = undefined;
    for (0..10) |idx| {
        _ = try std.fmt.bufPrint(&dirs[idx], "dir{} ", .{idx});
    }

    term.write("\n");
    for (dirs, 0..) |dir, idx| {
        term.writeln(" {}. {s}", .{ idx, &dir });
    }

    term.write("\n --> ");

    term.setCursor();

    while (true) {
        const str = try term.read();
        term.write(str);
    }
}
