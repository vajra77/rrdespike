with RRD.Types;  use RRD.Types;
with RRD.Format; use RRD.Format;

package RRD is

   -- Array dinamici allocati in base ai contatori presi da Header
   type Data_Source_Array is array (Positive range <>) of Data_Source;
   type RRA_Array         is array (Positive range <>) of RRA_Definition;
   type PDP_Prep_Array    is array (Positive range <>) of PDP_Prep;
   type CDP_Prep_Array    is array (Positive range <>) of CDP_Prep;
   type RRA_Pointer_Array is array (Positive range <>) of RRA_Pointer;

   -- Array dei dati double di tutte le RRA presenti nel database
   type Value_Array is array (Positive range <>) of RRD_Float;

   -- Pointers per gestire le sezioni dinamiche allocate nell'oggetto File
   type Data_Source_Access is access Data_Source_Array;
   type RRA_Access         is access RRA_Array;
   type PDP_Prep_Access    is access PDP_Prep_Array;
   type CDP_Prep_Access    is access CDP_Prep_Array;
   type RRA_Pointer_Access is access RRA_Pointer_Array;
   type Value_Access       is access Value_Array;

   -- Record principale che rappresenta il file RRD in memoria
   type File is record
      Stat_Head : Header;
      DS_Defs   : Data_Source_Access;
      RRA_Defs  : RRA_Access;
      Live_Head : Live_Header;
      PDP_Preps : PDP_Prep_Access;
      CDP_Preps : CDP_Prep_Access;
      RRA_Ptrs  : RRA_Pointer_Access;
      Data      : Value_Access;
   end record;

   -- Procedura per deallocare la memoria dinamica associata a File
   procedure Free (Obj : in out File);

   -- Operazioni di caricamento e salvataggio su disco
   procedure Load (Path : String; Obj : out File);
   procedure Save (Path : String; Obj : File);

   procedure Clean_DS_Spikes
     (Obj     : in out File;
      DS_Idx  : Positive;
      Max_Val : RRD_Float);

   -- Interpola i dati mancanti (NaN) presenti nelle serie storiche dell'oggetto File
   procedure Fix_Missing_Data
     (Obj     : in out File;
      Max_Gap : Positive := 12);

   RRD_Error : exception;

end RRD;