#include "rrd_algorithms.h"
#include <math.h>

void clean_spikes_threshold(double *data, size_t count, double min_val, double max_val, replacement_policy_t policy) {
    double last_valid = NAN;

    for (size_t i = 0; i < count; i++) {
        if (!isnan(data[i])) {
            if (data[i] < min_val || data[i] > max_val) {
                switch (policy) {
                    case REPLACE_WITH_NAN:
                        data[i] = NAN;
                        break;
                    case REPLACE_WITH_PREVIOUS:
                        data[i] = last_valid;
                        break;
                    case REPLACE_WITH_MEDIAN:
                        data[i] = (min_val + max_val) / 2.0;
                        break;
                }
            } else {
                last_valid = data[i];
            }
        }
    }
}

void interpolate_nan(double *data, size_t count, size_t max_gap) {
    if (count < 3) return;

    size_t i = 0;
    while (i < count - 1) {
        if (!isnan(data[i]) && isnan(data[i + 1])) {
            size_t start_idx = i;
            double y_start = data[i];

            size_t end_idx = i + 1;
            while (end_idx < count && isnan(data[end_idx])) {
                end_idx++;
            }

            if (end_idx < count) {
                size_t gap_len = end_idx - start_idx - 1;

                if (gap_len <= max_gap) {
                    double y_end = data[end_idx];
                    double step_slope = (y_end - y_start) / (double)(gap_len + 1);

                    for (size_t fill_idx = start_idx + 1; fill_idx < end_idx; fill_idx++) {
                        data[fill_idx] = y_start + step_slope * (double)(fill_idx - start_idx);
                    }
                }
                i = end_idx;
            } else {
                break;
            }
        } else {
            i++;
        }
    }
}
