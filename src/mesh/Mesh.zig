const std = @import("std");
const utils = @import("../utils.zig");
const DPRINT = @import("../macros.zig").DPRINT;

const Matrix = @import("../Matrix.zig");

const MaterialProperties = @import("MaterialProperties.zig");
pub const Node = @import("../mat3d.zig").Vec3;
const Beam = @import("Beam.zig");
const BeamBC = @import("BeamBC.zig");

const DEBUG = @import("../config.zig").DEBUG;

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

pub fn assembleGlobalK(self: Self, gK: Matrix, eK: Matrix) void {
    if (comptime DEBUG)
        if (gK.n_rows != self.nodes.len * 6 or
            gK.n_cols != self.nodes.len * 6 or
            eK.n_rows != 2 * 6 or
            eK.n_cols != 2 * 6) std.debug.panic(
            "Wrong size.\nek.n_rows: {}, ek.n_cols: {},\nef.n_rows: {}, ef.n_cols {}",
            .{ eK.n_rows, eK.n_cols, gK.n_rows, gK.n_cols },
        );

    for (self.beams) |beam| self.processBeam(beam, gK, eK);
}

fn processBeam(self: Self, beam: Beam, gK: Matrix, eK: Matrix) void {
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
    Beam.rotate(eK);
    DPRINT("eK =\n{}", .{eK});
    Beam.accumLocalK(beam.n0_idx, beam.n1_idx, gK, eK);
}
