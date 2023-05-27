const std = @import("std");
pub fn contains(s1: []const u8, s2: []const u8) bool {
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

    for (max, 0..) |_, idx| {
        if (idx + min.len > max.len) {
            break;
        }
        var first = max[idx .. idx + min.len];
        if (std.mem.eql(u8, first, min)) {
            return true;
        }
    }

    return false;
}
