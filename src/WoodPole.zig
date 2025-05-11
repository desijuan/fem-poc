const std = @import("std");
const utils = @import("utils.zig");

const Vec3 = @import("mat3d.zig").Vec3;
const Mesh = @import("mesh/Mesh.zig");
const MaterialProperties = @import("mesh/MaterialProperties.zig");
const Node = Mesh.Node;
const Beam = @import("mesh/Beam.zig");
const BoundaryCondition = @import("mesh/BoundaryCondition.zig");

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

pub fn buildMesh(self: Self, allocator: std.mem.Allocator, max_elem_size: f64, force_top: Vec3) error{OutOfMemory}!Mesh {
    const mat_props: []MaterialProperties = try allocator.alloc(MaterialProperties, 1);
    errdefer allocator.free(mat_props);

    mat_props[0] = MaterialProperties{
        .elasticity_modulus = self.modulus_of_elasticity,
        .shear_modulus = self.shear_modulus,
        .density = self.density,
    };

    const n_beams: usize = @as(usize, @intFromFloat(@ceil(self.height / max_elem_size)));
    const beam_size: f64 = self.height / @as(f64, @floatFromInt(n_beams));

    const nodes: []Node = try allocator.alloc(Node, n_beams + 1);
    errdefer allocator.free(nodes);

    for (0..n_beams) |i| {
        nodes[i] = Node{ 0.0, 0.0, @as(f64, @floatFromInt(i)) * beam_size };
        // TODO: TCXWoodPoleFem.fPoleNodesList[i] = i

    } else // Last Node
    nodes[n_beams] = Node{ 0.0, 0.0, self.height };

    const beams: []Beam = try allocator.alloc(Beam, n_beams);
    errdefer allocator.free(beams);

    for (0..n_beams) |i| {
        const diameter: f64 = utils.evalLine(
            (nodes[i][2] + nodes[i + 1][2]) / 2.0,
            .{ .x0 = 0.0, .y0 = self.bottom_diameter, .x1 = self.height, .y1 = self.top_diameter },
        );

        const moment: f64 = PI * (diameter * diameter * diameter * diameter) / 64.0;

        beams[i] = Beam{
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

    const bcs: []BoundaryCondition = try allocator.alloc(BoundaryCondition, 2);
    errdefer allocator.free(bcs);

    // Support
    // at ground level
    bcs[0] = BoundaryCondition{
        .node_idx = 0,
        .type = .Support,
    };

    // Force
    // read from imput.zon
    bcs[1] = BoundaryCondition{
        .node_idx = beams[n_beams - 1].n1_idx,
        .type = .{ .Force = force_top },
    };

    return Mesh{
        .mat_props = mat_props,
        .nodes = nodes,
        .beams = beams,
        .bcs = bcs,
    };
}
