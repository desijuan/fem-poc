const std = @import("std");
const utils = @import("utils.zig");
const WoodPole = @import("wood_pole.zig");
const Matrix = @import("matrix.zig");

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

    const m = try Matrix.init(allocator, 3, 3);
    defer m.deinit(allocator);

    try m.setEntries(&.{ 1, 2, 3, 4, 5, 6, 7, 8, 9 });
    m.set(3, 3, 99.0);

    m.e(2, 2).* = 7.75;

    std.debug.print("m[3, 3]: {}\n", .{m.get(3, 3)});
    std.debug.print("m[2, 2]: {}\n", .{m.e(2, 2).*});
    std.debug.print("m: {any}\n", .{m.entries});
}
