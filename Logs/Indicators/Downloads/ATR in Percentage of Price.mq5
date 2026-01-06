//+------------------------------------------------------------------+
//|                        Indicator: ATR in Percentage of Price.mq5 |
//+------------------------------------------------------------------+
#property copyright "Created by abfs.tech"
#property link      "https://www.abfs.tech"
#property version   "1.00"
#property description ""

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots 1

#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1
#property indicator_color1 0xFFAA00
#property indicator_label1 "ATR as Percentage of Price"

//--- indicator buffers
double Buffer1[];

input int Period1 = 14;
double myPoint; //initialized in OnInit
int ATR_handle;
double ATR[];
double Open[];

void myAlert(string type, string message)
  {
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | ATR in Percentage of Price @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {   
   SetIndexBuffer(0, Buffer1);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
     {
      myPoint *= 10;
     }
   ATR_handle = iATR(NULL, PERIOD_CURRENT, Period1);
   if(ATR_handle < 0)
     {
      Print("The creation of iATR has failed: ATR_handle=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
   int limit = rates_total - prev_calculated;
   //--- counting from 0 to rates_total
   ArraySetAsSeries(Buffer1, true);
   //--- initial zero
   if(prev_calculated < 1)
     {
      ArrayInitialize(Buffer1, EMPTY_VALUE);
     }
   else
      limit++;
   
   if(BarsCalculated(ATR_handle) <= 0) 
      return(0);
   if(CopyBuffer(ATR_handle, 0, 0, rates_total, ATR) <= 0) return(rates_total);
   ArraySetAsSeries(ATR, true);
   if(CopyOpen(Symbol(), PERIOD_CURRENT, 0, rates_total, Open) <= 0) return(rates_total);
   ArraySetAsSeries(Open, true);
   //--- main loop
   for(int i = limit-1; i >= 0; i--)
     {
      if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   
      
      //Indicator Buffer 1
      if(true //no conditions!
      )
        {
         Buffer1[i] = ATR[i] / Open[i] * 100; //Set indicator value at Average True Range / Candlestick Open * fixed value
        }
      else
        {
         Buffer1[i] = EMPTY_VALUE;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+