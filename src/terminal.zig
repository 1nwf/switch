const std = @import("std");
const system = std.os.system;
const ansi_term = @import("ansi-term");
const ziglyph = @import("ziglyph");

const Terminal = @This();
tty: std.fs.File,
writer: std.fs.File.Writer,
termios: std.os.termios,
old_termios: std.os.termios,
index: u8 = 0,
input_buffer: [200]u8 = undefined,

pub const Input = union(enum) {
    up,
    down,
    delete,
    select,
    quit,
    str: []const u8,
};

pub fn init() !Terminal {
    var tty = try std.fs.openFileAbsolute("/dev/tty", .{ .mode = .read_write });
    var termios = try std.os.tcgetattr(tty.handle);

    const old_termios = termios;
    var writer = tty.writer();

    var term = Terminal{ .tty = tty, .writer = writer, .termios = termios, .old_termios = old_termios };
    term.setTermAttrs();

    term.setCursor();
    return term;
}

pub fn read(self: *Terminal) !?Input {
    const cp = try ziglyph.readCodePoint(self.tty.reader());
    const char = cp.?;
    var idx = self.index;
    _ = idx;
    if (ziglyph.isControl(char)) {
        // TODO: handle j/k up/down commands
        switch (char) {
            127 => {
                return .delete;
            },
            27 => {
                return .quit;
            },
            '\r' => return .select,
            10 => return .down,
            11 => return .up,
            else => return null,
        }
    }

    self.index += try std.unicode.utf8Encode(char, self.input_buffer[self.index..]);
    return .{ .str = self.input_buffer[0..self.index] };
}

pub fn empty(self: *Terminal) bool {
    return self.index == 0;
}

pub fn getInput(self: *Terminal) []const u8 {
    return self.input_buffer[0..self.index];
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
    ansi_term.cursor.setCursorMode(self.writer, ansi_term.cursor.CursorMode.I_beam) catch {};
}

pub fn deinit(self: *Terminal) !void {
    try std.os.tcsetattr(self.tty.handle, .NOW, self.old_termios);
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

pub fn setLineStyle(self: *Terminal, total_lines: usize, line: usize, style: ?ansi_term.style.Style, entry: []const u8) void {
    ansi_term.cursor.saveCursor(self.writer) catch {};
    ansi_term.cursor.cursorUp(self.writer, total_lines - line) catch {};
    if (style) |s| {
        ansi_term.format.updateStyle(self.writer, s, null) catch {};
    }
    ansi_term.cursor.setCursorColumn(self.writer, 0) catch {};
    self.writeln("{}. {s}", .{ line + 1, entry });
    ansi_term.cursor.restoreCursor(self.writer) catch {};
}

pub fn cursorUp(self: *Terminal, lines: usize) !void {
    try ansi_term.cursor.cursorUp(self.writer, lines);
}

pub fn cursorDown(self: *Terminal, lines: usize) !void {
    try ansi_term.cursor.cursorDown(self.writer, lines);
}

pub fn delete(self: *Terminal) void {
    if (self.index == 0) {
        return;
    }
    self.index -= 1;
}
