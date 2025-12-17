//+------------------------------------------------------------------+
//|                                          PythonBridgeEA.mq5     |
//|                        Receives signals from Python Bridge       |
//|                        Executes trades via MT5 API              |
//+------------------------------------------------------------------+
#property copyright "Trading Bridge System"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include "PythonBridge.mqh"

//--- Input parameters
input int BridgePort = 5555;           // Python bridge port (must match Python bridge)
input string BrokerName = "EXNESS";    // Broker name
input bool AutoExecute = true;          // Auto-execute trades
input double DefaultLotSize = 0.01;     // Default lot size if not specified
input int MaxRetries = 3;              // Max connection retries
input int RetryDelay = 5;              // Retry delay (seconds)

//--- Global variables
CTrade trade;
PythonBridge bridge;
datetime lastHeartbeat = 0;
int heartbeatInterval = 10; // seconds

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("Python Bridge EA initialized");
   
   // Initialize bridge connection
   if (!bridge.Initialize(BridgePort))
   {
      Print("ERROR: Failed to initialize bridge connection");
      return(INIT_FAILED);
   }
   
   Print("Bridge connection initialized on port ", BridgePort);
   
   // Send initial heartbeat
   bridge.SendHeartbeat();
   lastHeartbeat = TimeCurrent();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Python Bridge EA deinitialized");
   bridge.Close();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Send heartbeat periodically
   if (TimeCurrent() - lastHeartbeat >= heartbeatInterval)
   {
      bridge.SendHeartbeat();
      lastHeartbeat = TimeCurrent();
   }
   
   // Request signals from Python bridge
   TradeSignal signals[];
   int signalCount = bridge.GetSignals(signals);
   
   if (signalCount > 0)
   {
      Print("Received ", signalCount, " signal(s) from Python bridge");
      
      // Process each signal
      for (int i = 0; i < signalCount; i++)
      {
         ProcessSignal(signals[i]);
      }
   }
}

//+------------------------------------------------------------------+
//| Process trade signal                                             |
//+------------------------------------------------------------------+
void ProcessSignal(TradeSignal &signal)
{
   // Validate signal
   if (signal.symbol == "" || signal.action == "")
   {
      Print("ERROR: Invalid signal - missing symbol or action");
      return;
   }
   
   // Check if symbol matches current chart (or validate symbol exists)
   if (signal.symbol != _Symbol && signal.broker == BrokerName)
   {
      // Symbol doesn't match current chart - could execute on different symbol
      // For now, we'll only process signals for current symbol
      Print("INFO: Signal for different symbol: ", signal.symbol);
      return;
   }
   
   // Determine lot size
   double lotSize = signal.lot_size > 0 ? signal.lot_size : DefaultLotSize;
   
   // Execute trade based on action
   if (signal.action == "BUY")
   {
      ExecuteBuy(signal.symbol, lotSize, signal.stop_loss, signal.take_profit, signal.comment);
   }
   else if (signal.action == "SELL")
   {
      ExecuteSell(signal.symbol, lotSize, signal.stop_loss, signal.take_profit, signal.comment);
   }
   else if (signal.action == "CLOSE")
   {
      CloseAllPositions(signal.symbol);
   }
   else
   {
      Print("WARNING: Unknown action: ", signal.action);
   }
}

//+------------------------------------------------------------------+
//| Execute BUY order                                                |
//+------------------------------------------------------------------+
void ExecuteBuy(string symbol, double lotSize, double stopLoss, double takeProfit, string comment)
{
   if (!AutoExecute)
   {
      Print("INFO: Auto-execute disabled, skipping BUY order");
      return;
   }
   
   double price = SymbolInfoDouble(symbol, SYMBOL_ASK);
   
   // Normalize prices
   double sl = stopLoss > 0 ? NormalizeDouble(stopLoss, _Digits) : 0;
   double tp = takeProfit > 0 ? NormalizeDouble(takeProfit, _Digits) : 0;
   
   if (trade.Buy(lotSize, symbol, price, sl, tp, comment))
   {
      Print("BUY order executed: ", symbol, " Lot: ", lotSize, " SL: ", sl, " TP: ", tp);
      
      // Send status back to Python
      bridge.SendStatus("SUCCESS", "BUY order executed: " + symbol);
   }
   else
   {
      Print("ERROR: Failed to execute BUY order: ", trade.ResultRetcodeDescription());
      bridge.SendStatus("ERROR", "Failed to execute BUY: " + trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Execute SELL order                                               |
//+------------------------------------------------------------------+
void ExecuteSell(string symbol, double lotSize, double stopLoss, double takeProfit, string comment)
{
   if (!AutoExecute)
   {
      Print("INFO: Auto-execute disabled, skipping SELL order");
      return;
   }
   
   double price = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   // Normalize prices
   double sl = stopLoss > 0 ? NormalizeDouble(stopLoss, _Digits) : 0;
   double tp = takeProfit > 0 ? NormalizeDouble(takeProfit, _Digits) : 0;
   
   if (trade.Sell(lotSize, symbol, price, sl, tp, comment))
   {
      Print("SELL order executed: ", symbol, " Lot: ", lotSize, " SL: ", sl, " TP: ", tp);
      
      // Send status back to Python
      bridge.SendStatus("SUCCESS", "SELL order executed: " + symbol);
   }
   else
   {
      Print("ERROR: Failed to execute SELL order: ", trade.ResultRetcodeDescription());
      bridge.SendStatus("ERROR", "Failed to execute SELL: " + trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Close all positions for symbol                                    |
//+------------------------------------------------------------------+
void CloseAllPositions(string symbol)
{
   int total = PositionsTotal();
   int closed = 0;
   
   for (int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket > 0)
      {
         if (PositionGetString(POSITION_SYMBOL) == symbol)
         {
            if (trade.PositionClose(ticket))
            {
               closed++;
            }
         }
      }
   }
   
   if (closed > 0)
   {
      Print("Closed ", closed, " position(s) for ", symbol);
      bridge.SendStatus("SUCCESS", "Closed " + IntegerToString(closed) + " position(s)");
   }
}

