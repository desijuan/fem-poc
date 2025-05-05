const std = @import("std");
const utils = @import("../utils.zig");
const DPRINT = @import("../macros.zig").DPRINT;

const Matrix = @import("../Matrix.zig");

const MaterialProperties = @import("MaterialProperties.zig");
const Vec3 = @import("Vec3.zig");
const Beam = @import("Beam.zig");
const BeamBC = @import("BeamBC.zig");

const DEBUG = @import("../config.zig").DEBUG;

pub const DOFS = 12;

pub const desired_element_size = 0.5;
pub const gravity = Vec3{ .x = 0, .y = 0, .z = -9.8 };

mat_props: []MaterialProperties,
nodes: []Vec3,
beams: []Beam,
bcs: []BeamBC,

const Self = @This();

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    allocator.free(self.mat_props);
    allocator.free(self.nodes);
    allocator.free(self.beams);
    allocator.free(self.bcs);
}

pub fn processBeam(self: Self, beam: Beam, eK: Matrix, ef: Matrix, gK: Matrix) void {
    if (comptime DEBUG)
        if (eK.n_rows != DOFS or eK.n_cols != DOFS or ef.n_rows != DOFS or ef.n_cols != 1) std.debug.panic(
            "Wrong size.\nek.n_rows: {}, ek.n_cols: {},\nef.n_rows: {}, ef.n_cols {}",
            .{ eK.n_rows, eK.n_cols, ef.n_rows, ef.n_cols },
        );
    DPRINT("{}", .{beam});

    const mat_props: MaterialProperties = self.mat_props[beam.mat_props_idx];

    const beamData = Beam.BeamData{
        .E = mat_props.elasticity_modulus,
        .G = mat_props.shear_modulus,
        .A = beam.cross_area,
        .Iy = beam.moment_y,
        .Iz = beam.moment_x,
        .J = beam.fIp,
        .L = beam.length,
    };

    Beam.calcLocalK(beamData, eK);
    DPRINT("eK =\n{}", .{eK});
    Beam.accumLocalK(beam.n0_idx, beam.n1_idx, eK, gK);
}
