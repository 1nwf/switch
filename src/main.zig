const std = @import("std");

const os = std.os;

pub fn main() !void {
    var tty = try std.fs.openFileAbsolute("/dev/tty", .{ .mode = .read_write });
    var termios = try std.os.tcgetattr(tty.handle);
    _ = termios;

    var writer = std.io.bufferedWriter(tty.writer());
    _ = try writer.write("?\n");

    try writer.flush();
}
