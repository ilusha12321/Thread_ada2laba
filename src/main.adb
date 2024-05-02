-- Vykorystani pakyety
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Calendar; use Ada.Calendar;

procedure Main is

   -- Konstanty dlya rozmiru masivu ta kilkosti potokiv
   number_of_cells : constant Long_Long_Integer := 200000;
   thread_num : constant Long_Long_Integer := 4;

   -- Indeks elementu, yakyi bude vypadkovo zminenyy na vid'yemne znachennya
   index_random: Long_Long_Integer := 4567;

   -- Masiv dlya obchyslen'
   arr : array(0..number_of_cells) of Long_Long_Integer;

   -- Protsedura initsializatsii masivu
   procedure Init_Arr is
   begin
      for i in 1..number_of_cells loop
         arr(i) := i;
      end loop;
      arr(index_random):=arr(index_random)*(-1); -- Vypadkova zmina odnoho elementu na vid'yemne znachennya
   end Init_Arr;

   -- Funktsiya dlya poshuku minimal'noho elementu v mezhakh pidmasivu
   function part_min(start_index, finish_index : in Long_Long_Integer) return Long_Long_Integer is
      min : Long_Long_Integer := arr(start_index);
   begin
      for i in start_index..finish_index loop
         if(min>arr(i)) then
            min:=arr(i);
         end if;
      end loop;
      return min;
   end part_min;

   -- Zadacha dlya stvorennia potokiv
   task type starter_thread is
      entry start(start_index, finish_index : in Long_Long_Integer);
   end starter_thread;

   -- Zakhystena oblast' dlya obrobky rezultativ
   protected part_manager is
      procedure set_part_min(min : in Long_Long_Integer);
      entry get_min(min2 : out Long_Long_Integer);
   private
      tasks_count : Long_Long_Integer := 0;  -- Lichylnyk zakinchennykh zavdan'
      min1 : Long_Long_Integer := arr(1);   -- Potochne minimal'ne znachennya
   end part_manager;

   -- Realizatsiya zakhystenoi oblasti
   protected body part_manager is
      procedure set_part_min(min : in Long_Long_Integer) is
      begin
         if (min1>min) then
            min1 :=min; -- Ohnovenya minimal'noho znachennya
         end if;
         tasks_count := tasks_count + 1; -- Zbil'shennya lichylnyka zakinchennykh zavdan'
      end set_part_min;
      entry get_min(min2 : out Long_Long_Integer) when tasks_count = thread_num is -- Povernennya minimal'noho znachennya, koly vsi potoky zakincheni
      begin
         min2 := min1;
      end get_min;
   end part_manager;

   -- Tilo zadachi dlya obchyslennya minimumu
   task body starter_thread is
      min : Long_Long_Integer := 0;  -- Lokal'na zminna dlya zberihannya minimal'noho znachennya
      start_index, finish_index : Long_Long_Integer;  -- Indeksy pochatku ta kintsya pidmasivu
   begin
      accept start(start_index, finish_index : in Long_Long_Integer) do
         starter_thread.start_index := start_index;
         starter_thread.finish_index := finish_index;
      end start;
      min := part_min(start_index  => start_index, finish_index => finish_index); -- Vykluk funktsiyi dlya znaodzhennya minimumu
      part_manager.set_part_min(min);  -- Zberezhennya minimal'noho znachennya v zakhystenii oblasti
   end starter_thread;

   -- Funktsiya dlya obchyslennya minimal'noho znachennya v masivi za dopomohoyu kil'kokh potokiv
   function parallel_sum return Long_Long_Integer is
      min : Long_Long_Integer := 0;  -- Zminna dlya zberezhennya minimal'noho znachennya
      thread : array(1..thread_num) of starter_thread;  -- Masiv potokiv
      len : Long_Long_Integer:= number_of_cells/thread_num;  -- Rozmir pidmasivu dlya kozhnoho potoku
   begin
      for i in  1..thread_num-1 loop
         thread(i).start((i-1)*len,i*len); -- Zapusk potokiv
      end loop;
      thread(thread_num).start(len*(thread_num-1), number_of_cells); -- Zapusk ostann'oho potoku
      part_manager.get_min(min); -- Ottenennya minimal'noho znachennya z zakhystenoi oblasti
      return min;  -- Povernennya minimal'noho znachennya
   end parallel_sum;

   -- Chas pochatku vykonannya programy
   time :Ada.Calendar.Time := Clock;
   finish_time :Duration;
   rezult:Long_Long_Integer;

begin
   Init_Arr;  -- Initsializatsiya masivu
   time:=Clock;  -- Zberezhennya pochatkovoho chasu
   rezult:=part_min(0, number_of_cells);  -- Obchyslennya minimal'noho znachennya v odnopotokovomu rezhymi
   finish_time:=Clock-time;  -- Obchyslennya chasu vykonannya
   Put_Line(rezult'img &" one thread time: " & finish_time'img & " seconds");  -- Vydannia rezultatu

   time:=Clock;  -- Zberezhennya pochatkovoho chasu
   rezult:=parallel_sum;  -- Obchyslennya minimal'noho znachennya v bahatopotokovomu rezhymi
   finish_time:=Clock-time;  -- Obchyslennya chasu vykonannya
   Put_Line(rezult'img &" more thread time: " & finish_time'img & " seconds");  -- Vydannia rezultatu
end Main;
