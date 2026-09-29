package RRD.Types is

   -- Stringhe a dimensione fissa modellate come array di caratteri C
   type String_4  is array (1 .. 4)  of aliased char with Convention => C;
   type String_5  is array (1 .. 5)  of aliased char with Convention => C;
   type String_20 is array (1 .. 20) of aliased char with Convention => C;

   -- Tipi numerici standard del formato RRD
   type RRD_Float is new double;
   type RRD_Ulong is new unsigned_long;

   -- Mappatura dell'unione C 'unival'
   type Unival_Kind is (As_Ulong, As_Float);

   type Unival (Kind : Unival_Kind := As_Float) is record
      case Kind is
         when As_Ulong =>
            Ulong_Val : RRD_Ulong;
         when As_Float =>
            Float_Val : RRD_Float;
      end case;
   end record
   with Convention => C_Pass_By_Copy, Size => 64;

   for Unival use record
      Kind      at 0 range 0 .. -1; -- Campo discriminante fittizio/invisibile
      Ulong_Val at 0 range 0 .. 63;
      Float_Val at 0 range 0 .. 63;
   end record;

   type Unival_Array_10 is array (1 .. 10) of Unival with Convention => C;

end RRD.Types;