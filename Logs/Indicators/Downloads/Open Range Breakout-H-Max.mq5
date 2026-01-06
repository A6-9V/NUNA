//+------------------------------------------------------------------+
//|                                    Open Range Breakout-H-Max.mq5 |
//|                By Hieronymos Starch - Quotesy of The Nevek Ratio |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Hieronymos Starch - arete2077@gmail.com  - +263785974079 "
#property link      "https://www.mql5.com"
#property version   "9.00"
#property indicator_chart_window

#property indicator_buffers 22
#property indicator_plots   22

// Plot buffers
#property indicator_label1  "ORB High"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "ORB Low"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#property indicator_label3  "ORB Mid Point"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGray
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "ORB High PT 0.5"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrPurple
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

#property indicator_label5  "ORB High PT 1.0"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrBlue
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2

#property indicator_label6  "ORB Low PT 0.5"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrPurple
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2

#property indicator_label7  "ORB Low PT 1.0"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrBlue
#property indicator_style7  STYLE_SOLID
#property indicator_width7  2

// Extended targets
#property indicator_label8  "ORB High PT 1.5"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrTeal

#property indicator_label9  "ORB High PT 2.0"
#property indicator_type9   DRAW_LINE
#property indicator_color9  clrTeal

#property indicator_label10 "ORB High PT 2.5"
#property indicator_type10  DRAW_LINE
#property indicator_color10 clrTeal

#property indicator_label11 "ORB High PT 3.0"
#property indicator_type11  DRAW_LINE
#property indicator_color11 clrTeal

#property indicator_label12 "ORB High PT 3.5"
#property indicator_type12  DRAW_LINE
#property indicator_color12 clrTeal

#property indicator_label13 "ORB High PT 4.0"
#property indicator_type13  DRAW_LINE
#property indicator_color13 clrTeal

#property indicator_label14 "ORB High PT 4.5"
#property indicator_type14  DRAW_LINE
#property indicator_color14 clrTeal

#property indicator_label15 "ORB High PT 5.0"
#property indicator_type15  DRAW_LINE
#property indicator_color15 clrTeal

#property indicator_label16 "ORB Low PT 1.5"
#property indicator_type16  DRAW_LINE
#property indicator_color16 clrTeal

#property indicator_label17 "ORB Low PT 2.0"
#property indicator_type17  DRAW_LINE
#property indicator_color17 clrTeal

#property indicator_label18 "ORB Low PT 2.5"
#property indicator_type18  DRAW_LINE
#property indicator_color18 clrTeal

#property indicator_label19 "ORB Low PT 3.0"
#property indicator_type19  DRAW_LINE
#property indicator_color19 clrTeal

#property indicator_label20 "ORB Low PT 3.5"
#property indicator_type20  DRAW_LINE
#property indicator_color20 clrTeal

#property indicator_label21 "ORB Low PT 4.0"
#property indicator_type21  DRAW_LINE
#property indicator_color21 clrTeal

#property indicator_label22 "ORB Low PT 4.5"
#property indicator_type22  DRAW_LINE
#property indicator_color22 clrTeal

// Input parameters
input string    sOpeningRangeMinutes = "15";     // Period (minutes): 5,15,30,0
input bool      alertBreakoutsOnly = false;      // Alert only on ORB breakouts (not price ticks)
input bool      showLabels = true;               // Show ORB labels
input bool      showPreviousDayORBs = true;      // Show ORB ranges on previous days
input bool      showEntries = true;              // Show potential ORB Breakouts and Retests (BRB)
input bool      showPriceTargets = true;         // Show Default Price Targets (50%, 100%)
input bool      showPriceTargetsExtended = false; // Show Extended Price Targets (150%, 200%)
input bool      showMidPoint = false;            // Show ORB Mid Point
input bool      showShadedBox = true;            // Shade the ORB Range
input color     shadeColor = clrTeal;            // Shaded ORB Range Color
input color     orb50Color = clrPurple;          // ORB 50 Price Target
input color     orb100Color = clrBlue;           // ORB 100 Price Target
input color     orbOtherColor = clrTeal;         // All Other ORB Price Targets
input string    sORBStartTime = "0930-0945";     // Time Override (Format: 0930-0945)
input string    sTimeZone = "EST";               // Timezone
input int       labelOffsetBars = 5;             // Label Horizontal Offset (bars)
input int       labelOffsetPips = 0;             // Label Vertical Offset (pips)
input int       labelFontSize = 8;               // Label Font Size
input ENUM_ANCHOR_POINT labelAnchor = ANCHOR_LEFT; // Label Anchor Point
input int       maxLineBars = 500;               // Maximum Line Length (bars)

// Indicator buffers
double OrbHighBuffer[];
double OrbLowBuffer[];
double OrbMidBuffer[];
double OrbHigh50Buffer[];
double OrbHigh100Buffer[];
double OrbLow50Buffer[];
double OrbLow100Buffer[];
double OrbHigh150Buffer[];
double OrbHigh200Buffer[];
double OrbHigh250Buffer[];
double OrbHigh300Buffer[];
double OrbHigh350Buffer[];
double OrbHigh400Buffer[];
double OrbHigh450Buffer[];
double OrbHigh500Buffer[];
double OrbLow150Buffer[];
double OrbLow200Buffer[];
double OrbLow250Buffer[];
double OrbLow300Buffer[];
double OrbLow350Buffer[];
double OrbLow400Buffer[];
double OrbLow450Buffer[];

// Global variables
struct ORBData {
    double orbHighPrice;
    double orbLowPrice;
    datetime orbStartTime;
    datetime orbEndTime;
    bool isActive;
    string boxName;
    int dayOfYear;
    int sessionStartBar;
    int sessionEndBar;
};

ORBData currentORB;
bool inBreakout = false;
int openingRangeMinutes;
int sessionStartHour, sessionStartMin;
int sessionEndHour, sessionEndMin;
string orbTitle;
double pointMultiplier;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    openingRangeMinutes = (int)StringToInteger(sOpeningRangeMinutes);
    pointMultiplier = (_Point * 10);
    
    // Determine session times
    if(openingRangeMinutes == 5)
    {
        sessionStartHour = 9; sessionStartMin = 30;
        sessionEndHour = 9; sessionEndMin = 35;
    }
    else if(openingRangeMinutes == 15)
    {
        sessionStartHour = 9; sessionStartMin = 30;
        sessionEndHour = 9; sessionEndMin = 45;
    }
    else if(openingRangeMinutes == 30)
    {
        sessionStartHour = 9; sessionStartMin = 30;
        sessionEndHour = 10; sessionEndMin = 0;
    }
    else if(openingRangeMinutes == 0)
    {
        string parts[];
        if(StringSplit(sORBStartTime, '-', parts) == 2)
        {
            string startTime = parts[0];
            string endTime = parts[1];
            
            sessionStartHour = (int)StringToInteger(StringSubstr(startTime, 0, 2));
            sessionStartMin = (int)StringToInteger(StringSubstr(startTime, 2, 2));
            sessionEndHour = (int)StringToInteger(StringSubstr(endTime, 0, 2));
            sessionEndMin = (int)StringToInteger(StringSubstr(endTime, 2, 2));
        }
    }
    else
    {
        sessionStartHour = 9; sessionStartMin = 30;
        sessionEndHour = 9; sessionEndMin = 45;
    }
    
    orbTitle = "ORB" + IntegerToString(openingRangeMinutes);
    
    // Initialize ORB data
    currentORB.orbHighPrice = 0.0;
    currentORB.orbLowPrice = 0.0;
    currentORB.isActive = false;
    currentORB.boxName = "";
    currentORB.dayOfYear = 0;
    currentORB.sessionStartBar = -1;
    currentORB.sessionEndBar = -1;
    
    // Set indicator buffers
    SetIndexBuffer(0, OrbHighBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, OrbLowBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, OrbMidBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, OrbHigh50Buffer, INDICATOR_DATA);
    SetIndexBuffer(4, OrbHigh100Buffer, INDICATOR_DATA);
    SetIndexBuffer(5, OrbLow50Buffer, INDICATOR_DATA);
    SetIndexBuffer(6, OrbLow100Buffer, INDICATOR_DATA);
    SetIndexBuffer(7, OrbHigh150Buffer, INDICATOR_DATA);
    SetIndexBuffer(8, OrbHigh200Buffer, INDICATOR_DATA);
    SetIndexBuffer(9, OrbHigh250Buffer, INDICATOR_DATA);
    SetIndexBuffer(10, OrbHigh300Buffer, INDICATOR_DATA);
    SetIndexBuffer(11, OrbHigh350Buffer, INDICATOR_DATA);
    SetIndexBuffer(12, OrbHigh400Buffer, INDICATOR_DATA);
    SetIndexBuffer(13, OrbHigh450Buffer, INDICATOR_DATA);
    SetIndexBuffer(14, OrbHigh500Buffer, INDICATOR_DATA);
    SetIndexBuffer(15, OrbLow150Buffer, INDICATOR_DATA);
    SetIndexBuffer(16, OrbLow200Buffer, INDICATOR_DATA);
    SetIndexBuffer(17, OrbLow250Buffer, INDICATOR_DATA);
    SetIndexBuffer(18, OrbLow300Buffer, INDICATOR_DATA);
    SetIndexBuffer(19, OrbLow350Buffer, INDICATOR_DATA);
    SetIndexBuffer(20, OrbLow400Buffer, INDICATOR_DATA);
    SetIndexBuffer(21, OrbLow450Buffer, INDICATOR_DATA);
    
    // Set colors
    PlotIndexSetInteger(3, PLOT_LINE_COLOR, orb50Color);
    PlotIndexSetInteger(4, PLOT_LINE_COLOR, orb100Color);
    PlotIndexSetInteger(5, PLOT_LINE_COLOR, orb50Color);
    PlotIndexSetInteger(6, PLOT_LINE_COLOR, orb100Color);
    
    for(int i = 7; i < 22; i++)
        PlotIndexSetInteger(i, PLOT_LINE_COLOR, orbOtherColor);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0, "ORB_");
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
    if(rates_total < 10) return(0);
    
    int start = MathMax(1, prev_calculated);
    if(start == 1) start = 0;
    
    for(int i = start; i < rates_total; i++)
    {
        InitializeBuffers(i);
        
        MqlDateTime dt;
        TimeToStruct(time[i], dt);
        
        bool inSession = IsInSession(dt);
        bool isFirstBar = IsFirstBarOfSession(time, i, dt);
        bool newDayStart = IsNewDay(time, i);
        bool isToday = IsToday(time[i]);
        bool drawOrbs = showPreviousDayORBs || (!showPreviousDayORBs && isToday);
        
        // Start new ORB session
        if(isFirstBar && inSession)
        {
            currentORB.orbHighPrice = high[i];
            currentORB.orbLowPrice = low[i];
            currentORB.orbStartTime = time[i];
            currentORB.sessionStartBar = i;
            currentORB.isActive = true;
            currentORB.dayOfYear = dt.day_of_year;
            inBreakout = false;
            
            // Calculate session end time
            MqlDateTime sessionEnd = dt;
            sessionEnd.hour = sessionEndHour;
            sessionEnd.min = sessionEndMin;
            currentORB.orbEndTime = StructToTime(sessionEnd);
            
            currentORB.boxName = "ORB_Box_" + IntegerToString(dt.day_of_year);
        }
        
        // Update ORB levels during session
        if(inSession && currentORB.isActive)
        {
            if(high[i] > currentORB.orbHighPrice) 
                currentORB.orbHighPrice = high[i];
            if(low[i] < currentORB.orbLowPrice) 
                currentORB.orbLowPrice = low[i];
        }
        
        // Mark end of session
        if(!inSession && currentORB.isActive && i > 0)
        {
            MqlDateTime prevDt;
            TimeToStruct(time[i-1], prevDt);
            if(IsInSession(prevDt))
            {
                currentORB.sessionEndBar = i - 1;
                currentORB.isActive = false;
                
                // Draw the rectangle now that session is complete
                if(showShadedBox)
                    DrawORBRectangle();
            }
        }
        
        // Plot ORB levels and targets
        if(currentORB.orbHighPrice > 0 && currentORB.orbLowPrice > 0)
        {
            bool shouldPlot = false;
            
            if(!inSession && drawOrbs)
            {
                // Limit line length
                int barsFromSessionEnd = (currentORB.sessionEndBar > 0) ? i - currentORB.sessionEndBar : 0;
                if(barsFromSessionEnd <= maxLineBars)
                    shouldPlot = true;
            }
            
            if(shouldPlot)
            {
                double orbRange = currentORB.orbHighPrice - currentORB.orbLowPrice;
                
                // Always show ORB High and Low
                OrbHighBuffer[i] = currentORB.orbHighPrice;
                OrbLowBuffer[i] = currentORB.orbLowPrice;
                
                if(showMidPoint && showPriceTargets)
                    OrbMidBuffer[i] = currentORB.orbLowPrice + (orbRange * 0.5);
                
                if(showPriceTargets)
                    PlotPriceTargets(i, orbRange);
                
                // Draw labels only for today and only once
                if(isToday && showLabels && i == rates_total - 1)
                    DrawPriceTargetLabels(time[i], orbRange);
            }
        }
        
        // Handle breakout detection
        if(!inSession && i > 2 && currentORB.orbHighPrice > 0)
            ProcessBreakouts(time, high, low, close, i, isToday);
    }
    
    return(rates_total);
}

//+------------------------------------------------------------------+
//| Initialize all buffers to EMPTY_VALUE                           |
//+------------------------------------------------------------------+
void InitializeBuffers(int index)
{
    OrbHighBuffer[index] = EMPTY_VALUE;
    OrbLowBuffer[index] = EMPTY_VALUE;
    OrbMidBuffer[index] = EMPTY_VALUE;
    OrbHigh50Buffer[index] = EMPTY_VALUE;
    OrbHigh100Buffer[index] = EMPTY_VALUE;
    OrbLow50Buffer[index] = EMPTY_VALUE;
    OrbLow100Buffer[index] = EMPTY_VALUE;
    OrbHigh150Buffer[index] = EMPTY_VALUE;
    OrbHigh200Buffer[index] = EMPTY_VALUE;
    OrbHigh250Buffer[index] = EMPTY_VALUE;
    OrbHigh300Buffer[index] = EMPTY_VALUE;
    OrbHigh350Buffer[index] = EMPTY_VALUE;
    OrbHigh400Buffer[index] = EMPTY_VALUE;
    OrbHigh450Buffer[index] = EMPTY_VALUE;
    OrbHigh500Buffer[index] = EMPTY_VALUE;
    OrbLow150Buffer[index] = EMPTY_VALUE;
    OrbLow200Buffer[index] = EMPTY_VALUE;
    OrbLow250Buffer[index] = EMPTY_VALUE;
    OrbLow300Buffer[index] = EMPTY_VALUE;
    OrbLow350Buffer[index] = EMPTY_VALUE;
    OrbLow400Buffer[index] = EMPTY_VALUE;
    OrbLow450Buffer[index] = EMPTY_VALUE;
}

//+------------------------------------------------------------------+
//| Plot price targets                                               |
//+------------------------------------------------------------------+
void PlotPriceTargets(int index, double orbRange)
{
    OrbHigh50Buffer[index] = currentORB.orbHighPrice + (orbRange * 0.5);
    OrbHigh100Buffer[index] = currentORB.orbHighPrice + (orbRange * 1.0);
    OrbLow50Buffer[index] = currentORB.orbLowPrice + (orbRange * -0.5);
    OrbLow100Buffer[index] = currentORB.orbLowPrice + (orbRange * -1.0);
    
    if(showPriceTargetsExtended)
    {
        OrbHigh150Buffer[index] = currentORB.orbHighPrice + (orbRange * 1.5);
        OrbHigh200Buffer[index] = currentORB.orbHighPrice + (orbRange * 2.0);
        OrbHigh250Buffer[index] = currentORB.orbHighPrice + (orbRange * 2.5);
        OrbHigh300Buffer[index] = currentORB.orbHighPrice + (orbRange * 3.0);
        OrbHigh350Buffer[index] = currentORB.orbHighPrice + (orbRange * 3.5);
        OrbHigh400Buffer[index] = currentORB.orbHighPrice + (orbRange * 4.0);
        OrbHigh450Buffer[index] = currentORB.orbHighPrice + (orbRange * 4.5);
        OrbHigh500Buffer[index] = currentORB.orbHighPrice + (orbRange * 5.0);
        
        OrbLow150Buffer[index] = currentORB.orbLowPrice + (orbRange * -1.5);
        OrbLow200Buffer[index] = currentORB.orbLowPrice + (orbRange * -2.0);
        OrbLow250Buffer[index] = currentORB.orbLowPrice + (orbRange * -2.5);
        OrbLow300Buffer[index] = currentORB.orbLowPrice + (orbRange * -3.0);
        OrbLow350Buffer[index] = currentORB.orbLowPrice + (orbRange * -3.5);
        OrbLow400Buffer[index] = currentORB.orbLowPrice + (orbRange * -4.0);
        OrbLow450Buffer[index] = currentORB.orbLowPrice + (orbRange * -4.5);
    }
}

//+------------------------------------------------------------------+
//| Draw price target labels                                         |
//+------------------------------------------------------------------+
void DrawPriceTargetLabels(datetime time, double orbRange)
{
    if(!showLabels) return;
    
    string prefix = "ORB_Label_" + IntegerToString(currentORB.dayOfYear);
    ObjectsDeleteAll(0, prefix);
    
    datetime labelTime = time + labelOffsetBars * PeriodSeconds();
    double pipOffset = labelOffsetPips * pointMultiplier;
    
    // Basic ORB levels
    CreatePriceLabel(labelTime, currentORB.orbHighPrice + pipOffset + (20 * _Point), orbTitle + " HIGH", clrLime);
    CreatePriceLabel(labelTime, currentORB.orbLowPrice + pipOffset - (20 * _Point), orbTitle + " LOW", clrRed);
    
    if(showPriceTargets)
    {
        CreatePriceLabel(labelTime, currentORB.orbHighPrice + (orbRange * 0.5) + pipOffset, "PT 50%", orb50Color);
        CreatePriceLabel(labelTime, currentORB.orbHighPrice + (orbRange * 1.0) + pipOffset, "PT 100%", orb100Color);
        CreatePriceLabel(labelTime, currentORB.orbLowPrice + (orbRange * -0.5) + pipOffset, "PT 50%", orb50Color);
        CreatePriceLabel(labelTime, currentORB.orbLowPrice + (orbRange * -1.0) + pipOffset, "PT 100%", orb100Color);
        
        if(showPriceTargetsExtended)
        {
            CreatePriceLabel(labelTime, currentORB.orbHighPrice + (orbRange * 1.5) + pipOffset, "PT 150%", orbOtherColor);
            CreatePriceLabel(labelTime, currentORB.orbHighPrice + (orbRange * 2.0) + pipOffset, "PT 200%", orbOtherColor);
            CreatePriceLabel(labelTime, currentORB.orbHighPrice + (orbRange * 2.5) + pipOffset, "PT 250%", orbOtherColor);
            CreatePriceLabel(labelTime, currentORB.orbHighPrice + (orbRange * 3.0) + pipOffset, "PT 300%", orbOtherColor);
            
            CreatePriceLabel(labelTime, currentORB.orbLowPrice + (orbRange * -1.5) + pipOffset, "PT 150%", orbOtherColor);
            CreatePriceLabel(labelTime, currentORB.orbLowPrice + (orbRange * -2.0) + pipOffset, "PT 200%", orbOtherColor);
            CreatePriceLabel(labelTime, currentORB.orbLowPrice + (orbRange * -2.5) + pipOffset, "PT 250%", orbOtherColor);
            CreatePriceLabel(labelTime, currentORB.orbLowPrice + (orbRange * -3.0) + pipOffset, "PT 300%", orbOtherColor);
        }
        
        if(showMidPoint)
        {
            CreatePriceLabel(labelTime, currentORB.orbLowPrice + (orbRange * 0.5) + pipOffset, "MIDPOINT", clrGray);
        }
    }
}

//+------------------------------------------------------------------+
//| Create price label                                               |
//+------------------------------------------------------------------+
void CreatePriceLabel(datetime time, double price, string text, color clr)
{
    string labelName = "ORB_Label_" + IntegerToString(currentORB.dayOfYear) + "_" + text;
    
    if(ObjectCreate(0, labelName, OBJ_TEXT, 0, time, price))
    {
        ObjectSetString(0, labelName, OBJPROP_TEXT, text);
        ObjectSetInteger(0, labelName, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, labelFontSize);
        ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, labelAnchor);
        ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
    }
}

//+------------------------------------------------------------------+
//| Process breakout detection                                       |
//+------------------------------------------------------------------+
void ProcessBreakouts(const datetime &time[], const double &high[], const double &low[], const double &close[], int i, bool isToday)
{
    bool highCrossBO = CheckHighBreakout(high, low, close, i);
    bool lowCrossBO = CheckLowBreakout(high, low, close, i);
    
    if(showEntries)
    {
        if(highCrossBO)
        {
            CreateBreakoutLabel(time[i], high[i], "Breakout\nWait for Retest", clrGreen, true);
            inBreakout = true;
        }
        
        if(lowCrossBO)
        {
            CreateBreakoutLabel(time[i], low[i], "Breakout\nWait for Retest", clrGreen, false);
            inBreakout = true;
        }
        
        if(inBreakout)
        {
            bool isRetestHigh = close[i-1] > currentORB.orbHighPrice && low[i] <= currentORB.orbHighPrice && close[i] >= currentORB.orbHighPrice;
            bool isRetestLow = close[i-1] < currentORB.orbLowPrice && high[i] >= currentORB.orbLowPrice && close[i] <= currentORB.orbLowPrice;
            bool failedRetest = (close[i-1] > currentORB.orbHighPrice && close[i] < currentORB.orbHighPrice) || 
                               (close[i-1] < currentORB.orbLowPrice && close[i] > currentORB.orbLowPrice);
            
            if(isRetestHigh || isRetestLow)
            {
                CreateBreakoutLabel(time[i], high[i], "Retest", clrGreen, true);
                inBreakout = false;
            }
            else if(failedRetest)
            {
                CreateBreakoutLabel(time[i], high[i], "Failed Retest", clrRed, true);
                inBreakout = false;
            }
        }
    }
    
    if(isToday)
    {
        if(!alertBreakoutsOnly)
        {
            bool highCross = CheckCross(close, i, currentORB.orbHighPrice);
            bool lowCross = CheckCross(close, i, currentORB.orbLowPrice);
            
            if(highCross)
                SendNotification("Price crossing ORB High Level");
            if(lowCross)
                SendNotification("Price crossing ORB Low Level");
        }
        else
        {
            if(highCrossBO)
                SendNotification("Price breaking out of ORB High Level, Look for Retest");
            if(lowCrossBO)
                SendNotification("Price breaking out of ORB Low Level, Look for Retest");
        }
    }
}

//+------------------------------------------------------------------+
//| Create breakout label                                            |
//+------------------------------------------------------------------+
void CreateBreakoutLabel(datetime time, double price, string text, color clr, bool above)
{
    string labelName = "ORB_Breakout_" + TimeToString(time) + "_" + DoubleToString(price, 5);
    
    double adjustedPrice = above ? price + (50 * _Point) : price - (50 * _Point);
    
    if(ObjectCreate(0, labelName, OBJ_TEXT, 0, time, adjustedPrice))
    {
        ObjectSetString(0, labelName, OBJPROP_TEXT, text);
        ObjectSetInteger(0, labelName, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, above ? ANCHOR_LOWER : ANCHOR_UPPER);
        ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
    }
}

//+------------------------------------------------------------------+
//| Draw ORB Rectangle                                               |
//+------------------------------------------------------------------+
void DrawORBRectangle()
{
    if(!showShadedBox || currentORB.boxName == "" || currentORB.sessionStartBar < 0 || currentORB.sessionEndBar < 0) 
        return;
    
    ObjectDelete(0, currentORB.boxName);
    
    if(ObjectCreate(0, currentORB.boxName, OBJ_RECTANGLE, 0, currentORB.orbStartTime, currentORB.orbHighPrice, currentORB.orbEndTime, currentORB.orbLowPrice))
    {
        ObjectSetInteger(0, currentORB.boxName, OBJPROP_COLOR, shadeColor);
        ObjectSetInteger(0, currentORB.boxName, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, currentORB.boxName, OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, currentORB.boxName, OBJPROP_BACK, true);
        ObjectSetInteger(0, currentORB.boxName, OBJPROP_FILL, true);
        ObjectSetInteger(0, currentORB.boxName, OBJPROP_BGCOLOR, shadeColor);
    }
}

//+------------------------------------------------------------------+
//| Helper functions                                                 |
//+------------------------------------------------------------------+
bool IsInSession(MqlDateTime &dt)
{
    int currentMinutes = dt.hour * 60 + dt.min;
    int sessionStart = sessionStartHour * 60 + sessionStartMin;
    int sessionEnd = sessionEndHour * 60 + sessionEndMin;
    
    return (currentMinutes >= sessionStart && currentMinutes < sessionEnd);
}

bool IsFirstBarOfSession(const datetime &time[], int i, MqlDateTime &dt)
{
    if(i == 0) return false;
    
    MqlDateTime prevDt;
    TimeToStruct(time[i-1], prevDt);
    
    bool inSession = IsInSession(dt);
    bool wasInSession = IsInSession(prevDt);
    
    return (inSession && !wasInSession);
}

bool IsNewDay(const datetime &time[], int i)
{
    if(i == 0) return true;
    
    MqlDateTime dt, prevDt;
    TimeToStruct(time[i], dt);
    TimeToStruct(time[i-1], prevDt);
    
    return (dt.day != prevDt.day);
}

bool IsToday(datetime barTime)
{
    MqlDateTime dt, currentDt;
    TimeToStruct(barTime, dt);
    TimeToStruct(TimeCurrent(), currentDt);
    
    return (dt.year == currentDt.year && dt.day_of_year == currentDt.day_of_year);
}

bool CheckHighBreakout(const double &high[], const double &low[], const double &close[], int i)
{
    return (low[i-2] < currentORB.orbHighPrice && close[i-2] > currentORB.orbHighPrice && 
            low[i-1] > currentORB.orbHighPrice && close[i-1] > currentORB.orbHighPrice && 
            close[i] > low[i-1] && low[i] > currentORB.orbHighPrice);
}

bool CheckLowBreakout(const double &high[], const double &low[], const double &close[], int i)
{
    return (high[i-2] > currentORB.orbLowPrice && close[i-2] < currentORB.orbLowPrice && 
            high[i-1] < currentORB.orbLowPrice && close[i-1] < currentORB.orbLowPrice && 
            close[i] < high[i-1] && high[i] < currentORB.orbLowPrice);
}

bool CheckCross(const double &close[], int i, double level)
{
    if(i == 0) return false;
    return ((close[i-1] <= level && close[i] > level) || 
            (close[i-1] >= level && close[i] < level));
}