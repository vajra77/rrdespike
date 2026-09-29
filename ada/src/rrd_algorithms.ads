with RRD; use RRD;
with RRD_Types; use RRD_Types;

package RRD_Algorithms is

   -- Politica di sostituzione per lo spike rilevato
   type Replacement_Policy is (Replace_With_NaN, Replace_With_Previous, Replace_With_Median);

   ----------------------------------------------------------------------------
   -- 1. Filtraggio basato su soglia fissa (Min / Max)
   ----------------------------------------------------------------------------
   procedure Clean_Spikes_Threshold
     (Data        : in out Value_Array;
      Min_Val     : RRD_Float := 0.0;
      Max_Val     : RRD_Float;
      Policy      : Replacement_Policy := Replace_With_NaN);

   ----------------------------------------------------------------------------
   -- 2. Filtraggio statistico basato su Mediana Mobile e Deviazione
   --    Window_Size: numero di campioni attorno al punto (deve essere dispari)
   --    Threshold_Factor: quanti "scarti medi" tollerare prima di considerare spike
   ----------------------------------------------------------------------------
   procedure Clean_Spikes_Moving_Median
     (Data             : in out Value_Array;
      Window_Size      : Positive := 5;
      Threshold_Factor : RRD_Float := 3.5;
      Policy           : Replacement_Policy := Replace_With_Median);

   procedure Interpolate_NaN
     (Data    : in out Value_Array;
      Max_Gap : Positive := 10);

end RRD_Algorithms;