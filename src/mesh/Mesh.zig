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

pub fn calcLocalKforBeam(self: Self, idx: u32, ek: Matrix, ef: Matrix) error{WrongSize}!void {
    if (ek.n_rows != NEQ or ek.n_cols != NEQ or ef.n_rows != NEQ) return error.WrongSize;

    const beam: Beam = self.beams[idx];

    std.debug.print("{}", .{beam});

    const mat_props: MaterialProperties = self.mat_props[beam.mat_props_idx];

    std.debug.print("{}", .{mat_props});

    const beamData = Beam.BeamData{
        .L = beam.length,
        .E = mat_props.elasticity_modulus,
        .G = mat_props.shear_modulus,
        .A = beam.cross_area,
        .Iy = beam.moment_y,
        .Iz = beam.moment_x,
        .J = beam.fIp,
    };

    std.debug.print("{}\n", .{beamData});

    Beam.calcLocalK(beamData, ek) catch |err| switch (err) {
        error.WrongSize => unreachable,
    };
}

pub fn getEquationIndicesForBeam(self: Self, idx: u32, eq_idxs: *[12]u32) void {
    self.beams[idx].getEquationIndices(eq_idxs);
}
