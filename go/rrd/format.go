package rrd

type Header struct {
	Cookie      String4
	Version     String5
	_           [7]byte // Padding di allineamento a 8 byte per FloatCookie
	FloatCookie RrdFloat
	DsCnt       RrdUlong
	RraCnt      RrdUlong
	PdpStep     RrdUlong
	Par         UnivalArray10
}

type DataSource struct {
	DsNam String20
	Dst   String20
	_     [8]byte // Padding di allineamento per Par
	Par   UnivalArray10
}

type RraDefinition struct {
	CfNam  String20
	_      [4]byte // Padding di allineamento a 8 byte per RowCnt
	RowCnt RrdUlong
	PdpCnt RrdUlong
	Par    UnivalArray10
}

type LiveHeader struct {
	LastUp     RrdUlong
	LastUpUsec int64
}

type PdpPrep struct {
	LastDs  String30
	_       [2]byte // Padding
	Record1 Unival
	UnkSec  RrdUlong
}

type CdpPrep struct {
	Value  Unival
	UnkPdp RrdUlong
}

type RraPointer struct {
	CurRow RrdUlong
}
