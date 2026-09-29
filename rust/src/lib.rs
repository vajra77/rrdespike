pub mod algorithms;
pub mod format;
pub mod types;

use format::*;
use std::fs::File;
use std::io::{self, Read, Write};
use std::mem::size_of;
use std::path::Path;

pub struct RrdFile {
    pub stat_head: Header,
    pub ds_defs: Vec<DataSource>,
    pub rra_defs: Vec<RraDefinition>,
    pub live_head: LiveHeader,
    pub pdp_preps: Vec<PdpPrep>,
    pub cdp_preps: Vec<CdpPrep>,
    pub rra_ptrs: Vec<RraPointer>,
    pub data: Vec<f64>,
}

impl RrdFile {
    /// Carica un file RRD leggendo i byte direttamente nelle struct
    pub fn load<P: AsRef<Path>>(path: P) -> io::Result<Self> {
        let mut file = File::open(path)?;

        fn read_struct<T: Default>(f: &mut File) -> io::Result<T> {
            let mut val = T::default();
            let slice = unsafe {
                std::slice::from_raw_parts_mut(&mut val as *mut T as *mut u8, size_of::<T>())
            };
            f.read_exact(slice)?;
            Ok(val)
        }

        fn read_vec<T: Default + Clone>(f: &mut File, count: usize) -> io::Result<Vec<T>> {
            let mut vec = vec![T::default(); count];
            let slice = unsafe {
                std::slice::from_raw_parts_mut(vec.as_mut_ptr() as *mut u8, count * size_of::<T>())
            };
            f.read_exact(slice)?;
            Ok(vec)
        }

        let stat_head: Header = read_struct(&mut file)?;
        let ds_cnt = stat_head.ds_cnt as usize;
        let rra_cnt = stat_head.rra_cnt as usize;

        let ds_defs: Vec<DataSource> = read_vec(&mut file, ds_cnt)?;
        let rra_defs: Vec<RraDefinition> = read_vec(&mut file, rra_cnt)?;
        let live_head: LiveHeader = read_struct(&mut file)?;
        let pdp_preps: Vec<PdpPrep> = read_vec(&mut file, ds_cnt)?;
        let cdp_preps: Vec<CdpPrep> = read_vec(&mut file, rra_cnt * ds_cnt)?;
        let rra_ptrs: Vec<RraPointer> = read_vec(&mut file, rra_cnt)?;

        let total_values: usize = rra_defs
            .iter()
            .map(|rra| (rra.row_cnt as usize) * ds_cnt)
            .sum();

        let data: Vec<f64> = read_vec(&mut file, total_values)?;

        Ok(RrdFile {
            stat_head,
            ds_defs,
            rra_defs,
            live_head,
            pdp_preps,
            cdp_preps,
            rra_ptrs,
            data,
        })
    }

    /// Salva la struttura RRD di nuovo su disco
    pub fn save<P: AsRef<Path>>(&self, path: P) -> io::Result<()> {
        let mut file = File::create(path)?;

        fn write_struct<T>(f: &mut File, val: &T) -> io::Result<()> {
            let slice = unsafe {
                std::slice::from_raw_parts(val as *const T as *const u8, size_of::<T>())
            };
            f.write_all(slice)
        }

        fn write_vec<T>(f: &mut File, vec: &[T]) -> io::Result<()> {
            let slice = unsafe {
                std::slice::from_raw_parts(vec.as_ptr() as *const u8, vec.len() * size_of::<T>())
            };
            f.write_all(slice)
        }

        write_struct(&mut file, &self.stat_head)?;
        write_vec(&mut file, &self.ds_defs)?;
        write_vec(&mut file, &self.rra_defs)?;
        write_struct(&mut file, &self.live_head)?;
        write_vec(&mut file, &self.pdp_preps)?;
        write_vec(&mut file, &self.cdp_preps)?;
        write_vec(&mut file, &self.rra_ptrs)?;
        write_vec(&mut file, &self.data)?;

        Ok(())
    }

    /// Pulisce gli spike filtrando solo lo specifico Data Source (`ds_idx` 1-based)
    pub fn clean_ds_spikes(&mut self, ds_idx: usize, max_val: f64) {
        let ds_count = self.stat_head.ds_cnt as usize;
        if ds_idx == 0 || ds_idx > ds_count {
            return;
        }

        let mut idx = ds_idx - 1; // Conversione a 0-based
        while idx < self.data.len() {
            let val = self.data[idx];
            if !val.is_nan() && (val < 0.0 || val > max_val) {
                self.data[idx] = f64::NAN;
            }
            idx += ds_count;
        }
    }
}