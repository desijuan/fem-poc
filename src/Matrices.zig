const std = @import("std");
const Matrix = @import("Matrix.zig");

gK: Matrix,
gv: Matrix,
gf: Matrix,
eK: Matrix,

comptime {
    for (fields) |field| if (field.type != Matrix) @compileError(
        "All fields should be of type " ++ @typeName(Matrix) ++ ".",
    );
}

inline fn mats(self: *const Self) *const [fields.len]Matrix {
    return @ptrCast(self);
}

const fields = @typeInfo(Self).@"struct".fields;
const Self = @This();

pub fn init(allocator: std.mem.Allocator, n_nodes: u32) error{OutOfMemory}!Self {
    const n_eqs: u32 = n_nodes * 6;

    return Self{
        .gK = try Matrix.init(allocator, n_eqs, n_eqs),
        .gv = try Matrix.init(allocator, n_eqs, 1),
        .gf = try Matrix.init(allocator, n_eqs, 1),
        .eK = try Matrix.init(allocator, 2 * 6, 2 * 6),
    };
}

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    for (self.mats()) |m| m.deinit(allocator);
}
