#ifndef RRD_ALGORITHMS_H
#define RRD_ALGORITHMS_H

#include <stddef.h>

typedef enum {
    REPLACE_WITH_NAN,
    REPLACE_WITH_PREVIOUS,
    REPLACE_WITH_MEDIAN
} replacement_policy_t;

void clean_spikes_threshold(double *data, size_t count, double min_val, double max_val, replacement_policy_t policy);
void interpolate_nan(double *data, size_t count, size_t max_gap);

#endif /* RRD_ALGORITHMS_H */
