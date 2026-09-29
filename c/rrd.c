#include "rrd.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

rrd_file_t* rrd_load(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;

    rrd_file_t *rrd = (rrd_file_t*) calloc(1, sizeof(rrd_file_t));
    if (!rrd) { fclose(f); return NULL; }

    /* 1. Header statico */
    if (fread(&rrd->stat_head, sizeof(stat_head_t), 1, f) != 1) goto error;

    size_t ds_cnt = (size_t) rrd->stat_head.ds_cnt;
    size_t rra_cnt = (size_t) rrd->stat_head.rra_cnt;

    /* Allocazione ed I/O delle sezioni dinamiche */
    rrd->ds_defs  = (ds_def_t*) malloc(sizeof(ds_def_t) * ds_cnt);
    rrd->rra_defs = (rra_def_t*) malloc(sizeof(rra_def_t) * rra_cnt);
    
    if (fread(rrd->ds_defs, sizeof(ds_def_t), ds_cnt, f) != ds_cnt) goto error;
    if (fread(rrd->rra_defs, sizeof(rra_def_t), rra_cnt, f) != rra_cnt) goto error;

    if (fread(&rrd->live_head, sizeof(live_head_t), 1, f) != 1) goto error;

    rrd->pdp_preps = (pdp_prep_t*) malloc(sizeof(pdp_prep_t) * ds_cnt);
    rrd->cdp_preps = (cdp_prep_t*) malloc(sizeof(cdp_prep_t) * (rra_cnt * ds_cnt));
    rrd->rra_ptrs  = (rra_ptr_t*)  malloc(sizeof(rra_ptr_t)  * rra_cnt);

    if (fread(rrd->pdp_preps, sizeof(pdp_prep_t), ds_cnt, f) != ds_cnt) goto error;
    if (fread(rrd->cdp_preps, sizeof(cdp_prep_t), rra_cnt * ds_cnt, f) != (rra_cnt * ds_cnt)) goto error;
    if (fread(rrd->rra_ptrs, sizeof(rra_ptr_t), rra_cnt, f) != rra_cnt) goto error;

    /* Calcolo dimensione sezione dati */
    rrd->total_data_count = 0;
    for (size_t i = 0; i < rra_cnt; i++) {
        rrd->total_data_count += ((size_t) rrd->rra_defs[i].row_cnt) * ds_cnt;
    }

    rrd->data = (double*) malloc(sizeof(double) * rrd->total_data_count);
    if (fread(rrd->data, sizeof(double), rrd->total_data_count, f) != rrd->total_data_count) goto error;

    fclose(f);
    return rrd;

error:
    fclose(f);
    rrd_free(rrd);
    return NULL;
}

int rrd_save(const char *path, const rrd_file_t *rrd) {
    if (!rrd) return -1;

    FILE *f = fopen(path, "wb");
    if (!f) return -1;

    size_t ds_cnt = (size_t) rrd->stat_head.ds_cnt;
    size_t rra_cnt = (size_t) rrd->stat_head.rra_cnt;

    fwrite(&rrd->stat_head, sizeof(stat_head_t), 1, f);
    fwrite(rrd->ds_defs, sizeof(ds_def_t), ds_cnt, f);
    fwrite(rrd->rra_defs, sizeof(rra_def_t), rra_cnt, f);
    fwrite(&rrd->live_head, sizeof(live_head_t), 1, f);
    fwrite(rrd->pdp_preps, sizeof(pdp_prep_t), ds_cnt, f);
    fwrite(rrd->cdp_preps, sizeof(cdp_prep_t), rra_cnt * ds_cnt, f);
    fwrite(rrd->rra_ptrs, sizeof(rra_ptr_t), rra_cnt, f);
    fwrite(rrd->data, sizeof(double), rrd->total_data_count, f);

    fclose(f);
    return 0;
}

void rrd_clean_ds_spikes(rrd_file_t *rrd, size_t ds_idx, double max_val) {
    if (!rrd || !rrd->data) return;

    size_t ds_count = (size_t) rrd->stat_head.ds_cnt;
    if (ds_idx < 1 || ds_idx > ds_count) return;

    size_t idx = ds_idx - 1; /* Conversione ad indice 0-based */
    while (idx < rrd->total_data_count) {
        double val = rrd->data[idx];
        if (!isnan(val) && (val < 0.0 || val > max_val)) {
            rrd->data[idx] = NAN;
        }
        idx += ds_count;
    }
}

void rrd_free(rrd_file_t *rrd) {
    if (!rrd) return;
    free(rrd->ds_defs);
    free(rrd->rra_defs);
    free(rrd->pdp_preps);
    free(rrd->cdp_preps);
    free(rrd->rra_ptrs);
    free(rrd->data);
    free(rrd);
}
