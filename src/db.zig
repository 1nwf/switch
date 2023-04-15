const std = @import("std");
path: []const u8,
data: std.fs.File,

const Self = @This();
pub const Entry = struct {
    dir: []const u8,

    fn init(
        dir: []const u8,
    ) Entry {
        return Entry{ .dir = dir };
    }
};

pub fn init(alloc: std.mem.Allocator) !Self {
    var dir = try default_dir(alloc);
    init_dir(dir);

    var filename_buf: [100]u8 = undefined;

    var filename = try std.fmt.bufPrint(&filename_buf, "{s}/{s}", .{ dir, "folders.txt" });

    var file = std.fs.openFileAbsolute(filename, .{ .mode = .read_write }) catch blk: {
        break :blk try std.fs.createFileAbsolute(filename, .{});
    };

    return Self{ .data = file, .path = dir };
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

pub fn addEntry(self: *Self, entry: Entry) void {
    _ = entry;
    _ = self;
}
