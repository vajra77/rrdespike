#ifndef RRD_TYPES_H
#define RRD_TYPES_H

#include <stdint.h>

typedef char string4_t[4];
typedef char string5_t[5];
typedef char string20_t[20];
typedef char string30_t[30];

typedef double rrd_float_t;
typedef uint64_t rrd_ulong_t;

/* L'unione originale C unival utilizzata negli header RRD */
typedef union {
    rrd_ulong_t ulong_val;
    rrd_float_t float_val;
} unival_t;

typedef unival_t unival_array10_t[10];

#endif /* RRD_TYPES_H */
