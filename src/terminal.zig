const std = @import("std");
const system = std.os.system;
const ansi_term = @import("ansi-term");

const Terminal = @This();
tty: std.fs.File,
writer: std.fs.File.Writer,
termios: std.os.termios,

index: u8 = 0,
input_buffer: [200]u8 = undefined,

pub fn init() !Terminal {
    var tty = try std.fs.openFileAbsolute("/dev/tty", .{ .mode = .read_write });
    var termios = try std.os.tcgetattr(tty.handle);
    var writer = tty.writer();

    var term = Terminal{ .tty = tty, .writer = writer, .termios = termios };
    term.setTermAttrs();

    term.setCursor();
    return term;
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

pub fn write(self: *Terminal, comptime bytes: []const u8, args: anytype) void {
    self.writer.print(bytes, args) catch {};
}

pub fn writeln(self: *Terminal, comptime bytes: []const u8, args: anytype) void {
    self.writer.print(bytes, args) catch {};
    _ = self.writer.write("\n") catch {};
}

pub fn setTermAttrs(self: *Terminal) void {
    // disable terminal behavior that converts CR char to \n (new line)
    self.termios.iflag &= ~(system.ICRNL);
    // tell the terminal to not buffer input until new line or eof
    // also disbale terminal from echoing the input back to the user
    self.termios.lflag &= ~(system.ICANON | system.ECHO);

    self.termios.cc[system.V.MIN] = 1;

    std.os.tcsetattr(self.tty.handle, .NOW, self.termios) catch {};
}

pub fn clearLine(self: *Terminal) void {
    ansi_term.clear.clearCurrentLine(self.writer) catch {};
}

pub fn setCursor(self: *Terminal) void {
    ansi_term.cursor.setCursorMode(self.writer, ansi_term.cursor.CursorMode.underscore) catch {};
}

pub fn deinit(self: *Terminal) void {
    self.tty.close();
}

pub fn clearLines(self: *Terminal, lines: usize) void {
    self.clearLine();
    var i: u8 = 0;
    while (i < lines) : (i += 1) {
        ansi_term.cursor.cursorUp(self.writer, 1) catch {};
        self.clearLine();
    }
    ansi_term.cursor.setCursorColumn(self.writer, 0) catch {};
}

pub fn setLineStyle(self: *Terminal, total_lines: usize, line: usize, fg: ansi_term.style.Color, bg: ansi_term.style.Color, entry: []const u8) void {
    ansi_term.cursor.saveCursor(self.writer) catch {};
    ansi_term.cursor.cursorUp(self.writer, total_lines - line) catch {};
    ansi_term.format.updateStyle(self.writer, .{ .foreground = fg, .background = bg }, null) catch {};
    ansi_term.cursor.setCursorColumn(self.writer, 0) catch {};
    self.writeln("{}. {s}", .{ line + 1, entry });
    ansi_term.cursor.restoreCursor(self.writer) catch {};
}
