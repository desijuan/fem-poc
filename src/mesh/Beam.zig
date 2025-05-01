mat_props_idx: u32,
n0_idx: u32,
n1_idx: u32,
cross_area: f64, // fA
moment_x: f64, // fIz
moment_y: f64, // fIy
fJp: f64, // ?
fIp: f64, // ?

pub const format = @import("../utils.zig").structFormatFn(@This());
