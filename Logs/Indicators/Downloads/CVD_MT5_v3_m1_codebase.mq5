//+------------------------------------------------------------------+
//|                                           CVD_MT5_v3_m1_version |
//|                      Copyright 2025, Salman Soltaniyan          |
//|           https://www.mql5.com/en/users/salmansoltaniyan/       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Salman Soltaniyan"
#property link      "https://www.mql5.com/en/users/salmansoltaniyan/"
#property description "For any freelance job: https://www.mql5.com/en/job/new?prefered=salmansoltaniyan"
#property version   "1.00"

/*
 MIT License

 Copyright (c) 2025 Salman Soltaniyan

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1

// CVD Candle Plot
#property indicator_label1  "CVD"
#property indicator_type1   DRAW_CANDLES
#property indicator_color1  clrGreen,clrWhite,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- Input Parameters
input ENUM_TIMEFRAMES InpResetPeriod = PERIOD_H1;  // CVD Reset Period
input bool            InpNoReset = false;          // CVD No Reset

//--- Indicator Buffers
double CVD_Open[];
double CVD_High[];
double CVD_Low[];
double CVD_Close[];

//--- Global Variables
datetime g_LastM1Time = 0;
double   g_CumulativeDelta = 0.0;
int      g_PreviousChartBarIndex = -1;
datetime g_candle=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
// Set indicator buffers (ArraySetAsSeries = false)
   SetIndexBuffer(0, CVD_Open, INDICATOR_DATA);
   SetIndexBuffer(1, CVD_High, INDICATOR_DATA);
   SetIndexBuffer(2, CVD_Low, INDICATOR_DATA);
   SetIndexBuffer(3, CVD_Close, INDICATOR_DATA);

// Set buffer names for data window
   PlotIndexSetString(0, PLOT_LABEL, "CVD Open; CVD High; CVD Low; CVD Close");

   ArraySetAsSeries(CVD_Open, false);
   ArraySetAsSeries(CVD_High, false);
   ArraySetAsSeries(CVD_Low, false);
   ArraySetAsSeries(CVD_Close, false);

// Set indicator properties
   string shortname = InpNoReset ? "CVD (No Reset)" : "CVD (" + EnumToString(InpResetPeriod) + ")";
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
   IndicatorSetInteger(INDICATOR_DIGITS, 0);

   string resetInfo = InpNoReset ? "No Reset" : EnumToString(InpResetPeriod);
   Print("CVD MT5 Initialized - Reset Mode: ", resetInfo);

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
// Explicitly set time array as series flag to false
   ArraySetAsSeries(time, false);

   if(g_candle!=iTime(_Symbol,PERIOD_M1, 0))
     {


      // Don't loop over candles, use CopyRates approach
      ProcessM1Data(rates_total, prev_calculated, time);
      g_candle= iTime(_Symbol,PERIOD_M1, 0);
     }

   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Process M1 data and calculate CVD for chart timeframe           |
//+------------------------------------------------------------------+
void ProcessM1Data(int rates_total, int prev_calculated, const datetime &time[])
  {
// Get M1 data using CopyRates
   MqlRates m1_rates[];

   datetime start_time = (prev_calculated > 0) ? g_LastM1Time : time[0];
   datetime end_time = TimeCurrent();

   int m1_count = CopyRates(Symbol(), PERIOD_M1, start_time, end_time, m1_rates);

   if(m1_count <= 0)
     {
      Print("Failed to copy M1 rates");
      return;
     }
   else
     {
      Print("copied m1 candles= ", m1_count);
     }

   ArraySetAsSeries(m1_rates, false);

// Process each M1 candle and update CVD for chart bars
   for(int i = 0; i < m1_count; i++)
     {
      // Calculate volume delta for this M1 candle
      double volumeDelta = CalculateM1VolumeDelta(m1_rates[i]);

      // Check if we need to reset CVD (new reset period started) - only if reset is enabled
      if(!InpNoReset && IsNewResetPeriod(m1_rates[i].time))
        {
         g_CumulativeDelta = 0.0;
        }

      // Update cumulative delta
      double prevCVD = g_CumulativeDelta;
      g_CumulativeDelta += volumeDelta;

      // Find corresponding chart bar and update CVD
      int chart_bar_shift = iBarShift(Symbol(), Period(), m1_rates[i].time);
      if(chart_bar_shift >= 0 && chart_bar_shift < rates_total)
        {
         // Convert iBarShift result to correct array index (since buffers are not as series)
         int chart_bar_index = rates_total - 1 - chart_bar_shift;
         UpdateCVDCandle(chart_bar_index, prevCVD, g_CumulativeDelta);
        }

      g_LastM1Time = m1_rates[i].time;
     }
  }

//+------------------------------------------------------------------+
//| Calculate Volume Delta for a single M1 bar                      |
//+------------------------------------------------------------------+
double CalculateM1VolumeDelta(const MqlRates &m1_bar)
  {
// Simple volume delta calculation based on M1 candle direction
   double candle_body = m1_bar.close - m1_bar.open;
   double volume = (double)m1_bar.tick_volume;

   if(candle_body > 0)
      return volume;   // Bullish M1 candle - positive delta
   else
      if(candle_body < 0)
         return -volume;  // Bearish M1 candle - negative delta
      else
         return 0.0;      // Doji - neutral delta
  }

//+------------------------------------------------------------------+
//| Update CVD candle values for chart bar                          |
//+------------------------------------------------------------------+
void UpdateCVDCandle(int bar_index, double prev_cvd, double current_cvd)
  {
// Check if this is a new candle by comparing with previous bar index
   bool is_new_candle = (bar_index != g_PreviousChartBarIndex);

// Initialize if this is a new candle
   if(is_new_candle)
     {
      CVD_Open[bar_index] = prev_cvd;
      CVD_High[bar_index] = MathMax(prev_cvd, current_cvd);
      CVD_Low[bar_index] = MathMin(prev_cvd, current_cvd);
      g_PreviousChartBarIndex = bar_index;
     }
   else
     {
      // Update high and low for existing candle
      CVD_High[bar_index] = MathMax(CVD_High[bar_index], current_cvd);
      CVD_Low[bar_index] = MathMin(CVD_Low[bar_index], current_cvd);
     }

// Always update close to current CVD (for both new and existing candles)
   CVD_Close[bar_index] = current_cvd;
  }

//+------------------------------------------------------------------+
//| Check if new reset period started                               |
//+------------------------------------------------------------------+
bool IsNewResetPeriod(datetime current_time)
  {
   if(g_LastM1Time == 0)
      return true;

// Get period start times
   datetime current_period_start = GetPeriodStart(current_time, InpResetPeriod);
   datetime last_period_start = GetPeriodStart(g_LastM1Time, InpResetPeriod);

   return (current_period_start != last_period_start);
  }

//+------------------------------------------------------------------+
//| Get period start time based on timeframe                        |
//+------------------------------------------------------------------+
datetime GetPeriodStart(datetime time, ENUM_TIMEFRAMES timeframe)
  {
   MqlDateTime dt;
   TimeToStruct(time, dt);

   switch(timeframe)
     {
      case PERIOD_M1:
         dt.sec = 0;
         break;
      case PERIOD_M5:
         dt.min = (dt.min / 5) * 5;
         dt.sec = 0;
         break;
      case PERIOD_M15:
         dt.min = (dt.min / 15) * 15;
         dt.sec = 0;
         break;
      case PERIOD_M30:
         dt.min = (dt.min / 30) * 30;
         dt.sec = 0;
         break;
      case PERIOD_H1:
         dt.min = 0;
         dt.sec = 0;
         break;
      case PERIOD_H4:
         dt.hour = (dt.hour / 4) * 4;
         dt.min = 0;
         dt.sec = 0;
         break;
      case PERIOD_D1:
         dt.hour = 0;
         dt.min = 0;
         dt.sec = 0;
         break;
      case PERIOD_W1:
         dt.day_of_week = 1; // Monday
         dt.hour = 0;
         dt.min = 0;
         dt.sec = 0;
         break;
      case PERIOD_MN1:
         dt.day = 1;
         dt.hour = 0;
         dt.min = 0;
         dt.sec = 0;
         break;
      default:
         break;
     }

   return StructToTime(dt);
  }

//+------------------------------------------------------------------+
//| Indicator deinitialization function                             |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("CVD MT5 Deinitialized");
  }
//+------------------------------------------------------------------+
