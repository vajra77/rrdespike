package rrd

import "math"

type ReplacementPolicy int

const (
	ReplaceWithNaN ReplacementPolicy = iota
	ReplaceWithPrevious
	ReplaceWithMedian
)

// CleanSpikesThreshold sostituisce i punti che superano le soglie fisse
func CleanSpikesThreshold(data []float64, minVal, maxVal float64, policy ReplacementPolicy) {
	lastValid := math.NaN()

	for i := range data {
		val := data[i]
		if !math.IsNaN(val) {
			if val < minVal || val > maxVal {
				switch policy {
				case ReplaceWithNaN:
					data[i] = math.NaN()
				case ReplaceWithPrevious:
					data[i] = lastValid
				case ReplaceWithMedian:
					data[i] = (minVal + maxVal) / 2.0
				}
			} else {
				lastValid = val
			}
		}
	}
}

// InterpolateNaN interpola linearmente sequenze di NaN brevi (<= maxGap)
func InterpolateNaN(data []float64, maxGap int) {
	length := len(data)
	if length < 3 {
		return
	}

	i := 0
	for i < length-1 {
		if !math.IsNaN(data[i]) && math.IsNaN(data[i+1]) {
			startIdx := i
			yStart := data[i]

			endIdx := i + 1
			for endIdx < length && math.IsNaN(data[endIdx]) {
				endIdx++
			}

			if endIdx < length {
				gapLen := endIdx - startIdx - 1

				if gapLen <= maxGap {
					yEnd := data[endIdx]
					stepSlope := (yEnd - yStart) / float64(gapLen+1)

					for fillIdx := startIdx + 1; fillIdx < endIdx; fillIdx++ {
						data[fillIdx] = yStart + stepSlope*float64(fillIdx-startIdx)
					}
				}
				i = endIdx
			} else {
				break
			}
		} else {
			i++
		}
	}
}
