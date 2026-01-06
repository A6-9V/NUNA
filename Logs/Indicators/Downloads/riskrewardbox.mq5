//+------------------------------------------------------------------+
//|                                                riskrewardbox.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#property strict
#property indicator_chart_window

input    bool              DrawAllChart   =  false;      // Draw Box on all opened charts
input    ENUM_TIMEFRAMES   TimeFrame      =  PERIOD_H1;  // Cart timeframe
string   OBJprefix         =  "ziwoxRSRW";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ChartDraw();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   long     chartID           =  ChartFirst();
   string   symb              =  "";
   ENUM_TIMEFRAMES ChartPer   =  0;
   if (DrawAllChart)
      while(chartID>=0)
      {
         ObjectsDeleteAll(chartID,OBJprefix,-1,-1);
         chartID = ChartNext(chartID);
      }
   else 
      ObjectsDeleteAll(0,OBJprefix,-1,-1);
      
   ObjectDelete(0,"Reset");   
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
//---
   ButtonCreate(0,"Reset",0,20,30,110,25,CORNER_LEFT_UPPER,"Reset All Box","Trebuchet MS",10,clrWhite,clrMediumSeaGreen,clrMediumSeaGreen,false,false,false,true,1,"");
   return(1);   
  }

void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam=="Reset") // Pause forwarder
       {
         ChartClean();
       }
     }
   if(id==CHARTEVENT_OBJECT_DRAG)
     {
  
      double   pricePink1    =  ObjectGetDouble(0, OBJprefix+".Risk_Reward_Pink", OBJPROP_PRICE, 0); // low pink
      double   pricePink2    =  ObjectGetDouble(0, OBJprefix+".Risk_Reward_Pink", OBJPROP_PRICE, 1); // top pink
      double   priceGreen1    = ObjectGetDouble(0, OBJprefix+".Risk_Reward_Green", OBJPROP_PRICE, 0); // low green
      double   priceGreen2    = ObjectGetDouble(0, OBJprefix+".Risk_Reward_Green", OBJPROP_PRICE, 1); // top green
      
      double maxPink = MathMax(pricePink1, pricePink2);
      double minPink = MathMin(pricePink1, pricePink2);
      double maxGreen = MathMax(priceGreen1, priceGreen2);
      double minGreen = MathMin(priceGreen1, priceGreen2);

     
      if(sparam==OBJprefix+".Risk_Reward_Green" )
       {

         double pinkSize = maxPink - minPink;
         int      time1    =  ObjectGetInteger (0, OBJprefix+".Risk_Reward_Green",OBJPROP_TIME, 0);
         int      time2    =  ObjectGetInteger (0, OBJprefix+".Risk_Reward_Green",OBJPROP_TIME, 1);
         
         
         if (maxPink > maxGreen ) { // Risk at top
            ObjectSetDouble (0, OBJprefix+".Risk_Reward_Pink",OBJPROP_PRICE, 0, maxGreen); 
            ObjectSetDouble (0, OBJprefix+".Risk_Reward_Pink",OBJPROP_PRICE, 1, maxGreen+pinkSize);
         }
         else { // Risk at bottom
            ObjectSetDouble (0, OBJprefix+".Risk_Reward_Pink",OBJPROP_PRICE, 1, minGreen); 
            ObjectSetDouble (0, OBJprefix+".Risk_Reward_Pink",OBJPROP_PRICE, 0, minGreen-pinkSize);
         }
         
         ObjectSetInteger(0, OBJprefix+".Risk_Reward_Pink",OBJPROP_TIME, 0, time1);     // mid
         ObjectSetInteger(0, OBJprefix+".Risk_Reward_Pink",OBJPROP_TIME, 1, time2);     // mid
         ChartRedraw(0);
       }
       
      if(sparam==OBJprefix+".Risk_Reward_Pink" )
       {
         double greeSize = maxGreen - minGreen;
         int      time1    =  ObjectGetInteger (0, OBJprefix+".Risk_Reward_Pink",OBJPROP_TIME, 0);
         int      time2    =  ObjectGetInteger (0, OBJprefix+".Risk_Reward_Pink",OBJPROP_TIME, 1);
         
         if (maxGreen > maxPink ) { // Reward at top
            ObjectSetDouble (0, OBJprefix+".Risk_Reward_Green", OBJPROP_PRICE, 0, maxPink); 
            ObjectSetDouble (0, OBJprefix+".Risk_Reward_Green",OBJPROP_PRICE, 1, maxPink+greeSize);
         }
         else { // Reward at bottom
            ObjectSetDouble (0, OBJprefix+".Risk_Reward_Green",OBJPROP_PRICE, 1, minPink); 
            ObjectSetDouble (0, OBJprefix+".Risk_Reward_Green",OBJPROP_PRICE, 0, minPink-greeSize);
         }         
         
         ObjectSetInteger(0, OBJprefix+".Risk_Reward_Green", OBJPROP_TIME, 0, time1);
         ObjectSetInteger(0, OBJprefix+".Risk_Reward_Green", OBJPROP_TIME, 1, time2);
         ChartRedraw(0);
       }
     }  
   
}
//+------------------------------------------------------------------+
bool ButtonCreate(const long              chart_ID=0,               // chart's ID
                  const string            name="Button",            // button name
                  const int               sub_window=0,             // subwindow index
                  const int               x=0,                      // X coordinate
                  const int               y=0,                      // Y coordinate
                  const int               width=50,                 // button width
                  const int               height=18,                // button height
                  const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                  const string            text="Button",            // text
                  const string            font="Arial",             // font
                  const int               font_size=10,             // font size
                  const color             clr=clrBlack,             // text color
                  const color             back_clr=C'236,233,216',  // background color
                  const color             border_clr=clrNONE,       // border color
                  const bool              state=false,              // pressed/released
                  const bool              back=false,               // in the background
                  const bool              selection=false,          // highlight to move
                  const bool              hidden=true,              // hidden in the object list
                  const long              z_order=0,                // priority for mouse click
                  const string            tooltip="\n")             // tooltip for mouse hover
  {
//--- reset the error value
   ResetLastError();
//---
   if(ObjectFind(chart_ID,name)!=0)
     {
      if(!ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0))
        {
         Print(__FUNCTION__,
               ": failed to create the button! Error code = ",_LastError);
         return(false);
        }
      //--- SetObjects
      ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
      ObjectSetString(chart_ID,name,OBJPROP_TOOLTIP,tooltip);
     }
     else
     {
     ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
      ObjectSetString(chart_ID,name,OBJPROP_TOOLTIP,tooltip);
     }
//---
   return(true);
  }

void ChartClean()
{
   long     chartID           =  ChartFirst();
   string   symb              =  "";
   ENUM_TIMEFRAMES ChartPer   =  0;
   if (DrawAllChart)
   while(chartID>=0)
     {
      ObjectsDeleteAll(chartID,OBJprefix,-1,-1);
      chartID = ChartNext(chartID);
     }
   else ObjectsDeleteAll(0,OBJprefix,-1,-1);
   ObjectSetInteger(0,"Reset",OBJPROP_STATE,false);
   ChartDraw();
}


//====================================================================
//+------------------------------------------------------------------+
//| OnTick Deinit                                                    |
//+------------------------------------------------------------------+
void ChartDraw()
{
   long     chart_ID             =  ChartFirst();
   string   symbl                =  "";
   ENUM_TIMEFRAMES chartperiod   =  0;
   if (DrawAllChart)
   while(chart_ID>=0)
     {
      symbl          =  ChartSymbol(chart_ID);
      chartperiod    =  ChartPeriod(chart_ID);
      string   name  =  OBJprefix+".Risk_Reward_Pink";
      double   top   =  iHigh(symbl,chartperiod,iHighest(symbl,chartperiod,MODE_HIGH,20,0));
      double   low   =  iLow(symbl,chartperiod,iLowest(symbl,chartperiod,MODE_LOW,20,0));
      double   mid   =  SymbolInfoDouble(symbl,SYMBOL_ASK);
      if (ObjectFind(chart_ID,name)<0)
      {
      ObjectCreate(chart_ID,name,OBJ_RECTANGLE,0,iTime(symbl,chartperiod,0),low,iTime(symbl,chartperiod,0)+PeriodSeconds()*25,mid);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrPink);
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,2);
      ObjectSetInteger(chart_ID,name,OBJPROP_FILL,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,true);  
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,0);
      }
      name  =  OBJprefix+".Risk_Reward_Green";
      if (ObjectFind(chart_ID,name)<0)
      {
      ObjectCreate(chart_ID,name,OBJ_RECTANGLE,0,iTime(symbl,chartperiod,0),mid,iTime(symbl,chartperiod,0)+PeriodSeconds()*25,top);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrLightGreen);
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,2);
      ObjectSetInteger(chart_ID,name,OBJPROP_FILL,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,true);  
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,0);
      }
      chart_ID = ChartNext(chart_ID);
     }
     else {
      chart_ID       =  0;
      symbl          =  Symbol();
      chartperiod    =  PERIOD_CURRENT;
      string   name  =  OBJprefix+".Risk_Reward_Pink";
      double   top   =  iHigh(symbl,chartperiod,iHighest(symbl,chartperiod,MODE_HIGH,20,0));
      double   low   =  iLow(symbl,chartperiod,iLowest(symbl,chartperiod,MODE_LOW,20,0));
      double   mid   =  SymbolInfoDouble(symbl,SYMBOL_ASK);
      if (ObjectFind(chart_ID,name)<0)
      {
      ObjectCreate(chart_ID,name,OBJ_RECTANGLE,0,iTime(symbl,chartperiod,0),low,iTime(symbl,chartperiod,0)+PeriodSeconds()*25,mid);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrPink);
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,2);
      ObjectSetInteger(chart_ID,name,OBJPROP_FILL,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,true);  
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,0);
      }
      name  =  OBJprefix+".Risk_Reward_Green";
      if (ObjectFind(chart_ID,name)<0)
      {
      ObjectCreate(chart_ID,name,OBJ_RECTANGLE,0,iTime(symbl,chartperiod,0),mid,iTime(symbl,chartperiod,0)+PeriodSeconds()*25,top);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrLightGreen);
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,2);
      ObjectSetInteger(chart_ID,name,OBJPROP_FILL,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,true);  
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,0);
      }
     }
}
