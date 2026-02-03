//+------------------------------------------------------------------+
//|                                          WH PriceDensity_MT5.mq5 |
//|                                      Copyright 2023, WH Trading. |
//|                     "https://www.mql5.com/en/users/linkt/seller" |
//+------------------------------------------------------------------+
#property copyright "WH Trading"
#property link      "https://www.mql5.com/en/users/linkt/seller"
#property version   "1.0"
#property strict

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDarkOrange
#property indicator_level1 5
#property indicator_levelwidth 1
#property indicator_levelstyle STYLE_DOT

//Input parameters
input int    InpPeriods                = 20;       //Indicator Periods
input double InpNoiseThresholdLevel    = 5.0;      //Price Density Noise Threshold Level
input color  InpLineColor              = clrBlack; //Threshold Level Color 

//Indicator Buffers
double PriceDensityBuffer[];
double SumHighsLowsBuffer[];
double HighestHighBuffer[];
double LowestLowBuffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, PriceDensityBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, SumHighsLowsBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, HighestHighBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, LowestLowBuffer, INDICATOR_CALCULATIONS);

   IndicatorSetInteger(INDICATOR_DIGITS, 5);
   IndicatorSetString(INDICATOR_SHORTNAME, "Price Density - Market Noise Index (" + IntegerToString(InpPeriods) + ")");
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpPeriods);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, InpNoiseThresholdLevel);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, InpLineColor);
   IndicatorSetString(INDICATOR_LEVELTEXT, 0, "Threshold Level");

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
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


//if the rates_total is less than the period return
   if(rates_total <= InpPeriods)
      return(0);

   int currentPosition = prev_calculated - 1;

   if(currentPosition < InpPeriods)
      currentPosition = InpPeriods;



//Loop from the current position to rates_total
   for(int i = currentPosition; i < rates_total && !IsStopped(); i++)
     {
      if(rates_total != prev_calculated)
        {
         SumHighsLowsBuffer[i] = 0;
         HighestHighBuffer[i] = DBL_MIN;
         LowestLowBuffer[i] = DBL_MAX;

         //Loop to get the highest index and the lowest.
         for(int j = i - 1; j > i - InpPeriods; j--)
           {
            SumHighsLowsBuffer[i] += high[j] - low[j];

            if(high[j] > HighestHighBuffer[i])
               HighestHighBuffer[i] = high[j];

            if(low[j] < LowestLowBuffer[i])
               LowestLowBuffer[i] = low[j];
           }
        }

      //get the highest value and the lowest value.
      double highestHigh = MathMax(HighestHighBuffer[i], high[i]);
      double lowestLow = MathMin(LowestLowBuffer[i], low[i]);


      //Price density formula
      if(highestHigh - lowestLow != 0)
         PriceDensityBuffer[i] = (SumHighsLowsBuffer[i] + (high[i] - low[i])) / (highestHigh - lowestLow);
      else
         PriceDensityBuffer[i] = 0.0;
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
