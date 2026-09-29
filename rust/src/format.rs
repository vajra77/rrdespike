use crate::types::*;

#[repr(C)]
#[derive(Copy, Clone, Default)]
pub struct Header {
    pub cookie: String4,       // "RRD\0"
    pub version: String5,      // "0003\0" o "0004\0"
    pub float_cookie: RrdFloat,// 8.642135e130
    pub ds_cnt: RrdUlong,
    pub rra_cnt: RrdUlong,
    pub pdp_step: RrdUlong,
    pub par: UnivalArray10,
}

#[repr(C)]
#[derive(Copy, Clone, Default)]
pub struct DataSource {
    pub ds_nam: String20,
    pub dst: String20,
    pub par: UnivalArray10,
}

#[repr(C)]
#[derive(Copy, Clone, Default)]
pub struct RraDefinition {
    pub cf_nam: String20,
    pub row_cnt: RrdUlong,
    pub pdp_cnt: RrdUlong,
    pub par: UnivalArray10,
}

#[repr(C)]
#[derive(Copy, Clone, Default)]
pub struct LiveHeader {
    pub last_up: RrdUlong,
    pub last_up_usec: i64,
}

#[repr(C)]
#[derive(Copy, Clone, Default)]
pub struct PdpPrep {
    pub last_ds: String30,
    pub record_1: Unival,
    pub unk_sec: RrdUlong,
}

#[repr(C)]
#[derive(Copy, Clone, Default)]
pub struct CdpPrep {
    pub value: Unival,
    pub unk_pdp: RrdUlong,
}

#[repr(C)]
#[derive(Copy, Clone, Default)]
pub struct RraPointer {
    pub cur_row: RrdUlong,
}