//+------------------------------------------------------------------+
//|                                         SlowMA_alerter_phade.mq5 |
//|                             https://www.mql5.com/en/users/phade/ |
//+------------------------------------------------------------------+

#property copyright "Copyright 2023, https://www.mql5.com/en/users/phade/"
#property link      "https://www.mql5.com/en/users/phade/"
#property version   "1.01"

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_type1    DRAW_LINE
#property indicator_color1   clrGray // change to clrNONE to hide the line
#property indicator_style1   STYLE_DOT
#property indicator_label1   "Line"
#property indicator_width1   1
#define OBJ_PREFIX MQLInfoString(MQL_PROGRAM_NAME)


ENUM_TIMEFRAMES prevPeriod = PERIOD_CURRENT;
input int slowPeriod = 44; // Moving Average Length
double indvalue[];
double slowma[];
int handle;
int max_bars;
double arrowDistance = 250.0; // Desired distance


input string Audio_Alert_Sound = "alert.wav"; //Audio alert sample
string audioFilePath = "\\Files\\" + Audio_Alert_Sound;
static datetime last_playsound_time = TimeCurrent();
input bool Audio_Alert_On_Signals = false; // Enable audio alerts
input int pointNum = 100; // Amount of points on MA crossover that should enable a signal
input color LongSignalColor = clrPurple;  // Set the up arrow color (long signals)
input color ShortSignalColor = clrBlack;  // Set the down arrow color (short signals)

double gLongSignal = 0.0;
double gShortSignal = 0.0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // ChartSetInteger(0, CHART_FOREGROUND, false);
    SetIndexBuffer(0, indvalue, INDICATOR_DATA);

    handle = iMA(_Symbol, PERIOD_CURRENT, slowPeriod, 0, MODE_SMA, PRICE_CLOSE);

    if (handle == INVALID_HANDLE)
    {
        Print("Get MA Handle failed!");
        return INIT_FAILED;
    }

    max_bars = Bars(Symbol(), Period());  
    
    ArrayResize(slowma, max_bars);
    ArrayResize(indvalue, max_bars);

    return INIT_SUCCEEDED;
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
    // Calculate the number of bars to copy
    int to_copy = rates_total - prev_calculated;
    if (to_copy <= 0)
        to_copy = max_bars;
        
    int limit = MathMin(rates_total - prev_calculated, rates_total);

    // Copy data from indicator buffers
    CopyBuffer(handle, 0, 0, to_copy, slowma);

    if (ChartPeriod() != prevPeriod) {
        prevPeriod = ChartPeriod(); // Store the current timeframe for comparison in the next calculation
        ChartRedraw(); // Refresh the chart to remove previous objects
    }

    if (_Period == PERIOD_M1) {
        arrowDistance = 5.0; // Change the distance for the 1-minute timeframe
    } else if (_Period == PERIOD_M2) {
        arrowDistance = 5.0; // Change the distance for the 2-minute timeframe
    } else if (_Period == PERIOD_M5) {
        arrowDistance = 20.0; // Change the distance for the 5-minute timeframe
    } else if (_Period == PERIOD_M15) {
        arrowDistance = 20.0; // Change the distance for the 15-minute timeframe
    } else if (_Period == PERIOD_M30) {
        arrowDistance = 20.0; // Change the distance for the 30-minute timeframe
    } else if (_Period == PERIOD_H1) {
        arrowDistance = 40.0; // Change the distance for the 1-hour timeframe
    } else if (_Period == PERIOD_H4) {
        arrowDistance = 40.0; // Change the distance for the 4-hour timeframe
    } else if (_Period == PERIOD_D1) {
        arrowDistance = 40.0; // Change the distance for the daily timeframe
    } else if (_Period == PERIOD_W1) {
        arrowDistance = 40.0; // Change the distance for the weekly timeframe
    } else if (_Period == PERIOD_MN1) {
        arrowDistance = 40.0; // Change the distance for the monthly timeframe
    }

    // Calculate the indicator values
    for (int i = prev_calculated - (rates_total==prev_calculated); i < limit; i++)
    {
        indvalue[i] = slowma[i];
        
     //   longSignalBuffer[i] = 0;    // Set long signal to 0
     //   shortSignalBuffer[i] = 0;   // Set short signal to 0
        
        bool noSidewaysMarket = false;
        bool significantLiquidity = false;
        
        if(i > 0){
            noSidewaysMarket = (MathAbs(close[i] - close[i-1]) > 10 * _Point);
        }
        
        if(i > 3){
            significantLiquidity = (MathAbs(close[i] - close[i-3]) > 8 * _Point);
        }
        
        bool greenCandleFormation = (close[i] > open[i]);
        bool redCandleFormation = (close[i] < open[i]);
        

        // Check for MA crossovers
        if (i > 0 && (i - 2) >= 0 && close[i] > (indvalue[i] + pointNum * _Point) && close[i - 2] < indvalue[i])
        {
            string bullArrow = OBJ_PREFIX + IntegerToString(i); // Unique name for the arrow object based on bar index
            double bullArrowPrice = low[i] - (arrowDistance * _Point);
       
            if(EntryValid(open, close, high, low, i, time, rates_total) && greenCandleFormation && noSidewaysMarket && significantLiquidity){
            
               gLongSignal = 1;
               gShortSignal = 0;

               if (Audio_Alert_On_Signals) {
                   if (last_playsound_time < time[i])
                   {
                       PlaySound(audioFilePath);
   
                       // Update last_playsound_time to the start of the current minute
                       last_playsound_time = time[i] - (time[i] % PeriodSeconds());
                   }
               }
   
               ObjectCreate(0, bullArrow, OBJ_ARROW, 0, time[i], bullArrowPrice);
               ObjectSetInteger(0, bullArrow, OBJPROP_ARROWCODE, 233);
               ObjectSetInteger(0, bullArrow, OBJPROP_BACK, false);
               ObjectSetInteger(0, bullArrow, OBJPROP_COLOR, LongSignalColor); // Set the color of the arrow
               ObjectSetInteger(0, bullArrow, OBJPROP_ANCHOR, ANCHOR_TOP); // Set the anchor point of the arrow
               ObjectSetInteger(0, bullArrow, OBJPROP_WIDTH, 2); // Set the width of the arrow
            }

        } 
        else if (i > 0 && (i - 2) >= 0 && close[i] < (indvalue[i] - pointNum * _Point) && close[i - 2] > indvalue[i])
        {
            string bearArrow = OBJ_PREFIX + IntegerToString(i); // Unique name for the arrow object based on bar index
            double bearArrowPrice = high[i] + (arrowDistance * _Point);       
            
            if(EntryValid(open, close, high, low, i, time, rates_total) && redCandleFormation && noSidewaysMarket && significantLiquidity){
                
               gLongSignal = 0;
               gShortSignal = 1;
   
               if (Audio_Alert_On_Signals) {
                   if (last_playsound_time < time[i])
                   {
                       PlaySound(audioFilePath);
   
                       // Update last_playsound_time to the start of the current minute
                       last_playsound_time = time[i] - (time[i] % PeriodSeconds());
                   }
               }
   
               ObjectCreate(0, bearArrow, OBJ_ARROW, 0, time[i], bearArrowPrice);
               ObjectSetInteger(0, bearArrow, OBJPROP_ARROWCODE, 234);
               ObjectSetInteger(0, bearArrow, OBJPROP_BACK, false);
               ObjectSetInteger(0, bearArrow, OBJPROP_COLOR, ShortSignalColor); // Set the color of the arrow
               ObjectSetInteger(0, bearArrow, OBJPROP_ANCHOR, ANCHOR_BOTTOM); // Set the anchor point of the arrow
               ObjectSetInteger(0, bearArrow, OBJPROP_WIDTH, 2); // Set the width of the arrow
            }
        }   
    }

    // Return value of prev_calculated for the next call
    return rates_total;
}



bool EntryValid(const double& open[], const double& close[], const double& high[], const double& low[], int idx, const datetime& time[], const int bars){

  double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
  bool valid = true;
  
  double liquidityCheck_a = MathAbs(close[idx-1] - close[idx-2])/pointSize; // analyze previous candle closes       
  double liquidityCheck_b = MathAbs(close[idx-3] - close[idx-4])/pointSize;  // analyze even older candle closes     
  double liquidityCheck_c = MathAbs(open[idx] - close[idx])/pointSize; // compare current candle open and close
  double liquidityCheck_d = MathAbs(high[idx] - low[idx])/pointSize; // compare current candle high and low
  double liquidityCheck_e = MathAbs(open[idx-1] - close[idx-1])/pointSize; // compare previous candle open and close
  double liquidityCheck_f = MathAbs(high[idx-1] - low[idx-1])/pointSize; // compare previous candle high and low 
  double liquidityCheck_g = MathAbs(close[idx-2] - close[idx-8])/pointSize;  // analyze even older candle closes     
   
   // remove signals on weak candles (market uncertainty)
   if(liquidityCheck_d < 25){
      valid = false;
   } 
   else if(liquidityCheck_e < 10){
      
      if(MathAbs(high[idx] - low[idx])/pointSize > 15){
         valid = true;
      }
      else{
         valid = false;
      } 
   } 
   else if(liquidityCheck_g < 10){
      valid = false;
   }

   return valid;
}



//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0, OBJ_PREFIX);
    IndicatorRelease(handle);
}


