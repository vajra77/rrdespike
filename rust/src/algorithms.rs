pub enum ReplacementPolicy {
    ReplaceWithNan,
    ReplaceWithPrevious,
    ReplaceWithMedian,
}

/// Sostituisce i punti che superano le soglie fisse
pub fn clean_spikes_threshold(
    data: &mut [f64],
    min_val: f64,
    max_val: f64,
    policy: ReplacementPolicy,
) {
    let mut last_valid = f64::NAN;

    for val in data.iter_mut() {
        if !val.is_nan() {
            if *val < min_val || *val > max_val {
                match policy {
                    ReplacementPolicy::ReplaceWithNan => *val = f64::NAN,
                    ReplacementPolicy::ReplaceWithPrevious => *val = last_valid,
                    ReplacementPolicy::ReplaceWithMedian => *val = (min_val + max_val) / 2.0,
                }
            } else {
                last_valid = *val;
            }
        }
    }
}

/// Interpola linearmente sequenze di NaN brevi (<= max_gap)
pub fn interpolate_nan(data: &mut [f64], max_gap: usize) {
    let len = data.len();
    if len < 3 {
        return;
    }

    let mut i = 0;
    while i < len - 1 {
        if !data[i].is_nan() && data[i + 1].is_nan() {
            let start_idx = i;
            let y_start = data[i];

            let mut end_idx = i + 1;
            while end_idx < len && data[end_idx].is_nan() {
                end_idx += 1;
            }

            if end_idx < len {
                let gap_len = end_idx - start_idx - 1;

                if gap_len <= max_gap {
                    let y_end = data[end_idx];
                    let step_slope = (y_end - y_start) / ((gap_len + 1) as f64);

                    for fill_idx in (start_idx + 1)..end_idx {
                        data[fill_idx] = y_start + step_slope * ((fill_idx - start_idx) as f64);
                    }
                }
                i = end_idx;
            } else {
                break;
            }
        } else {
            i += 1;
        }
    }
}