elasticity_modulus: f64, // fE [N/m^2]
shear_modulus: f64, // fG [N/m^2]
density: f64, // fRho [kg/m^3]

pub const format = @import("../utils.zig").structFormatFn(@This());
