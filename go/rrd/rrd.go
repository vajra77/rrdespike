package rrd

import (
	"encoding/binary"
	"fmt"
	"math"
	"os"
	"unsafe"
)

type File struct {
	StatHead Header
	DsDefs   []DataSource
	RraDefs  []RraDefinition
	LiveHead LiveHeader
	PdpPreps []PdpPrep
	CdpPreps []CdpPrep
	RraPtrs  []RraPointer
	Data     []float64
}

// nativeEndian rileva l'endianness del sistema corrente
var nativeEndian binary.ByteOrder

func init() {
	buf := [2]byte{}
	*(*uint16)(unsafe.Pointer(&buf[0])) = uint16(0xABCD)
	if buf[0] == 0xCD {
		nativeEndian = binary.LittleEndian
	} else {
		nativeEndian = binary.BigEndian
	}
}

// Load carica un file RRD da disco
func Load(path string) (*File, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	rrdObj := &File{}

	// 1. Header Statico
	if err := binary.Read(f, nativeEndian, &rrdObj.StatHead); err != nil {
		return nil, fmt.Errorf("errore lettura StatHead: %w", err)
	}

	dsCnt := int(rrdObj.StatHead.DsCnt)
	rraCnt := int(rrdObj.StatHead.RraCnt)

	// 2. Data Sources
	rrdObj.DsDefs = make([]DataSource, dsCnt)
	if err := binary.Read(f, nativeEndian, &rrdObj.DsDefs); err != nil {
		return nil, fmt.Errorf("errore lettura DsDefs: %w", err)
	}

	// 3. Definizioni RRA
	rrdObj.RraDefs = make([]RraDefinition, rraCnt)
	if err := binary.Read(f, nativeEndian, &rrdObj.RraDefs); err != nil {
		return nil, fmt.Errorf("errore lettura RraDefs: %w", err)
	}

	// 4. Live Header
	if err := binary.Read(f, nativeEndian, &rrdObj.LiveHead); err != nil {
		return nil, fmt.Errorf("errore lettura LiveHead: %w", err)
	}

	// 5. PDP Prep
	rrdObj.PdpPreps = make([]PdpPrep, dsCnt)
	if err := binary.Read(f, nativeEndian, &rrdObj.PdpPreps); err != nil {
		return nil, fmt.Errorf("errore lettura PdpPreps: %w", err)
	}

	// 6. CDP Prep
	rrdObj.CdpPreps = make([]CdpPrep, rraCnt*dsCnt)
	if err := binary.Read(f, nativeEndian, &rrdObj.CdpPreps); err != nil {
		return nil, fmt.Errorf("errore lettura CdpPreps: %w", err)
	}

	// 7. Puntatori RRA
	rrdObj.RraPtrs = make([]RraPointer, rraCnt)
	if err := binary.Read(f, nativeEndian, &rrdObj.RraPtrs); err != nil {
		return nil, fmt.Errorf("errore lettura RraPtrs: %w", err)
	}

	// 8. Sezione Dati
	var totalValues int
	for _, rra := range rrdObj.RraDefs {
		totalValues += int(rra.RowCnt) * dsCnt
	}

	rrdObj.Data = make([]float64, totalValues)
	if err := binary.Read(f, nativeEndian, &rrdObj.Data); err != nil {
		return nil, fmt.Errorf("errore lettura Data: %w", err)
	}

	return rrdObj, nil
}

// Save scrive la struttura del file RRD su disco
func (r *File) Save(path string) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	sections := []interface{}{
		&r.StatHead,
		r.DsDefs,
		r.RraDefs,
		&r.LiveHead,
		r.PdpPreps,
		r.CdpPreps,
		r.RraPtrs,
		r.Data,
	}

	for _, sec := range sections {
		if err := binary.Write(f, nativeEndian, sec); err != nil {
			return fmt.Errorf("errore scrittura su file: %w", err)
		}
	}

	return nil
}

// CleanDSSpikes applica la pulizia degli spike isolando il Data Source desiderato (1-based index)
func (r *File) CleanDSSpikes(dsIdx int, maxVal float64) {
	dsCount := int(r.StatHead.DsCnt)
	if dsIdx < 1 || dsIdx > dsCount {
		return
	}

	idx := dsIdx - 1 // Converti a 0-based index
	for idx < len(r.Data) {
		val := r.Data[idx]
		if !math.IsNaN(val) && (val < 0.0 || val > maxVal) {
			r.Data[idx] = math.NaN()
		}
		idx += dsCount
	}
}
