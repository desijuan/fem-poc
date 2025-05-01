const std = @import("std");
const utils = @import("utils.zig");
const mesh = @import("mesh/mesh.zig");

const Mesh = mesh.Mesh;

const PI = std.math.pi;

height: f64,
bottom_diameter: f64,
top_diameter: f64,
fiber_strength: f64,
modulus_of_elasticity: f64,
shear_modulus: f64,
density: f64,

const Self = @This();

pub const format = utils.structFormatFn(Self);

pub fn buildMesh(self: Self, allocator: std.mem.Allocator) !Mesh {
    const mat_props: []mesh.MaterialProperties = try allocator.alloc(mesh.MaterialProperties, 1);
    errdefer allocator.free(mat_props);

    mat_props[0] = mesh.MaterialProperties{
        .elasticity_modulus = self.modulus_of_elasticity,
        .shear_modulus = self.shear_modulus,
        .density = self.density,
    };

    const n_beams: usize = @as(usize, @intFromFloat(@ceil(self.height / Mesh.desired_element_size)));
    const beam_size: f64 = self.height / @as(f64, @floatFromInt(n_beams));

    const nodes: []mesh.Vec3 = try allocator.alloc(mesh.Vec3, n_beams + 1);
    errdefer allocator.free(nodes);

    for (0..n_beams) |i| {
        nodes[i] = mesh.Vec3{
            .x = 0.0,
            .y = 0.0,
            .z = @as(f64, @floatFromInt(i)) * beam_size,
        };
        // TODO: TCXWoodPoleFem.fPoleNodesList[i] = i

    } else { // Last Node
        nodes[n_beams] = mesh.Vec3{
            .x = 0.0,
            .y = 0.0,
            .z = self.height,
        };
    }

    const beams: []mesh.Beam = try allocator.alloc(mesh.Beam, n_beams);
    errdefer allocator.free(beams);

    for (0..n_beams) |i| {
        const diameter: f64 = utils.evalLine(
            (nodes[i].z + nodes[i + 1].z) / 2.0,
            .{ .x0 = 0.0, .y0 = self.bottom_diameter, .x1 = self.height, .y1 = self.top_diameter },
        );

        const moment: f64 = PI * (diameter * diameter * diameter * diameter) / 64.0;

        beams[i] = mesh.Beam{
            .mat_props_idx = 0,
            .n0_idx = @intCast(i),
            .n1_idx = @intCast(i + 1),
            .length = beam_size,
            .cross_area = PI * diameter * diameter / 4.0,
            .moment_x = moment,
            .moment_y = moment,
            .fJp = 2.0 * moment,
            .fIp = 2.0 * moment,
        };
    }

    const bcs: []mesh.BeamBC = try allocator.alloc(mesh.BeamBC, 1);
    errdefer allocator.free(bcs);

    bcs[0] = mesh.BeamBC{
        .node_idx = 0,
        .beam_idx = 0,
        .type0 = .Support,
        .type1 = .Support,
        .type2 = .Support,
        .type3 = .Support,
        .type4 = .Support,
        .type5 = .Support,
        .value0 = 0.0,
        .value1 = 0.0,
        .value2 = 0.0,
        .value3 = 0.0,
        .value4 = 0.0,
        .value5 = 0.0,
    };

    return Mesh{
        .mat_props = mat_props,
        .nodes = nodes,
        .beams = beams,
        .bcs = bcs,
    };
}
