const std = @import("std");
const utils = @import("utils.zig");
const WoodPole = @import("wood_pole.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const woodPole = WoodPole{
        .height = 1.036e1,
        .bottom_diameter = 2.911e-1,
        .top_diameter = 1.86e-1,
        .fiber_strength = 5.52e7,
        .reduce_strength_factor = 3e-1,
        .modulus_of_elasticity = 1.468e10,
        .shear_modulus = 1e9,
        .density = 5.4463e2,
    };

    utils.print(woodPole);

    const mesh = try woodPole.buildMesh(allocator);
    defer mesh.deinit(allocator);

    for (mesh.material_properties) |props| utils.print(props);
    for (mesh.nodes) |node| utils.print(node);
    for (mesh.beams) |beam| utils.print(beam);
    for (mesh.bcs) |bc| utils.print(bc);
}
