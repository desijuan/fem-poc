const std = @import("std");
const builtin = @import("builtin");

pub fn DPRINT(mode: std.builtin.OptimizeMode) fn (comptime fmt: []const u8, args: anytype) callconv(.@"inline") void {
    return struct {
        inline fn DPRINT(comptime fmt: []const u8, args: anytype) void {
            if (comptime mode == .Debug)
                std.debug.print(fmt, args);
        }
    }.DPRINT;
}
