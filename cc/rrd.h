#ifndef RRD_H
#define RRD_H

#include "rrd_format.h"
#include <stddef.h>

typedef struct {
    stat_head_t  stat_head;
    ds_def_t    *ds_defs;
    rra_def_t   *rra_defs;
    live_head_t  live_head;
    pdp_prep_t  *pdp_preps;
    cdp_prep_t  *cdp_preps;
    rra_ptr_t   *rra_ptrs;
    double      *data;
    size_t       total_data_count;
} rrd_file_t;

rrd_file_t* rrd_load(const char *path);
int         rrd_save(const char *path, const rrd_file_t *rrd);
void        rrd_free(rrd_file_t *rrd);
void        rrd_clean_ds_spikes(rrd_file_t *rrd, size_t ds_idx, double max_val);

#endif /* RRD_H */
