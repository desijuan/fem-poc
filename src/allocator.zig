const std = @import("std");

pub const Gpa = switch (@import("builtin").mode) {
    .ReleaseSmall, .ReleaseFast => c_allocator,
    .Debug, .ReleaseSafe => DebugAllocator,
};

const c_allocator = struct {
    pub inline fn allocator() std.mem.Allocator {
        return std.heap.c_allocator;
    }
};

const DebugAllocator = struct {
    var da_inst = std.heap.DebugAllocator(.{ .safety = true }){};

    pub fn allocator() std.mem.Allocator {
        return da_inst.allocator();
    }

    pub fn deinit() void {
        _ = da_inst.deinit();
    }
};
