#ifndef RRD_FORMAT_H
#define RRD_FORMAT_H

#include "rrd_types.h"

typedef struct {
    string4_t        cookie;        /* "RRD\0" */
    string5_t        version;       /* "0003\0" o "0004\0" */
    char             _pad[7];       /* Padding a 8 byte per float_cookie */
    rrd_float_t      float_cookie;  /* 8.642135e130 */
    rrd_ulong_t      ds_cnt;
    rrd_ulong_t      rra_cnt;
    rrd_ulong_t      pdp_step;
    unival_array10_t par;
} stat_head_t;

typedef struct {
    string20_t       ds_nam;
    string20_t       dst;
    char             _pad[8];       /* Padding per unival */
    unival_array10_t par;
} ds_def_t;

typedef struct {
    string20_t       cf_nam;
    char             _pad[4];       /* Padding per row_cnt */
    rrd_ulong_t      row_cnt;
    rrd_ulong_t      pdp_cnt;
    unival_array10_t par;
} rra_def_t;

typedef struct {
    rrd_ulong_t      last_up;
    int64_t          last_up_usec;
} live_head_t;

typedef struct {
    string30_t       last_ds;
    char             _pad[2];
    unival_t         record_1;
    rrd_ulong_t      unk_sec;
} pdp_prep_t;

typedef struct {
    unival_t         value;
    rrd_ulong_t      unk_pdp;
} cdp_prep_t;

typedef struct {
    rrd_ulong_t      cur_row;
} rra_ptr_t;

#endif /* RRD_FORMAT_H */
