package rrd

import "math"

type String4 [4]byte
type String5 [5]byte
type String20 [20]byte
type String30 [30]byte

type RrdFloat = float64
type RrdUlong = uint64

// Unival simula l'unione C di 8 byte
type Unival struct {
	Value uint64
}

func (u *Unival) GetFloat() float64 {
	return math.Float64frombits(u.Value)
}

func (u *Unival) SetFloat(v float64) {
	u.Value = math.Float64bits(v)
}

func (u *Unival) GetUlong() uint64 {
	return u.Value
}

func (u *Unival) SetUlong(v uint64) {
	u.Value = v
}

type UnivalArray10 [10]Unival