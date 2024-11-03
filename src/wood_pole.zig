const std = @import("std");
const utils = @import("utils.zig");
const Mesh = @import("mesh.zig");

const PI = std.math.pi;

height: f64,
bottom_diameter: f64,
top_diameter: f64,
fiber_strength: f64,
reduce_strength_factor: f64,
modulus_of_elasticity: f64,
shear_modulus: f64,
density: f64,

const Self = @This();

pub fn buildMesh(self: Self, allocator: std.mem.Allocator) !Mesh {
    var material_properties = try allocator.alloc(Mesh.MaterialProperties, 1);
    material_properties[0] = Mesh.MaterialProperties{
        .elasticity_modulus = self.modulus_of_elasticity,
        .shear_modulus = self.shear_modulus,
        .density = self.density,
    };

    // TODO: Safety checks here!!
    const n_beams: usize = @as(usize, @intFromFloat(self.height / Mesh.desired_element_size)) + 1;

    var nodes = try allocator.alloc(Mesh.Vect3, n_beams + 1);
    for (0..n_beams) |i| {
        nodes[i] = Mesh.Vect3{
            .x = 0.0,
            .y = 0.0,
            .z = @as(f32, @floatFromInt(i)) * Mesh.desired_element_size,
        };
        // TODO: TCXWoodPoleFem.fPoleNodesList[i] = i

    } else {
        // Last Node
        nodes[n_beams] = Mesh.Vect3{
            .x = 0.0,
            .y = 0.0,
            .z = self.height,
        };
    }

    var beams = try allocator.alloc(Mesh.Beam, n_beams);
    for (0..n_beams) |i| {
        const diameter: f64 = utils.evalLine(
            (nodes[i].z + nodes[i + 1].z) / 2.0,
            0.0,
            self.bottom_diameter,
            self.height,
            self.top_diameter,
        );

        const moment: f64 = PI * (diameter * diameter * diameter * diameter) / 64.0;

        beams[i] = Mesh.Beam{
            .material_props_index = 0,
            .n0_index = @intCast(i),
            .n1_index = @intCast(i + 1),
            .cross_area = PI * diameter * diameter / 4.0,
            .moment_x = moment,
            .moment_y = moment,
            .fJp = 2.0 * moment,
            .fIp = 2.0 * moment,
        };
    }

    var bcs = try allocator.alloc(Mesh.BeamBC, 1);
    bcs[0] = Mesh.BeamBC{
        .node_index = 0,
        .beam_index = 0,
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
        .material_properties = material_properties,
        .nodes = nodes,
        .beams = beams,
        .bcs = bcs,
    };
}
