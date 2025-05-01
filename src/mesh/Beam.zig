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
