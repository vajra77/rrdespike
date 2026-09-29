with Ada.Containers.Generic_Array_Sort;

package body RRD_Algorithms is
   function Make_NaN return RRD_Float is
      Zero : RRD_Float := 0.0;
   begin
      -- Azzeramento indiretto a runtime per evitare la valutazione statica di GNAT
      Zero := Zero + 0.0;
      return Zero / Zero;
   end Make_NaN;

   IEEE_NaN : constant RRD_Float := Make_NaN;

   -- Utility per verificare se un valore RRD_Float è NaN
   function Is_NaN (Val : RRD_Float) return Boolean is
   begin
      return Val /= Val; -- In IEEE 754, NaN è l'unico valore non uguale a se stesso
   end Is_NaN;

   ----------------------------
   -- Clean_Spikes_Threshold --
   ----------------------------

   procedure Clean_Spikes_Threshold
     (Data    : in out Value_Array;
      Min_Val : RRD_Float := 0.0;
      Max_Val : RRD_Float;
      Policy  : Replacement_Policy := Replace_With_NaN)
   is
      Last_Valid : RRD_Float := IEEE_NaN;
   begin
      for I in Data'Range loop
         if not Is_NaN (Data (I)) then
            -- Controllo se il dato supera i limiti
            if Data (I) < Min_Val or else Data (I) > Max_Val then
               case Policy is
                  when Replace_With_NaN =>
                     Data (I) := IEEE_NaN;
                  when Replace_With_Previous =>
                     Data (I) := Last_Valid;
                  when Replace_With_Median =>
                     Data (I) := (Min_Val + Max_Val) / 2.0;
               end case;
            else
               Last_Valid := Data (I);
            end if;
         end if;
      end loop;
   end Clean_Spikes_Threshold;

   --------------------------------
   -- Clean_Spikes_Moving_Median --
   --------------------------------

   procedure Clean_Spikes_Moving_Median
     (Data             : in out Value_Array;
      Window_Size      : Positive := 5;
      Threshold_Factor : RRD_Float := 3.5;
      Policy           : Replacement_Policy := Replace_With_Median)
   is
      -- Instanziazione di ordinamento per il calcolo della mediana
      procedure Sort_Window is new Ada.Containers.Generic_Array_Sort
        (Index_Type   => Positive,
         Element_Type => RRD_Float,
         Array_Type   => Value_Array);

      Half_Window : constant Natural := Window_Size / 2;
      Win_Buffer  : Value_Array (1 .. Window_Size);
      Valid_Count : Natural;
      Mediana     : RRD_Float;
      Diff        : RRD_Float;
      Mad         : RRD_Float; -- Median Absolute Deviation

      Original_Data : constant Value_Array := Data; -- Copia di lettura
   begin
      if Data'Length < Window_Size then
         return; -- Serie troppo corta per la finestra richiesta
      end if;

      for I in Data'First + Half_Window .. Data'Last - Half_Window loop
         if not Is_NaN (Original_Data (I)) then

            -- Extract valid non-NaN samples in current window
            Valid_Count := 0;
            for W in I - Half_Window .. I + Half_Window loop
               if not Is_NaN (Original_Data (W)) then
                  Valid_Count := Valid_Count + 1;
                  Win_Buffer (Valid_Count) := Original_Data (W);
               end if;
            end loop;

            if Valid_Count >= 3 then
               -- 1. Ordina la finestra per calcolare la Mediana
               Sort_Window (Win_Buffer (1 .. Valid_Count));
               Mediana := Win_Buffer ((Valid_Count + 1) / 2);

               -- 2. Calcola la deviazione assoluta
               Diff := abs (Original_Data (I) - Mediana);

               -- 3. Stima lo scarto medio (MAD)
               Mad := 0.0;
               for K in 1 .. Valid_Count loop
                  Mad := Mad + abs (Win_Buffer (K) - Mediana);
               end loop;
               Mad := Mad / RRD_Float (Valid_Count);

               -- 4. Rilevazione Spike
               if Mad > 0.0 and then (Diff / Mad) > Threshold_Factor then
                  case Policy is
                     when Replace_With_NaN =>
                        Data (I) := IEEE_NaN;
                     when Replace_With_Median =>
                        Data (I) := Mediana;
                     when Replace_With_Previous =>
                        Data (I) := Original_Data (I - 1);
                  end case;
               end if;
            end if;

         end if;
      end loop;
   end Clean_Spikes_Moving_Median;

   procedure Interpolate_NaN
     (Data    : in out Value_Array;
      Max_Gap : Positive := 10)
   is
      Start_Idx : Positive;
      End_Idx   : Positive;
      Gap_Len   : Natural;

      Y_Start   : RRD_Float;
      Y_End     : RRD_Float;
      Step_Slope: RRD_Float;

      I : Positive := Data'First;
   begin
      if Data'Length < 3 then
         return; -- Impossibile interpolare con meno di 3 punti
      end if;

      while I < Data'Last loop

         -- Trova il primo valore NaN preceduto da un valore valido
         if not Is_NaN (Data (I)) and then Is_NaN (Data (I + 1)) then

            Start_Idx := I;         -- Ultimo punto valido prima del gap
            Y_Start   := Data (I);

            -- Cerca la fine della sequenza di NaN
            End_Idx := I + 1;
            while End_Idx <= Data'Last and then Is_NaN (Data (End_Idx)) loop
               End_Idx := End_Idx + 1;
            end loop;

            -- Verifica se abbiamo trovato un valore finale valido entro i limiti del file
            if End_Idx <= Data'Last then
               Gap_Len := End_Idx - Start_Idx - 1;

               -- Applica l'interpolazione solo se il gap non supera Max_Gap
               if Gap_Len <= Max_Gap then
                  Y_End := Data (End_Idx);

                  -- Incremento costante per ciascun passo temporale
                  Step_Slope := (Y_End - Y_Start) / RRD_Float (Gap_Len + 1);

                  -- Calcola e sostituisce i valori intermedi
                  for Fill_Idx in Start_Idx + 1 .. End_Idx - 1 loop
                     Data (Fill_Idx) := Y_Start + Step_Slope * RRD_Float (Fill_Idx - Start_Idx);
                  end loop;
               end if;

               -- Avanza l'indice di ricerca oltre il gap elaborato
               I := End_Idx;
            else
               -- Il gap si estende fino alla fine del dataset: impossibile interpolare oltre
               exit;
            end if;
         else
            I := I + 1;
         end if;

      end loop;
   end Interpolate_NaN;

end RRD_Algorithms;