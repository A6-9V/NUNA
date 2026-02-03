//+------------------------------------------------------------------+
//|                                         MAwithArrows.mq5 		   |
//|                             https://www.mql5.com/en/users/phade/|
//+------------------------------------------------------------------+

#property copyright "Copyright 2023, https://www.mql5.com/en/users/phade/"
#property link      "https://www.mql5.com/en/users/phade/"
#property version   "1.01"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1  "Buy"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrPurple
#property indicator_width1  3

#property indicator_label2  "Sell"
#property indicator_type2   DRAW_ARROW
#property indicator_color2 clrBlack
#property indicator_width2  3

#property indicator_type3   DRAW_LINE
#property indicator_color3   clrGray // change to clrNONE to hide the line
#property indicator_style3   STYLE_DOT
#property indicator_label3   "Line"
#property indicator_width3   1


double indvalue[];
double slowma[];
int handle;
int max_bars;


input int slowPeriod = 200; // Moving Average Length
input int pointNum = 130; // Amount of points on MA crossover that should enable a signal

double value_buf_a[];
double value_buf_b[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // ChartSetInteger(0, CHART_FOREGROUND, false);

    SetIndexBuffer(0, value_buf_a);
    SetIndexBuffer(1, value_buf_b);
    SetIndexBuffer(2, indvalue); 
    
    PlotIndexSetInteger(0, PLOT_ARROW, 233);   
    PlotIndexSetInteger(1, PLOT_ARROW, 234);
    
    handle = iMA(_Symbol, PERIOD_CURRENT, slowPeriod, 0, MODE_SMA, PRICE_CLOSE);

    if (handle == INVALID_HANDLE){
        Print("Get MA Handle failed!");
        return INIT_FAILED;
    }
    
    ArrayInitialize(value_buf_a, 0.0);    
    ArrayInitialize(value_buf_b, 0.0);


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
                const int &spread[]){

    if (Bars(_Symbol, _Period) < rates_total)
      return (-1);

    // Copy data from indicator buffers
    CopyBuffer(handle, 0, 0, rates_total, slowma);
    

    // Calculate the indicator values
    for (int i = prev_calculated - (rates_total==prev_calculated); i < rates_total; i++){
    
         indvalue[i] = slowma[i];
         value_buf_a[i] = 0;
         value_buf_b[i] = 0; 
         
         // Check for MA crossovers
         if (i >= 0 && (i - 2) >= 0 && close[i] > (indvalue[i] + pointNum * _Point) && close[i - 2] < indvalue[i]){
         
            value_buf_a[i] = low[i];                 
         } 
         else{
            value_buf_a[i] = 0;
         }
         
         
         if (i >= 0 && (i - 2) >= 0 && close[i] < (indvalue[i] - pointNum * _Point) && close[i - 2] > indvalue[i]){      
            value_buf_b[i] = high[i];     
         }
         else{
            value_buf_b[i] = 0; 
         }  

    }
         
    return rates_total;
}



//+------------------------------------------------------------------+

void OnDeinit(const int reason){

    ArrayFree(slowma);
    IndicatorRelease(handle);
}

