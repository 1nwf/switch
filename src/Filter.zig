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

pub fn next(self: *Self) ?Word {
    if (self.idx >= self.items.len) return null;
    const filter_word = self.value orelse return null;
    for (self.items[self.idx..], self.idx..) |dir, idx| {
        const match = util.contains(dir, filter_word) orelse continue;
        self.idx = idx + 1;
        return Word.init(dir, match);
    }
    return null;
}

pub fn filter(self: *Self, value: []const u8) void {
    self.value = value;
    self.idx = 0;
}

pub const Word = struct {
    match: util.Match,
    value: []const u8,
    fn init(value: []const u8, match: util.Match) Word {
        return .{
            .value = value,
            .match = match,
        };
    }
};
