const std = @import("std");
const builtin = @import("builtin");

pub inline fn DPRINT(comptime fmt: []const u8, args: anytype) void {
    if (comptime builtin.mode == .Debug)
        std.debug.print(fmt, args);
}
