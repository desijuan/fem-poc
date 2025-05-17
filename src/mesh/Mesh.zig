const std = @import("std");
const utils = @import("../utils.zig");
const DPRINT = @import("../macros.zig").DPRINT;

const Matrix = @import("../Matrix.zig");

const MaterialProperties = @import("MaterialProperties.zig");
pub const Node = @import("../mat3d.zig").Vec3;
const Beam = @import("Beam.zig");
const BoundaryCondition = @import("BoundaryCondition.zig");

const DEBUG = @import("../config.zig").DEBUG;

mat_props: []MaterialProperties,
nodes: []Node,
beams: []Beam,
bcs: []BoundaryCondition,

const Self = @This();

const BIG_NUMBER = 1e12;

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

pub fn applyBoundaryConditions(self: Self, gK: Matrix, gf: Matrix) void {
    for (self.bcs) |bc| {
        const d0 = 6 * bc.node_idx;

        switch (bc.type) {
            .Support => {
                // L
                for (0..d0) |j| @memset(gK.entries[j * gK.n_rows + d0 ..][0..6], 0);
                // I
                @memset(gK.entries[d0 .. d0 + 6 * gK.n_rows], 0);
                // R
                for (d0 + 6..gK.n_cols) |j| @memset(gK.entries[j * gK.n_rows + d0 ..][0..6], 0);
                // D
                for (utils.range(u32, 1, 7)) |s| gK.set(d0 + s, d0 + s, BIG_NUMBER);
            },

            .Force => |force| {
                gf.addTo(d0 + 1, 1, force[0]);
                gf.addTo(d0 + 2, 1, force[1]);
                gf.addTo(d0 + 3, 1, force[2]);
            },
        }
    }
}

const WIDTH = "6";

pub fn printSolution(self: Self, f: Matrix) void {
    std.debug.print("Height (m), Displacement (m)\n", .{});
    for (self.nodes, 0..self.nodes.len) |n, i| {
        const anchor: u32 = @intCast(i * 6);
        std.debug.print("{}, {}\n", .{ n[2], f.get(anchor + 2, 1) });
    }
}

fn processBeam(self: Self, beam: Beam, gK: Matrix, eK: Matrix) void {
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
    Beam.accumLocalK(beam.n0_idx, beam.n1_idx, gK, eK);
}
