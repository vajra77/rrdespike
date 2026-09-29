with Ada.Streams.Stream_IO; use Ada.Streams.Stream_IO;
with Ada.Unchecked_Deallocation;
with RRD_Algorithms;

package body RRD is
   subtype Long_Natural is Long_Long_Integer range 0 .. Long_Long_Integer'Last;

   procedure Free (Obj : in out File) is
      procedure Free_DS is new Ada.Unchecked_Deallocation (Data_Source_Array, Data_Source_Access);
      procedure Free_RRA is new Ada.Unchecked_Deallocation (RRA_Array, RRA_Access);
      procedure Free_PDP is new Ada.Unchecked_Deallocation (PDP_Prep_Array, PDP_Prep_Access);
      procedure Free_CDP is new Ada.Unchecked_Deallocation (CDP_Prep_Array, CDP_Prep_Access);
      procedure Free_Ptr is new Ada.Unchecked_Deallocation (RRA_Pointer_Array, RRA_Pointer_Access);
      procedure Free_Val is new Ada.Unchecked_Deallocation (Value_Array, Value_Access);
   begin
      Free_DS  (Obj.DS_Defs);
      Free_RRA (Obj.RRA_Defs);
      Free_PDP (Obj.PDP_Preps);
      Free_CDP (Obj.CDP_Preps);
      Free_Ptr (Obj.RRA_Ptrs);
      Free_Val (Obj.Data);
   end Free;

   ----------
   -- Load --
   ----------

   procedure Load (Path : String; Obj : out File) is
      Stream_File : Ada.Streams.Stream_IO.File_Type;
      S           : Stream_Access;
      DS_Count    : Natural;
      RRA_Count   : Natural;
      Total_PDP   : Natural;
      Total_CDP   : Natural;
      Total_Value : Long_Natural := 0;
   begin
      Open (Stream_File, In_File, Path);
      S := Stream (Stream_File);

      -- 1. Legge l'Header Statico
      Header'Read (S, Obj.Stat_Head);

      DS_Count  := Natural (Obj.Stat_Head.DS_Cnt);
      RRA_Count := Natural (Obj.Stat_Head.RRA_Cnt);

      -- 2. Legge i Data Source
      Obj.DS_Defs := new Data_Source_Array (1 .. DS_Count);
      for I in 1 .. DS_Count loop
         Data_Source'Read (S, Obj.DS_Defs (I));
      end loop;

      -- 3. Legge le definizioni RRA
      Obj.RRA_Defs := new RRA_Array (1 .. RRA_Count);
      for I in 1 .. RRA_Count loop
         RRA_Definition'Read (S, Obj.RRA_Defs (I));
      end loop;

      -- 4. Legge il Live Header
      Live_Header'Read (S, Obj.Live_Head);

      -- 5. Legge i blocchi di stato PDP Prep (uno per DS)
      Total_PDP := DS_Count;
      Obj.PDP_Preps := new PDP_Prep_Array (1 .. Total_PDP);
      for I in 1 .. Total_PDP loop
         PDP_Prep'Read (S, Obj.PDP_Preps (I));
      end loop;

      -- 6. Legge i blocchi di stato CDP Prep (RRA_Count * DS_Count)
      Total_CDP := RRA_Count * DS_Count;
      Obj.CDP_Preps := new CDP_Prep_Array (1 .. Total_CDP);
      for I in 1 .. Total_CDP loop
         CDP_Prep'Read (S, Obj.CDP_Preps (I));
      end loop;

      -- 7. Legge i puntatori di riga corrente per ciascuna RRA
      Obj.RRA_Ptrs := new RRA_Pointer_Array (1 .. RRA_Count);
      for I in 1 .. RRA_Count loop
         RRA_Pointer'Read (S, Obj.RRA_Ptrs (I));
      end loop;

      -- 8. Calcola il numero totale dei valori double memorizzati e li legge
      for I in 1 .. RRA_Count loop
         Total_Value := Total_Value + Long_Natural (Obj.RRA_Defs (I).Row_Cnt) * Long_Natural (DS_Count);
      end loop;

      Obj.Data := new Value_Array (1 .. Positive (Total_Value));
      for I in 1 .. Positive (Total_Value) loop
         RRD_Float'Read (S, Obj.Data (I));
      end loop;

      Close (Stream_File);
   exception
      when others =>
         if Is_Open (Stream_File) then
            Close (Stream_File);
         end if;
         Free (Obj);
         raise RRD_Error with "Errore durante il caricamento del file RRD: " & Path;
   end Load;

   ----------
   -- Save --
   ----------

   procedure Save (Path : String; Obj : File) is
      Stream_File : Ada.Streams.Stream_IO.File_Type;
      S           : Stream_Access;
   begin
      Create (Stream_File, Out_File, Path);
      S := Stream (Stream_File);

      -- Scrittura sequenziale nell'esatto ordine binario RRD
      Header'Write (S, Obj.Stat_Head);

      for I in Obj.DS_Defs'Range loop
         Data_Source'Write (S, Obj.DS_Defs (I));
      end loop;

      for I in Obj.RRA_Defs'Range loop
         RRA_Definition'Write (S, Obj.RRA_Defs (I));
      end loop;

      Live_Header'Write (S, Obj.Live_Head);

      for I in Obj.PDP_Preps'Range loop
         PDP_Prep'Write (S, Obj.PDP_Preps (I));
      end loop;

      for I in Obj.CDP_Preps'Range loop
         CDP_Prep'Write (S, Obj.CDP_Preps (I));
      end loop;

      for I in Obj.RRA_Ptrs'Range loop
         RRA_Pointer'Write (S, Obj.RRA_Ptrs (I));
      end loop;

      for I in Obj.Data'Range loop
         RRD_Float'Write (S, Obj.Data (I));
      end loop;

      Close (Stream_File);
   exception
      when others =>
         if Is_Open (Stream_File) then
            Close (Stream_File);
         end if;
         raise RRD_Error with "Errore durante il salvataggio del file RRD: " & Path;
   end Save;

   procedure Clean_DS_Spikes
     (Obj     : in out File;
      DS_Idx  : Positive;
      Max_Val : RRD_Float)
   is
      DS_Count    : constant Positive := Positive (Obj.Stat_Head.DS_Cnt);
      Total_Rows  : constant Natural  := Obj.Data'Length / DS_Count;

      -- Array temporaneo che conterra solo i dati del DS selezionato
      DS_Values   : Value_Array (1 .. Total_Rows);
      Read_Idx    : Positive;
   begin
      if Obj.Data = null or else DS_Idx > DS_Count then
         return;
      end if;

      -- 1. Estrazione dei campioni appartenenti a DS_Idx
      Read_Idx := DS_Idx;
      for I in DS_Values'Range loop
         DS_Values (I) := Obj.Data (Read_Idx);
         Read_Idx      := Read_Idx + DS_Count;
      end loop;

      -- 2. Applicazione del filtro sulla serie estratta
      RRD_Algorithms.Clean_Spikes_Threshold
        (Data    => DS_Values,
         Min_Val => 0.0,
         Max_Val => Max_Val,
         Policy  => RRD_Algorithms.Replace_With_NaN);

      -- 3. Riscrittura dei valori filtrati nell'array principale Data
      Read_Idx := DS_Idx;
      for I in DS_Values'Range loop
         Obj.Data (Read_Idx) := DS_Values (I);
         Read_Idx            := Read_Idx + DS_Count;
      end loop;
   end Clean_DS_Spikes;

   procedure Fix_Missing_Data
     (Obj     : in out File;
      Max_Gap : Positive := 12)
   is
   begin
      if Obj.Data /= null then
         -- Applica l'interpolazione lineare su tutto il buffer dei dati memorizzati
         RRD_Algorithms.Interpolate_NaN
           (Data    => Obj.Data.all,
            Max_Gap => Max_Gap);
      end if;
   end Fix_Missing_Data;

end RRD;