with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Command_Line;      use Ada.Command_Line;
with Ada.Real_Time;         use Ada.Real_Time;

procedure Rrdespike is

   -- Mostra la Guida per l'utente
   procedure Print_Usage is
   begin
      Put_Line ("Uso: rrdespike <file.rrd> [soglia_max_gbps] [sigma]");
      Put_Line ("  file.rrd         : Percorso del file binario RRD da pulire");
      Put_Line ("  soglia_max_gbps  : (Opzionale) Limite di banda fisico in Gbps (Default: 10.0)");
      Put_Line ("  sigma            : (Opzionale) Deviazione filtro Hampel (Default: 3.5)");
   end Print_Usage;

begin
   null
end Rrdespike;
