const std = @import("std");
const utils = @import("../utils.zig");
const DPRINT = @import("../macros.zig").DPRINT;

const Matrix = @import("../Matrix.zig");

const MaterialProperties = @import("MaterialProperties.zig");
pub const Node = @import("../mat3d.zig").Vec3;
const Beam = @import("Beam.zig");
const BeamBC = @import("BeamBC.zig");

const DEBUG = @import("../config.zig").DEBUG;

pub const DOFS = 12;

pub const desired_element_size = 6; // 0.5
pub const gravity = Node{ 0, 0, -9.8 };

mat_props: []MaterialProperties,
nodes: []Node,
beams: []Beam,
bcs: []BeamBC,

const Self = @This();

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    allocator.free(self.mat_props);
    allocator.free(self.nodes);
    allocator.free(self.beams);
    allocator.free(self.bcs);
}

pub fn assembleGlobalK(self: Self, eK: Matrix, ef: Matrix, gK: Matrix) void {
    if (comptime DEBUG)
        if (eK.n_rows != DOFS or eK.n_cols != DOFS or ef.n_rows != DOFS or ef.n_cols != 1) std.debug.panic(
            "Wrong size.\nek.n_rows: {}, ek.n_cols: {},\nef.n_rows: {}, ef.n_cols {}",
            .{ eK.n_rows, eK.n_cols, ef.n_rows, ef.n_cols },
        );

    for (self.beams) |beam| self.processBeam(beam, eK, ef, gK);
}

fn processBeam(self: Self, beam: Beam, eK: Matrix, ef: Matrix, gK: Matrix) void {
    DPRINT("{}", .{beam});
    _ = ef;

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
    // ROTATE
    // Beam.rotate(eK);
    Beam.accumLocalK(beam.n0_idx, beam.n1_idx, eK, gK);
}
