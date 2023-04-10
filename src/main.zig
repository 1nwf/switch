const std = @import("std");

const os = std.os;
const Terminal = @import("terminal.zig");

pub fn main() !void {
    var term = try Terminal.init();

    term.disableIcanon();

    while (true) {
        const str = try term.read();
        term.write(str);
    }
}
