with Interfaces.C; use Interfaces.C;
with RRD_Types; use RRD_Types;

package RRD_Format is

    type Header is record
      Cookie       : String_4;        -- "RRD\0"
      Version      : String_5;        -- "0003\0" o "0004\0"
      Float_Cookie : RRD_Float;       -- 8.642135e130 per verficarne l'endianness
      DS_Cnt       : RRD_Ulong;       -- Numero di Data Source presenti
      RRA_Cnt      : RRD_Ulong;       -- Numero di RRA presenti
      PDP_Step     : RRD_Ulong;       -- Passo base in secondi (es. 300)
      Par          : Unival_Array_10; -- Parametri riservati
   end record
   with Convention => C;

   for Header use record
      Cookie       at 0   range 0 .. 31;
      Version      at 4   range 0 .. 39;
      -- Padding di 3 byte aggiunto dal compilatore C per allineare Float_Cookie a 8 byte
      Float_Cookie at 16  range 0 .. 63;
      DS_Cnt       at 24  range 0 .. 63;
      RRA_Cnt      at 32  range 0 .. 63;
      PDP_Step     at 40  range 0 .. 63;
      Par          at 48  range 0 .. 639; -- 10 * 8 byte = 80 byte
   end record;

   type Data_Source is record
      DS_Nam : String_20;       -- Nome del DS (null-terminated)
      DST    : String_20;       -- Tipo DS: GAUGE, COUNTER, DERIVE, ABSOLUTE
      Par    : Unival_Array_10; -- Par(1)=Heartbeat, Par(2)=Min, Par(3)=Max
   end record
   with Convention => C;

   for Data_Source use record
      DS_Nam at 0   range 0 .. 159;  -- 20 byte
      DST    at 20  range 0 .. 159;  -- 20 byte
      -- Padding di 8 byte aggiunto da RRD per allineare l'array di Unival
      Par    at 48  range 0 .. 639;  -- 80 byte
   end record;
   -- Dimensione totale Data_Source = 128 byte

   type RRA_Definition is record
      CF_Nam  : String_20;       -- Funzione di Consolidamento: AVERAGE, MAX, MIN, LAST
      Row_Cnt : RRD_Ulong;       -- Numero totale di righe nel buffer circolare
      PDP_Cnt : RRD_Ulong;       -- Quanti punti primari servono per 1 punto RRA
      Par     : Unival_Array_10; -- Par(1) = xff (Xfiles Factor)
   end record
   with Convention => C;

   for RRA_Definition use record
      CF_Nam  at 0   range 0 .. 159; -- 20 byte
      -- Padding di 4 byte aggiunto per allineare Row_Cnt a 8 byte
      Row_Cnt at 24  range 0 .. 63;  -- 8 byte
      PDP_Cnt at 32  range 0 .. 63;  -- 8 byte
      Par     at 40 range 0 .. 639; -- 80 byte
   end record;
   -- Dimensione totale RRA_Definition = 120 byte

   type Live_Header is record
      Last_Up      : RRD_Ulong; -- UNIX Timestamp dell'ultimo update (time_t 64-bit)
      Last_Up_Usec : long;      -- Microsecondi associati (long 64-bit su x86_64)
   end record
   with Convention => C;

   for Live_Header use record
      Last_Up      at 0 range 0 .. 63;
      Last_Up_Usec at 8 range 0 .. 63;
   end record;
   -- Dimensione totale Live_Header = 16 byte

   -- 1. Stato temporaneo PDP (un array per DS)
   type PDP_Prep is record
      Last_DS  : String_30; -- Ultima lettura grezza sotto forma di stringa
      Record_1 : Unival;    -- Valore temporaneo accumulato
      Unk_Sec  : RRD_Ulong; -- Secondi sconosciuti nel periodo
   end record with Convention => C;

   -- 2. Stato temporaneo CDP (array di dimensioni DS_Cnt * RRA_Cnt)
   type CDP_Prep is record
      Value   : Unival;     -- Valore consolidato temporaneo
      Unk_PDP : RRD_Ulong;  -- PDP sconosciuti nell'intervallo corrente
   end record with Convention => C;

   -- 3. Puntatore di riga corrente per RRA (un array di dimensione RRA_Cnt)
   type RRA_Pointer is record
      Cur_Row : RRD_Ulong;  -- Indice della riga corrente nel buffer circolare
   end record with Convention => C;

end RRD_Format;