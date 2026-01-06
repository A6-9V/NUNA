//+------------------------------------------------------------------+
//|                                               RSI_MA_Signal.mq5  |
//|               Portfolio Sample for Kemran Feitulov               |
//|                    https://www.mql5.com/en/users/x45_e127h263570 |
//+------------------------------------------------------------------+
#property copyright "Kemran Feitulov"
#property link      "https://www.mql5.com/en/users/x45_e127h263570"
#property version   "1.00"

//--- Draw on the main chart window
#property indicator_chart_window
//--- We have 2 signal buffers
#property indicator_buffers 2
#property indicator_plots   2

//--- Plot 1: Buy Signal (Arrow Up)
#property indicator_label1  "Buy_Signal"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- Plot 2: Sell Signal (Arrow Down)
#property indicator_label2  "Sell_Signal"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- Input parameters for the indicator
input int RSI_Period = 14;           // RSI Period
input int MA_Period = 20;            // Moving Average Period
input ENUM_MA_METHOD MA_Method = MODE_SMA; // MA Method
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE; // MA Applied Price

//--- Indicator buffers
double BuyBuffer[];
double SellBuffer[];

//--- Indicator handles
int h_rsi;
int h_ma;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Set up the Buy buffer
   SetIndexBuffer(0, BuyBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0); // Don't draw zero values
   PlotIndexSetInteger(0, PLOT_ARROW, 233); // Set Wingdings Up Arrow

//--- Set up the Sell buffer
   SetIndexBuffer(1, SellBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0); // Don't draw zero values
   PlotIndexSetInteger(1, PLOT_ARROW, 234); // Set Wingdings Down Arrow

//--- Get indicator handles
   h_rsi = iRSI(_Symbol, _Period, RSI_Period, PRICE_CLOSE);
   h_ma = iMA(_Symbol, _Period, MA_Period, 0, MA_Method, MA_Price);
   
   if(h_rsi == INVALID_HANDLE || h_ma == INVALID_HANDLE)
     {
      Print("Error getting indicator handles in OnInit()");
      return(INIT_FAILED);
     }
//---
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
//--- Check if we have enough bars to calculate
   if(rates_total < MathMax(RSI_Period, MA_Period))
      return(0);
      
//--- Define arrays to hold indicator data
   double rsi_buffer[];
   double ma_buffer[];

//--- Define the starting bar for calculation
   int start = (prev_calculated > 1) ? prev_calculated - 1 : 1;

//--- Copy data from indicators
   if(CopyBuffer(h_rsi, 0, 0, rates_total, rsi_buffer) < rates_total)
     {
      Print("Error copying RSI buffer");
      return(0);
     }
   if(CopyBuffer(h_ma, 0, 0, rates_total, ma_buffer) < rates_total)
     {
      Print("Error copying MA buffer");
      return(0);
     }

//--- Main calculation loop
   for(int i = start; i < rates_total; i++)
     {
      //--- Default to no signal
      BuyBuffer[i] = 0.0;
      SellBuffer[i] = 0.0;
      
      //--- Get indicator values for the current bar
      double rsi_value = rsi_buffer[i];
      double ma_value = ma_buffer[i];
      double close_price = close[i];
      
      //--- Check Buy Signal Logic
      if(rsi_value > 50 && close_price > ma_value)
        {
         // Place arrow slightly above the high
         BuyBuffer[i] = high[i] + 10 * _Point;
        }
      //--- Check Sell Signal Logic
      else if(rsi_value < 50 && close_price < ma_value)
        {
         // Place arrow slightly below the low
         SellBuffer[i] = low[i] - 10 * _Point;
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+