const std = @import("std");
path: []const u8,
data: std.fs.File,
alloc: std.mem.Allocator,
entries: [][]const u8,

const Self = @This();

pub fn init(alloc: std.mem.Allocator) !Self {
    var dir = try default_dir(alloc);
    try init_dir(dir);

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
    self.alloc.free(self.path);
    for (self.entries) |dir| {
        self.alloc.free(dir);
    }
    self.alloc.free(self.entries);
    self.data.close();
}

pub fn default_dir(alloc: std.mem.Allocator) ![]const u8 {
    return try std.fs.getAppDataDir(alloc, "dir_cli");
}

fn init_dir(dir: []const u8) !void {
    std.fs.makeDirAbsolute(dir) catch |e| {
        switch (e) {
            error.PathAlreadyExists => {},
            else => {
                std.log.err("unable to create data directory", .{});
                return e;
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

pub fn removeEntry(self: *Self, path: []const u8) ![]u8 {
    var dir = try std.fs.realpathAlloc(self.alloc, path);
    var size: usize = 0;
    for (self.entries) |e| {
        size += e.len + 1;
    }

    var data = try self.alloc.alloc(u8, size - dir.len - 1);
    var index: usize = 0;
    for (self.entries) |entry| {
        if (!std.mem.eql(u8, entry, dir)) {
            std.mem.copy(u8, data[index..], entry);
            std.mem.copy(u8, data[index + entry.len ..], "\n");
            index += entry.len + 1;
        }
    }

    try self.deleteAll();
    try self.data.writeAll(data);

    return dir;
}

pub fn read(self: *Self) ![][]const u8 {
    var reader = self.data.reader();
    var list = std.ArrayList([]const u8).init(self.alloc);
    while (true) {
        var dir = reader.readUntilDelimiterOrEofAlloc(self.alloc, '\n', 300) catch break;
        if (dir) |val| {
            if (val.len == 0) break;
            try list.append(val);
            continue;
        }
        break;
    }

    return try list.toOwnedSlice();
}

pub fn entryExists(self: *Self, entry: []const u8) bool {
    for (self.entries) |e| {
        if (std.mem.eql(u8, e, entry)) {
            return true;
        }
    }

    return false;
}

pub fn removeEntries(self: *Self, entries: [][]const u8) !void {
    if (entries.len == 0) {
        return;
    }
    var data = try std.ArrayList([]const u8).initCapacity(self.alloc, self.entries.len);
    for (self.entries) |d| {
        var valid = true;
        for (entries) |e| {
            if (std.mem.eql(u8, e, d)) {
                valid = false;
                break;
            }
        }

        if (valid) {
            try data.append(d);
            try data.append("\n");
        }
    }

    const dirs = try std.mem.concat(self.alloc, u8, data.items);
    try self.deleteAll();
    try self.data.writeAll(dirs);
}

pub fn deleteAll(self: *Self) !void {
    try self.data.seekTo(0);
    try self.data.setEndPos(0);
}

pub fn exists(self: *Self, path: []const u8) bool {
    for (self.entries) |e| {
        if (std.mem.eql(u8, e, path)) {
            return true;
        }
    }

    return false;
}
pub fn sync(self: *Self) !void {
    var toDelete = std.ArrayList([]const u8).init(self.alloc);
    for (self.entries) |e| {
        if (!dirExists(e)) {
            std.debug.print("removing {s}\n", .{e});
            try toDelete.append(e);
        }
    }
    try self.removeEntries(toDelete.items);

    std.debug.print("database updated\n", .{});
}

pub fn dirExists(dir: []const u8) bool {
    var d = std.fs.openDirAbsolute(dir, .{}) catch {
        return false;
    };
    d.close();
    return true;
}
