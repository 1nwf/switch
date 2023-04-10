const std = @import("std");
const system = std.os.system;

const Terminal = @This();
tty: std.fs.File,
writer: std.io.BufferedWriter(4096, std.fs.File.Writer),
termios: std.os.termios,

index: u8 = 0,
input_buffer: [200]u8 = undefined,

pub fn init() !Terminal {
    var tty = try std.fs.openFileAbsolute("/dev/tty", .{ .mode = .read_write });
    var termios = try std.os.tcgetattr(tty.handle);
    var writer = std.io.bufferedWriter(tty.writer());

    return Terminal{ .tty = tty, .writer = writer, .termios = termios };
}

pub fn read(self: *Terminal) ![]u8 {
    var buf: [2]u8 = undefined;
    const n = try self.tty.read(&buf);
    for (0..n) |idx| {
        self.input_buffer[idx + self.index] = buf[idx];
    }
    const idx = self.index;

    if (std.mem.eql(u8, buf[0..n], "\r")) {
        return "";
    }
    self.index += @truncate(u8, n);
    return self.input_buffer[idx..self.index];
}

pub fn write(self: *Terminal, bytes: []const u8) void {
    const writer = self.writer.writer();
    _ = writer.write(bytes) catch 0;
    self.writer.flush() catch {};
}

pub fn disableIcanon(self: *Terminal) void {
    // disable terminal behavior that converts CR char to \n (new line)
    self.termios.iflag &= ~(system.ICRNL);
    // tell the terminal to not buffer input until new line or eof
    // also disbale terminal from echoing the input back to the user
    self.termios.lflag &= ~(system.ICANON | system.ECHO);
    std.os.tcsetattr(self.tty.handle, .NOW, self.termios) catch {};
}
