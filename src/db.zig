const std = @import("std");
path: []const u8,
data: std.fs.File,
alloc: std.mem.Allocator,
entries: [][]const u8,

const Self = @This();

pub fn init(alloc: std.mem.Allocator) !Self {
    var dir = try default_dir(alloc);
    init_dir(dir);

    var filename_buf: [100]u8 = undefined;

    var filename = try std.fmt.bufPrint(&filename_buf, "{s}/{s}", .{ dir, "folders.txt" });

    var file = std.fs.openFileAbsolute(filename, .{ .mode = .read_write }) catch blk: {
        break :blk try std.fs.createFileAbsolute(filename, .{});
    };

    var db = Self{ .data = file, .path = dir, .alloc = alloc, .entries = undefined };
    db.entries = try db.read();

    return db;
}

pub fn deinit(self: *Self) void {
    self.data.close();
}

pub fn default_dir(alloc: std.mem.Allocator) ![]const u8 {
    return try std.fs.getAppDataDir(alloc, "dir_cli");
}

fn init_dir(dir: []const u8) void {
    std.fs.makeDirAbsolute(dir) catch |e| {
        switch (e) {
            error.PathAlreadyExists => {},
            else => {
                std.log.err("unable to create data directory", .{});
                std.process.exit(1);
            },
        }
    };
}
pub fn write(self: Self, value: []const u8) !void {
    try self.data.writeAll(value);
}

pub fn addEntry(self: *Self, path: []const u8) ![]const u8 {
    var dir = try std.fs.realpathAlloc(self.alloc, path);
    if (self.entryExists(dir)) {
        return dir;
    }
    try self.data.seekFromEnd(0);
    try self.data.writeAll(dir);
    try self.data.writeAll("\n");
    return dir;
}

pub fn read(
    self: *Self,
) ![][]const u8 {
    var reader = self.data.reader();
    var list = std.ArrayList([]const u8).init(self.alloc);
    while (true) {
        var dir = reader.readUntilDelimiterAlloc(self.alloc, '\n', 200) catch break;
        if (dir.len == 0) {
            break;
        }
        try list.append(dir);
    }

    return list.items;
}

pub fn entryExists(self: *Self, entry: []const u8) bool {
    const entries = self.read() catch unreachable;
    for (entries) |e| {
        if (std.mem.eql(u8, e, entry)) {
            return true;
        }
    }

    return false;
}
