const std = @import("std");
const utils = @import("../utils.zig");

const Matrix = @import("../Matrix.zig");

const MaterialProperties = @import("MaterialProperties.zig");
const Vec3 = @import("Vec3.zig");
const Beam = @import("Beam.zig");
const BeamBC = @import("BeamBC.zig");

pub const desired_element_size = 0.5;
pub const gravity = Vec3{ .x = 0, .y = 0, .z = -9.8 };

mat_props: []MaterialProperties,
nodes: []Vec3,
beams: []Beam,
bcs: []BeamBC,

pub const NEQ = 12;

const Self = @This();

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    allocator.free(self.mat_props);
    allocator.free(self.nodes);
    allocator.free(self.beams);
    allocator.free(self.bcs);
}

pub fn calcLocalKforBeam(self: Self, idx: u32, ek: Matrix, ef: Matrix) (error{WrongNEQ} || Matrix.Error)!void {
    if (ek.n_rows != NEQ or ek.n_cols != NEQ or ef.n_rows != NEQ) return error.WrongNEQ;

    const beam: Beam = self.beams[idx];

    std.debug.print("{}", .{beam});

    const mat_props: MaterialProperties = self.mat_props[beam.mat_props_idx];

    std.debug.print("{}", .{mat_props});

    const l: f64 = beam.length;

    const E: f64 = mat_props.elasticity_modulus;
    const G: f64 = mat_props.shear_modulus;
    const A: f64 = beam.cross_area;
    // const Ix = beam.moment_x;
    const Iy = beam.moment_y;
    const J = beam.fIp;

    var value: f64 = 0;

    value = E * A / l;
    try ek.set(1, 1, value);
    try ek.set(1, 7, -1.0 * value);
    try ek.set(7, 1, -1.0 * value);
    try ek.set(7, 7, value);

    value = 12.0 * E * Iy / (l * l * l);
    try ek.set(2, 2, value);
    try ek.set(2, 8, -1.0 * value);
    try ek.set(8, 2, -1.0 * value);
    try ek.set(8, 8, value);

    value = 6.0 * E * Iy / (l * l);
    try ek.set(2, 6, value);
    try ek.set(2, 12, value);
    try ek.set(8, 6, -1.0 * value);
    try ek.set(8, 12, -1.0 * value);

    try ek.set(6, 2, value);
    try ek.set(12, 2, value);
    try ek.set(6, 8, -1.0 * value);
    try ek.set(12, 8, -1.0 * value);

    value = 12.0 * E * Iy / (l * l * l);
    try ek.set(3, 3, value);
    try ek.set(3, 9, -1.0 * value);
    try ek.set(9, 3, -1.0 * value);
    try ek.set(9, 9, value);

    value = -6.0 * E * Iy / (l * l);
    try ek.set(3, 5, value);
    try ek.set(3, 11, value);
    try ek.set(9, 5, -1.0 * value);
    try ek.set(9, 11, -1.0 * value);

    try ek.set(5, 3, value);
    try ek.set(11, 3, value);
    try ek.set(5, 9, -1.0 * value);
    try ek.set(11, 9, -1.0 * value);

    value = G * J / l;
    try ek.set(4, 4, value);
    try ek.set(4, 10, -1.0 * value);
    try ek.set(10, 4, -1.0 * value);
    try ek.set(10, 10, value);

    value = 4.0 * E * Iy / l;
    try ek.set(5, 5, value);
    try ek.set(5, 11, value / 2.0);
    try ek.set(11, 5, value / 2.0);
    try ek.set(11, 11, value);

    value = 4.0 * E * Iy / l;
    try ek.set(6, 6, value);
    try ek.set(6, 12, value / 2.0);
    try ek.set(12, 6, value / 2.0);
    try ek.set(12, 12, value);
}

pub fn getEquationIndicesForBeam(self: Self, idx: u32, eq_idxs: *[12]u32) void {
    self.beams[idx].getEquationIndices(eq_idxs);
}
