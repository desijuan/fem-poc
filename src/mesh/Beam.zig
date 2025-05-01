const std = @import("std");
const Matrix = @import("../Matrix.zig");
const Mesh = @import("Mesh.zig");
const MaterialProperties = @import("MaterialProperties.zig");

mat_props_idx: u32,
n0_idx: u32,
n1_idx: u32,
length: f64,
cross_area: f64, // fA
moment_x: f64, // fIy
moment_y: f64, // fIy
fJp: f64, // ?
fIp: f64, // ?

const Self = @This();

pub const format = @import("../utils.zig").structFormatFn(Self);

pub fn getEquationIndices(self: Self, eq_idxs: *[12]u32) void {
    for (1..7) |k| {
        eq_idxs[k - 1] = 6 * self.n0_idx + @as(u32, @intCast(k));
        eq_idxs[k - 1 + 6] = 6 * self.n1_idx + @as(u32, @intCast(k));
    }
}
