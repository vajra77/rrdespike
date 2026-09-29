use rrdespike::algorithms;
use rrdespike::RrdFile;
use std::env;
use std::process::ExitCode;

fn main() -> ExitCode {
    let args: Vec<String> = env::args().collect();

    if args.len() < 3 {
        eprintln!("Uso: {} <file_input.rrd> <file_output.rrd>", args[0]);
        return ExitCode::FAILURE;
    }

    let in_path = &args[1];
    let out_path = &args[2];

    let max_traffic_threshold = 1_250_000_000.0; // 10 Gbit/s in Byte/s
    let max_interpolation_gap = 6;

    println!("Caricamento file RRD: {} ...", in_path);
    let mut rrd = match RrdFile::load(in_path) {
        Ok(f) => f,
        Err(e) => {
            eprintln!("Errore durante il caricamento del file RRD: {}", e);
            return ExitCode::FAILURE;
        }
    };

    println!(
        "Filtraggio spike sul canale DS 1 (Soglia: {}) ...",
        max_traffic_threshold
    );
    rrd.clean_ds_spikes(1, max_traffic_threshold);

    println!(
        "Interpolazione NaN (Max gap: {} campioni) ...",
        max_interpolation_gap
    );
    algorithms::interpolate_nan(&mut rrd.data, max_interpolation_gap);

    println!("Salvataggio file pulito: {} ...", out_path);
    if let Err(e) = rrd.save(out_path) {
        eprintln!("Errore durante il salvataggio: {}", e);
        return ExitCode::FAILURE;
    }

    println!("Operazione completata con successo.");
    ExitCode::SUCCESS
}