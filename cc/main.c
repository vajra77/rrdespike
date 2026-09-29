#include <stdio.h>
#include <stdlib.h>
#include "rrd.h"
#include "rrd_algorithms.h"

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Uso: %s <file_input.rrd> <file_output.rrd>\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *in_path = argv[1];
    const char *out_path = argv[2];

    const double max_traffic_threshold = 1250000000.0; /* 10 Gbit/s in Byte/s */
    const size_t max_interpolation_gap = 6;

    printf("Caricamento file RRD: %s ...\n", in_path);
    rrd_file_t *rrd = rrd_load(in_path);
    if (!rrd) {
        fprintf(stderr, "Errore durante il caricamento del file RRD!\n");
        return EXIT_FAILURE;
    }

    printf("Filtraggio spike sul canale DS 1 (Soglia: %g) ...\n", max_traffic_threshold);
    rrd_clean_ds_spikes(rrd, 1, max_traffic_threshold);

    printf("Interpolazione NaN (Max gap: %zu campioni) ...\n", max_interpolation_gap);
    interpolate_nan(rrd->data, rrd->total_data_count, max_interpolation_gap);

    printf("Salvataggio file pulito: %s ...\n", out_path);
    if (rrd_save(out_path, rrd) != 0) {
        fprintf(stderr, "Errore durante il salvataggio del file!\n");
        rrd_free(rrd);
        return EXIT_FAILURE;
    }

    rrd_free(rrd);
    printf("Operazione completata con successo.\n");
    return EXIT_SUCCESS;
}
