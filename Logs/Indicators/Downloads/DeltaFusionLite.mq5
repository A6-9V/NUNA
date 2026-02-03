//+------------------------------------------------------------------+
//|                                              DeltaFusionLite.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com/en/users/francescosecchi"
#property version   "1.0"
#property description "DeltaFusion Lite - Cumulative Delta & Net Delta"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3
#property indicator_level1  0.0
#define EPSILON 1e-12
#define DEFAULT_MIN_TICK 0.00001
#define DEFAULT_TF_SECONDS 60
#define COLOR_CUM_ASK clrGreen
#define COLOR_CUM_BID clrRed
#define COLOR_NET_DELTA clrBlack
double CumAsk[];
double CumBid[];
double NetDelta[];
input string ResetSession = "=== Session Reset ==="; // Section header label used to group session reset inputs
input int    ResetHourCustom = 1; // Hour of daily session reset (0-23)
input int    ResetMinuteCustom = 0; // Minute of daily session reset (0-59)
input string CumulativeDelta = "=== Cumulative Delta ==="; // Section header label used to group cumulative delta inputs
input int    SmoothPeriod = 10; // EMA smoothing period for delta (>=1)
datetime g_lastSession = 0;
bool g_firstRun = true;
double Eps() { return EPSILON; }
double SafeDiv(double numerator, double denominator)
{
   if(MathAbs(denominator) <= Eps())
   {
      return (numerator > Eps()) ? 1e9 : 0.0;
   }
   double result = numerator / denominator;
   if(!MathIsValidNumber(result)) return 0.0;
   return result;
}
double SafeNormalize(double price)
{
   return NormalizeDouble(price, _Digits);
}
int GetTFSeconds()
{
   int sec = PeriodSeconds();
   return (sec <= 0) ? DEFAULT_TF_SECONDS : sec;
}
double GetMinTick()
{
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   return (tick <= 0.0) ? DEFAULT_MIN_TICK : tick;
}
datetime GetSessionStart()
{
   int mm = (ResetMinuteCustom < 0) ? 0 : ((ResetMinuteCustom > 59) ? 59 : ResetMinuteCustom);
   datetime now = TimeCurrent();
   MqlDateTime md;
   TimeToStruct(now, md);
   md.hour = ResetHourCustom;
   md.min = mm;
   md.sec = 0;
   datetime sessionToday = StructToTime(md);
   if(now < sessionToday)
   {
      sessionToday -= 24 * 60 * 60;
   }
   return sessionToday;
}
bool IsNewSession()
{
   datetime currentSession = GetSessionStart();
   if(currentSession != g_lastSession)
   {
      g_lastSession = currentSession;
      return true;
   }
   return false;
}
void SmoothEMA(const double &src[], int count, int period, double &emaOut[])
{
   if(ArraySize(emaOut) != count)
   {
      ArrayResize(emaOut, count);
      ArraySetAsSeries(emaOut, true);
   }
   if(count <= 0) return;
   if(period <= 1)
   {
      ArrayCopy(emaOut, src, 0, 0, WHOLE_ARRAY);
      return;
   }
   double alpha = 2.0 / (period + 1.0);
   double prev = src[count - 1];
   emaOut[count - 1] = prev;
   for(int i = count - 2; i >= 0; i--)
   {
      prev = alpha * src[i] + (1.0 - alpha) * prev;
      emaOut[i] = prev;
   }
}
void GetTickDeltaAskBid(int i,
                        const double &open[],
                        const double &high[],
                        const double &low[],
                        const double &close[],
                        const long &tick_volume[],
                        double &deltaAsk,
                        double &deltaBid)
{
   deltaAsk = 0.0;
   deltaBid = 0.0;
   if(i < 0) return;
   double o = open[i];
   double c = close[i];
   double h = high[i];
   double l = low[i];
   long tv = tick_volume[i];
   double vol = (tv > 0) ? (double)tv : 1.0;
   double spread = h - l;
   if(spread <= 0.0) return;
   double upper = MathMax(h - MathMax(o, c), 0.0);
   double lower = MathMax(MathMin(o, c) - l, 0.0);
   double body = spread - (upper + lower);
   double pu = upper / spread;
   double pl = lower / spread;
   double pb = body / spread;
   if(c > o)
   {
      deltaAsk = (pb + (pu + pl) / 2.0) * vol;
      deltaBid = ((pu + pl) / 2.0) * vol;
   }
   else if(c < o)
   {
      deltaBid = (pb + (pu + pl) / 2.0) * vol;
      deltaAsk = ((pu + pl) / 2.0) * vol;
   }
   else
   {
      deltaAsk = deltaBid = ((pu + pl) / 2.0) * vol;
   }
}
int OnInit()
{
   SetIndexBuffer(0, CumAsk, INDICATOR_DATA);
   SetIndexBuffer(1, CumBid, INDICATOR_DATA);
   SetIndexBuffer(2, NetDelta, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_HISTOGRAM);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 2);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, COLOR_CUM_ASK);
   PlotIndexSetString(0, PLOT_LABEL, "Ask Volume");
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_HISTOGRAM);
   PlotIndexSetInteger(1, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 2);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, COLOR_CUM_BID);
   PlotIndexSetString(1, PLOT_LABEL, "Bid Volume");
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(2, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, COLOR_NET_DELTA);
   PlotIndexSetString(2, PLOT_LABEL, "Net Delta");
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   ArraySetAsSeries(CumAsk, true);
   ArraySetAsSeries(CumBid, true);
   ArraySetAsSeries(NetDelta, true);
   IndicatorSetString(INDICATOR_SHORTNAME, "DeltaFusion Lite v1.0");
   IndicatorSetInteger(INDICATOR_LEVELS, 1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 0.0);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE, 0, STYLE_DASH);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrGray);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH, 0, 1);
   Print("DeltaFusion Lite initialized successfully");
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason)
{
   string reason_text;
   switch(reason)
   {
      case REASON_PROGRAM:     reason_text = "Program terminated"; break;
      case REASON_REMOVE:      reason_text = "Indicator removed"; break;
      case REASON_RECOMPILE:   reason_text = "Recompiled"; break;
      case REASON_CHARTCHANGE: reason_text = "Chart changed"; break;
      case REASON_CHARTCLOSE:  reason_text = "Chart closed"; break;
      case REASON_PARAMETERS:  reason_text = "Parameters changed"; break;
      case REASON_ACCOUNT:     reason_text = "Account changed"; break;
      default: reason_text = "Unknown reason"; break;
   }
   Print("Indicator deinitialized: ", reason_text);
}
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
   if(rates_total <= 0) return 0;
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(tick_volume, true);
   int start;
   if(prev_calculated == 0 || g_firstRun)
   {
      start = rates_total - 1;
      g_firstRun = false;
   }
   else
   {
      start = rates_total - prev_calculated;
      if(start > 0) start--;
   }
   if(start < 0) start = 0;
   if(start >= rates_total) start = rates_total - 1;
   static double dA[];
   static double dB[];
   if(ArraySize(dA) != rates_total)
   {
      ArrayResize(dA, rates_total);
      ArraySetAsSeries(dA, true);
   }
   if(ArraySize(dB) != rates_total)
   {
      ArrayResize(dB, rates_total);
      ArraySetAsSeries(dB, true);
   }
   for(int i = start; i >= 0; i--)
   {
      GetTickDeltaAskBid(i, open, high, low, close, tick_volume, dA[i], dB[i]);
   }
   static double emaA[];
   static double emaB[];
   SmoothEMA(dA, rates_total, SmoothPeriod, emaA);
   SmoothEMA(dB, rates_total, SmoothPeriod, emaB);
   for(int i2 = start; i2 >= 0; i2--)
   {
      CumAsk[i2] = (emaA[i2] > 0.0) ? emaA[i2] : EMPTY_VALUE;
      CumBid[i2] = (emaB[i2] > 0.0) ? -emaB[i2] : EMPTY_VALUE;
      NetDelta[i2] = emaA[i2] - emaB[i2];
   }
   datetime sessionStart = GetSessionStart();
   double sumAsk = 0.0, sumBid = 0.0;
   int firstIdx = -1, lastIdx = -1;
   for(int i3 = 0; i3 < rates_total; i3++)
   {
      if(time[i3] < sessionStart) break;
      if(firstIdx < 0) firstIdx = i3;
      lastIdx = i3;
      if(CumAsk[i3] != EMPTY_VALUE) sumAsk += MathAbs(CumAsk[i3]);
      if(CumBid[i3] != EMPTY_VALUE) sumBid += MathAbs(CumBid[i3]);
   }
   return rates_total;
}
