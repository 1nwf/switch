const util = @import("util.zig");
const std = @import("std");
items: [][]const u8,
value: ?[]const u8 = null,
idx: usize = 0,

const Self = @This();

pub fn init(items: [][]const u8) !Self {
    return .{
        .items = items,
    };
}

pub fn next(self: *Self) ?[]const u8 {
    if (self.idx >= self.items.len) return null;
    var next_val: ?[]const u8 = null;
    if (self.value) |val| {
        for (self.items[self.idx..], self.idx..) |dir, idx| {
            if (!util.contains(dir, val)) continue;
            next_val = dir;
            self.idx = idx + 1;
            break;
        }
    } else {
        next_val = self.items[self.idx];
        self.idx += 1;
    }

    return next_val;
}

pub fn filter(self: *Self, value: []const u8) void {
    self.value = value;
    self.idx = 0;
}
