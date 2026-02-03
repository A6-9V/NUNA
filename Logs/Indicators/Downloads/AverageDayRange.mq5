//+------------------------------------------------------------------+
//|                                              AverageDayRange.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property description "Average Day Range is an indicator that measures the volatility of an asset."
#property description "It shows the average movement of the price between the high and the low over the last several days."

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1

//--- plot ADR
#property indicator_label1  "ADR"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- includes
#include <MovingAverages.mqh>

//--- input parameters
input uint     InpLength   =  14;   // Length

//--- indicator buffers
double         ExtBufferADR[];
double         ExtBufferTMP[];

//--- global variables
int            period_sma;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtBufferADR,INDICATOR_DATA);
   SetIndexBuffer(1,ExtBufferTMP,INDICATOR_CALCULATIONS);
   
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(ExtBufferADR,true);
   ArraySetAsSeries(ExtBufferTMP,true);
   
//--- setting the period for calculating the moving average and a short name for the indicator
   period_sma=int(InpLength<2 ? 14 : InpLength);
   IndicatorSetString(INDICATOR_SHORTNAME,StringFormat("ADR(%lu)",period_sma));
   
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
   if(rates_total<period_sma)
      return 0;
      
//--- setting predefined indicator arrays as timeseries
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   
//--- checking and calculating the number of bars to be calculated
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-1;
      ArrayInitialize(ExtBufferADR,EMPTY_VALUE);
      ArrayInitialize(ExtBufferTMP,0);
     }
     
//--- calculation of price data
   for(int i=limit;i>=0;i--)
      ExtBufferTMP[i]=high[i]-low[i];
      
//--- calculation of a simple MA and return of the indicator calculation result for next call
   return(SimpleMAOnBuffer(rates_total,prev_calculated,0,period_sma,ExtBufferTMP,ExtBufferADR));
  }
//+------------------------------------------------------------------+
