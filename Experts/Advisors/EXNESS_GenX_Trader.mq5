//+------------------------------------------------------------------+
//|                                       EXNESS_GenX_Trader.mq5     |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2025, MetaQuotes Ltd."
#property link      "https://forge.mql5.io/LengKundee/mql5.git"
#property version   "2.01"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
#include <Expert\Signal\SignalMA.mqh>
#include <Expert\Signal\SignalRSI.mqh>
#include <Expert\Trailing\TrailingParabolicSAR.mqh>
#include <Expert\Money\MoneySizeOptimized.mqh>
#include <ZoloBridge.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Inp_Expert_Title                      ="EXNESS GenX Trader v2.0";
int                      Expert_MagicNumber                    =81001;
bool                     Expert_EveryTick                      =false;
input bool               EnableTrading                         =true; // Enable Trading
//--- inputs for signal
input int                Inp_Signal_MA_Period                  =30;          // MA Period
input int                Inp_Signal_MA_Shift                   =0;           // MA Shift
input ENUM_MA_METHOD     Inp_Signal_MA_Method                  =MODE_EMA;    // MA Method
input ENUM_APPLIED_PRICE Inp_Signal_MA_Applied                 =PRICE_CLOSE; // MA Applied Price
//--- inputs for RSI filter
input int                Inp_Signal_RSI_Period                 =14;          // RSI Period
input double             Inp_Signal_RSI_Weight                 =0.5;         // RSI Weight (0.0 to 1.0)
//--- inputs for trailing
input double             Inp_Trailing_ParabolicSAR_Step        =0.02;        // PSAR Step
input double             Inp_Trailing_ParabolicSAR_Maximum     =0.2;         // PSAR Maximum
//--- inputs for money
input double             Inp_Money_SizeOptimized_DecreaseFactor=3.0;         // Money Decrease Factor
input double             Inp_Money_SizeOptimized_Percent       =1.0;         // Risk Percent
//--- inputs for ZOLO Integration
input group              "ZOLO Integration"
input bool               EnableWebRequest                      =true;
input string             WebRequestURL                         = "http://203.147.134.90";
input string             ZoloEncryptionKey                     = ""; // Leave empty for no encryption

//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;

//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(-1);
     }
//--- Creation of signal object
   CSignalMA *signal=new CSignalMA;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(-2);
     }
//--- Add signal to expert (will be deleted automatically))
   if(!ExtExpert.InitSignal(signal))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing signal");
      ExtExpert.Deinit();
      return(-3);
     }
//--- Set signal parameters
   signal->PeriodMA(Inp_Signal_MA_Period);
   signal->Shift(Inp_Signal_MA_Shift);
   signal->Method(Inp_Signal_MA_Method);
   signal->Applied(Inp_Signal_MA_Applied);
//--- Check signal parameters
   if(!signal->ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error signal parameters");
      ExtExpert.Deinit();
      return(-4);
     }
//--- Creation of RSI filter
   CSignalRSI *filter=new CSignalRSI;
   if(filter==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating RSI filter");
      ExtExpert.Deinit();
      return(-5);
     }
//--- Add filter to signal
   if(!signal->AddFilter(filter))
     {
      //--- failed
      printf(__FUNCTION__+": error adding RSI filter");
      ExtExpert.Deinit();
      return(-6);
     }
//--- Set filter parameters
   filter->PeriodRSI(Inp_Signal_RSI_Period);
   filter->Weight(Inp_Signal_RSI_Weight);
   // Note: Applied price for RSI is usually Close, defaulted in CSignalRSI
//--- Check filter parameters
   if(!filter->ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error RSI filter parameters");
      ExtExpert.Deinit();
      return(-7);
     }

//--- Creation of trailing object
   CTrailingPSAR *trailing=new CTrailingPSAR;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(-8);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(-9);
     }
//--- Set trailing parameters
   trailing->Step(Inp_Trailing_ParabolicSAR_Step);
   trailing->Maximum(Inp_Trailing_ParabolicSAR_Maximum);
//--- Check trailing parameters
   if(!trailing->ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error trailing parameters");
      ExtExpert.Deinit();
      return(-10);
     }
//--- Creation of money object
   CMoneySizeOptimized *money=new CMoneySizeOptimized;
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(-11);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(-12);
     }
//--- Set money parameters
   money->DecreaseFactor(Inp_Money_SizeOptimized_DecreaseFactor);
   money->Percent(Inp_Money_SizeOptimized_Percent);
//--- Check money parameters
   if(!money->ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error money parameters");
      ExtExpert.Deinit();
      return(-13);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(-14);
     }

   // --- User requested logging
   Print("═══════════════════════════════════════════════════");
   Print("     EXNESS GenX Trader v2.0 Initialized");
   Print("     Symbol: ", Symbol(), " (or your symbol)");
   Print("     Strategy: MA(10/", Inp_Signal_MA_Period, ") + RSI(", Inp_Signal_RSI_Period, ")");
   Print("     Risk: ", Inp_Money_SizeOptimized_Percent, "% per trade");
   Print("     Trading: ", (EnableTrading ? "ENABLED" : "DISABLED"));
   Print("═══════════════════════════════════════════════════");

   // Start Heartbeat Timer (Every 1 hour = 3600 seconds)
   EventSetTimer(3600);

//--- succeed
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| Function-event handler "tick"                                    |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   if(EnableTrading)
     {
      ExtExpert.OnTick();
     }
  }
//+------------------------------------------------------------------+
//| Function-event handler "trade"                                   |
//+------------------------------------------------------------------+
void OnTrade(void)
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| Function-event handler "timer"                                   |
//+------------------------------------------------------------------+
void OnTimer(void)
  {
   ExtExpert.OnTimer();

   // --- Heartbeat Logic ---
   // Construct the heartbeat message
   string timeStr = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   string msg = StringFormat("And bridge https://chat.whatsapp.com/J3io2JyrkBe0uCbB9WBHJE?mode=hqrc to schedule research to help analy uptime real data %s", timeStr);

   Print(msg);
   SendSignalToBridge(msg, EnableWebRequest, WebRequestURL, ZoloEncryptionKey);
  }
//+------------------------------------------------------------------+