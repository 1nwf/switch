const std = @import("std");
const toLower = std.ascii.toLower;

pub fn contains(s1: []const u8, s2: []const u8) bool {
    if (s1.len == 0 or s2.len == 0) return true;
    const min = blk: {
        if (s1.len > s2.len) {
            break :blk s2;
        }
        break :blk s1;
    };

    var max = blk: {
        if (min.len != s1.len) {
            break :blk s1;
        }
        break :blk s2;
    };

    var window = std.mem.window(u8, max, min.len, 1);
    while (window.next()) |val| {
        if (eql(val, min)) {
            return true;
        }
    }

    return false;
}

fn eql(first: []const u8, second: []const u8) bool {
    if (first.len != second.len) return false;
    for (first, second) |a, b| {
        if (a != b and toLower(a) != toLower(b)) return false;
    }
    return true;
}
