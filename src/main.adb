with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Command_Line;    use Ada.Command_Line;
with Ada.Exceptions;      use Ada.Exceptions;

with RRD;              use RRD;
with RRD.Types;        use RRD.Types;
with RRD.Algorithms;   use RRD.Algorithms;

procedure Main is
   In_Path  : String_Access;
   Out_Path : String_Access;

   Input_RRD : RRD.File;

   -- Valore di soglia massimo per il traffico di rete (es. 10 Gbit/s in Byte/s)
   -- Modificabile in base alla velocità nominale dell'interfaccia.
   Max_Traffic_Threshold : constant RRD_Float := 625_000_000_000.0; -- 5 Tbps

   -- Dimensione massima della sequenza di NaN da interpolare (es. 6 campioni consecutive = 30 min se step = 300s)
   Max_Interpolation_Gap : constant Positive := 6;

begin
   -- 1. Validazione degli argomenti da riga di comando
   if Argument_Count < 2 then
      Put_Line ("Usage: " & Command_Name & " <file_input.rrd> <file_output.rrd>");
      Set_Exit_Status (Failure);
      return;
   end if;

   In_Path  := new String'(Argument (1));
   Out_Path := new String'(Argument (2));

   Put_Line ("Loading RRD file: " & In_Path.all & " ...");

   -- 2. Caricamento del file binario RRD in memoria
   RRD.Load (In_Path.all, Input_RRD);

   -- 3. Filtraggio degli Spike
   -- Sostituisce i valori superiori alla soglia fisica dell'interfaccia con NaN
   Put_Line ("Cleaning spikes (max threshold: " & Max_Traffic_Threshold'Img & ") ...");

   if Input_RRD.Data /= null then
      RRD.Algorithms.Clean_Spikes_Threshold
        (Data    => Input_RRD.Data.all,
         Min_Val => 0.0,
         Max_Val => Max_Traffic_Threshold,
         Policy  => RRD.Algorithms.Replace_With_NaN);

      -- 4. Interpolazione dei buco dati (NaN)
      Put_Line ("Interpolating null points (max gap: " & Max_Interpolation_Gap'Img & " samples) ...");

      RRD.Algorithms.Interpolate_NaN
        (Data    => Input_RRD.Data.all,
         Max_Gap => Max_Interpolation_Gap);
   end if;

   -- 5. Scrittura del file RRD pulito su disco
   Put_Line ("Saving clean file: " & Out_Path.all & " ...");
   RRD.Save (Out_Path.all, Input_RRD);

   -- Liberazione della memoria allocate
   RRD.Free (Input_RRD);

   Put_Line ("Despike successfully completed.");
   Set_Exit_Status (Success);

exception
   when E : RRD.RRD_Error =>
      Put_Line (Standard_Error, "RRD Error: " & Exception_Message (E));
      Set_Exit_Status (Failure);

   when E : others =>
      Put_Line (Standard_Error, "Unexpected error: " & Exception_Information (E));
      Set_Exit_Status (Failure);
end Main;