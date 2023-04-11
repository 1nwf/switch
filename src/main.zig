const std = @import("std");

const os = std.os;
const Terminal = @import("terminal.zig");

pub fn main() !void {
    var term = try Terminal.init();

    var dirs: [10][10]u8 = undefined;
    for (0..10) |idx| {
        _ = try std.fmt.bufPrint(&dirs[idx], "| dir{}", .{idx});
    }

    for (dirs) |dir| {
        term.writeln(&dir);
    }

    term.write("> ");

    while (true) {
        const str = try term.read();
        term.write(str);
    }
}
