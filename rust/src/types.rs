pub type String4 = [u8; 4];
pub type String5 = [u8; 5];
pub type String20 = [u8; 20];
pub type String30 = [u8; 30];

pub type RrdFloat = f64;
pub type RrdUlong = u64;

#[repr(C)]
#[derive(Copy, Clone)]
pub union Unival {
    pub ulong_val: RrdUlong,
    pub float_val: RrdFloat,
}

impl Default for Unival {
    fn default() -> Self {
        Unival { float_val: 0.0 }
    }
}

pub type UnivalArray10 = [Unival; 10];