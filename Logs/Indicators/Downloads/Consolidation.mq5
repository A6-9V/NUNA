#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_level1 0
#property indicator_level2 2
#property indicator_level3 -2

#property indicator_color1 clrBlue
#property indicator_type1  DRAW_HISTOGRAM
#property indicator_width1 2

#property indicator_color2 clrRed
#property indicator_type2  DRAW_HISTOGRAM
#property indicator_width2 2

input ENUM_TIMEFRAMES   inp_signal_time_frame      = PERIOD_M15;  // time frame
input int               inp_signal_block           = 100;         // block size in points
input int               inp_signal_block_bars      = 25;          // period max
input bool              inp_signal_break           = false;       // break signal by opposite movement

double ext_buf_up[];
double ext_buf_down[];
//+------------------------------------------------------------------+
int OnInit() {
   SetIndexBuffer(0, ext_buf_up);
   SetIndexBuffer(1, ext_buf_down);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
int OnCalculate(const int32_t rates_total,
                const int32_t prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int32_t &spread[]) {

   for(int i=MathMax(0,prev_calculated-1); i<rates_total; i++) {
      int up_blocks = 0;
      int down_blocks = 0;
      count_blocks(up_blocks, down_blocks, rates_total - i - 1, i==rates_total-2 ? true : false);
      ext_buf_up[i] = up_blocks;
      ext_buf_down[i] = -down_blocks;
   }

   return(rates_total);
}
//+------------------------------------------------------------------+
void count_blocks(int & count_up, int & count_down, int bar, bool check = false) {
   count_up    = 0;
   count_down  = 0;
   bool buy = true;
   bool sell = true;
   double start_price = iClose(NULL, inp_signal_time_frame, bar+1);
   //Print("start price: ",DoubleToString(start_price,_Digits));
   for(int i=1; i<=inp_signal_block_bars; i++) {
      int block_direction = -1;
      double bar_price = iClose(NULL, inp_signal_time_frame, bar+i);
      if(bar_price - start_price >= inp_signal_block*_Point && buy) {
         if(inp_signal_break) sell = false;
         start_price += inp_signal_block*_Point;
         count_down ++;
      }
      if(start_price - bar_price>= inp_signal_block*_Point && sell) {
         if(inp_signal_break) buy = false;
         start_price -= inp_signal_block*_Point;
         count_up ++;
      }
      if(!buy && !sell) 
         break;
   }
}
//+------------------------------------------------------------------+
