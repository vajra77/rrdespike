package main

import (
	"fmt"
	"os"

	"rrdespike/rrd"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Printf("Uso: %s <file_input.rrd> <file_output.rrd>\n", os.Args[0])
		os.Exit(1)
	}

	inPath := os.Args[1]
	outPath := os.Args[2]

	const maxTrafficThreshold = 1250000000.0 // 10 Gbit/s espresso in Byte/s
	const maxInterpolationGap = 6

	fmt.Printf("Caricamento file RRD: %s ...\n", inPath)
	rrdFile, err := rrd.Load(inPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Errore caricamento: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Filtraggio spike sul canale DS 1 (Soglia: %g) ...\n", maxTrafficThreshold)
	rrdFile.CleanDSSpikes(1, maxTrafficThreshold)

	fmt.Printf("Interpolazione NaN (Max gap: %d campioni) ...\n", maxInterpolationGap)
	rrd.InterpolateNaN(rrdFile.Data, maxInterpolationGap)

	fmt.Printf("Salvataggio file pulito: %s ...\n", outPath)
	if err := rrdFile.Save(outPath); err != nil {
		fmt.Fprintf(os.Stderr, "Errore salvataggio: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Operazione completata con successo.")
}
