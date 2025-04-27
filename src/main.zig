const std = @import("std");
const utils = @import("utils.zig");
const WoodPole = @import("WoodPole.zig");
const Matrix = @import("Matrix.zig");
const Mesh = @import("Mesh.zig");

pub fn main() !void {
    var gpa_instance = std.heap.DebugAllocator(.{ .safety = true }){};
    defer _ = gpa_instance.deinit();

    const gpa = gpa_instance.allocator();

    const pole = WoodPole{
        .height = 1.036e1,
        .bottom_diameter = 2.911e-1,
        .top_diameter = 1.86e-1,
        .fiber_strength = 5.52e7,
        .reduce_strength_factor = 3e-1,
        .modulus_of_elasticity = 1.468e10,
        .shear_modulus = 1e9,
        .density = 5.4463e2,
    };

    utils.print(pole);

    const mesh: Mesh = try pole.buildMesh(gpa);
    defer mesh.deinit(gpa);

    for (mesh.material_properties) |props| utils.print(props);
    for (mesh.nodes) |node| utils.print(node);
    for (mesh.beams) |beam| utils.print(beam);
    for (mesh.bcs) |bc| utils.print(bc);

    //
    // wip ...
    //
    const m_stiffness: Matrix = blk: {
        const n_nodes: u32 = @intCast(mesh.nodes.len);
        break :blk try Matrix.init(gpa, n_nodes, n_nodes);
    };
    defer m_stiffness.deinit(gpa);

    std.debug.print("{}", .{m_stiffness});
}

comptime {
    _ = @import("Matrix.zig");
}
