//+------------------------------------------------------------------+
//|                                             TestEAMyDateTime.mq5 |
//|                           Copyright 2021, Tobias Johannes Zimmer |
//|                                 https://www.mql5.com/pennyhunter |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Tobias Johannes Zimmer"
#property link      "https://www.mql5.com/pennyhunter"
#property version   "1.00"

#include <Tools\Custom\DateTimeMsc.mqh>

CDateTimeMsc time_msc_test;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

//--- Test the processing of ulong msc times
   ulong time_current_msc = ulong(1000 * TimeCurrent());
   time_msc_test.DateTime(TimeCurrent());

//--- test the manipulation  via increment/decrement
   time_msc_test.MscInc(55555);
   PrintCheck(time_msc_test);

   time_msc_test.MscInc(54321);
   PrintCheck(time_msc_test);

   time_msc_test.MscDec(54321);
   PrintCheck(time_msc_test);

   time_msc_test.MscDec(50000);  // 50000 msec = 50sec
   PrintCheck(time_msc_test);

//--- We want to know when the seconds since 1970 run out if we keep using integer as a time format
   Print("Last second IntTime: " + string(datetime(2147483646)));


//--- Test the processing of indeger times
   int time_current = int(TimeCurrent());
   time_msc_test.DateTime(time_current_msc);

//--- test the manipulation  via increment/decrement
   time_msc_test.MscInc(55555);
   PrintCheck(time_msc_test);

   time_msc_test.MscInc(54321);
   PrintCheck(time_msc_test);

   time_msc_test.MscDec(54321);
   PrintCheck(time_msc_test);

   time_msc_test.MscDec(50000);  // 50000 msec = 50sec
   PrintCheck(time_msc_test);


//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   ExpertRemove();
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PrintCheck(CDateTimeMsc &time)
  {
   Print("--------------------------------------------");
   Print("Time_Seconds: " + string(time.SecTime()));
   Print("DateTime: " + string(time.DateTime()));
   Print("MscTime: " + string(time.MscTime()));
   Print("IntTime: " + string(time.SecTime()));
   Print("--------------------------------------------");
  }
//+------------------------------------------------------------------+
