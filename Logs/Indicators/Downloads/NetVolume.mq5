//+------------------------------------------------------------------+
//|                                                    NetVolume.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1

//--- plot ExtNV
#property indicator_label1  "NV"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- input parameters
input ENUM_APPLIED_VOLUME  InpVolume   =  VOLUME_TICK;   // Volume

//--- indicator buffers
double         ExtBufferNV[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtBufferNV,INDICATOR_DATA);
   
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(ExtBufferNV,true);
   
//--- setting the short name and levels for the indicator
   IndicatorSetString(INDICATOR_SHORTNAME,"Net Volume");
   IndicatorSetInteger(INDICATOR_LEVELS,1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0, 0.0);

//--- success
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- checking for the minimum number of bars for calculation
   if(rates_total<2)
      return 0;
      
//--- setting predefined indicator arrays as timeseries
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(volume,true);
   ArraySetAsSeries(tick_volume,true);
   
//--- checking and calculating the number of bars to be calculated
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-2;
      ArrayInitialize(ExtBufferNV,EMPTY_VALUE);
     }
     
//--- calculation Net Volume
   for(int i=limit; i>=0; i--)
     {
      double v=close[i]-close[i+1];
      char   sign=(v<0 ? -1 : v>0 ? 1 : 0);
      ExtBufferNV[i]=double(sign*(InpVolume==VOLUME_TICK ? tick_volume[i] : volume[i]));
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
