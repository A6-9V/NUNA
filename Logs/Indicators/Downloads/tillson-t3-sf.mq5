/*
    Tillson T3
    Copyright (C) 2025  boyvlad  <https://www.mql5.com/en/users/boyvlad/>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

//--- Do not remove!
#property tester_everytick_calculate
//---
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 1
//---
#property indicator_label1 "T3"
#property indicator_type1  DRAW_LINE
#property indicator_color1 clrViolet
#property indicator_style1 STYLE_SOLID
#property indicator_width1 3
//---
#define VER_MAJOR     1
#define VER_MINOR     0
#define MIN_MQL_BUILD 5370
//---
#property version     string(VER_MAJOR)"."string(VER_MINOR)
#property description "Compiler build: "string(__MQLBUILD__)
#property copyright   "boyvlad"
#property link        "https://www.mql5.com/en/users/boyvlad/"
//---

#ifdef __MQL4__
   #property strict
   #ifndef ERR_SUCCESS
      #define ERR_SUCCESS ERR_NO_ERROR
   #endif 
#endif 

class CArrayHelper
  {
public:
   template<typename T>
   static void deleteEach(T& arr[])
     {
      for(int i = ArraySize(arr) - 1; i >= 0; i--)
         delete arr[i];
     }
   
   template<typename T>
   static bool add(T value, T& arr[], const int reserveSize)
     {
      int size = ArraySize(arr);
      return addEx(value, arr, size, reserveSize);
     }
   
   template<typename T>
   static bool expand(T& arr[], const int reserveSize)
     {
      int size = ArraySize(arr);
      return expandEx(arr, size, reserveSize);
     }
   
   template<typename T>
   static bool addEx(T value, T& arr[], int& arrSize, const int reserveSize)
     {
      if(!expandEx(arr, arrSize, reserveSize))
         return false;
      arr[arrSize - 1] = value;
      return true;
     }
   
   template<typename T>
   static bool expandEx(T& arr[], int& size, const int reserveSize)
     {
      ResetLastError();
      int returned = ArrayResize(arr, ++size, reserveSize);
      if(returned == size && _LastError == ERR_SUCCESS)
         return true;
      PrintFormat(__FUNCSIG__" error %i, newSize %i, result %i", _LastError, size, returned);
      return false;
     }
  };

class CFormedBarTime
  {
public:
   void set(datetime a_value) { value = a_value; }
   
   bool onNewBar(const int rates_total, const datetime &time[])
     {
      if(value == time[rates_total - 3])
        {
         value = time[rates_total - 2];
         return true;
        }
      printUnexpectedValue(rates_total, time);
      return false;
     }
   
private:
   void printUnexpectedValue(const int rates_total, const datetime &time[])
     {
      PrintFormat("CFormedBarTime: Unexpected value %s. time[-3] %s, time[-2] %s, rates_total %i", TimeToString(value),
                  TimeToString(time[rates_total - 3]), TimeToString(time[rates_total - 2]), rates_total);
     }
   
private:
   datetime value;
public:
   CFormedBarTime() : value(0) {}
  };

//---
#define _reserveSize 25

class CSubIndiBase;

class CSubIndiRegistry
  {
public:
   static void clear()
     {
      // Even with drawBegin = 0, at least 2 bars on the chart are required
      // Tracking the last formed bar (CFormedBarTime, for example) requires 3 bars on the chart
      barsRequired = 3;
      //---
      numOfPtrs = 0;
      ArrayResize(ptrs, numOfPtrs, _reserveSize);
     }
   
   static void register(CSubIndiBase& instance)
     {
      if(instance.barsRequired > barsRequired)
         barsRequired = instance.barsRequired;
      CArrayHelper::addEx(&instance, ptrs, numOfPtrs, _reserveSize);
     }
   
   static bool checkRatesTotal(int rates_total, int prev_calculated)
     {
      if(rates_total < barsRequired)
        {
         PrintFormat("Not enough bars on the chart to calculate the indicator. Required: %i, available: %i.", barsRequired, rates_total);
         return false; 
        }
      if(rates_total < prev_calculated)
        {
         PrintFormat(__FUNCTION__" Something went wrong. rates_total: %i, prev_calculated: %i", rates_total, prev_calculated);
         return false;
        }
      return true;
     }
   
private:
   static int           barsRequired;
   static CSubIndiBase* ptrs[];
   static int           numOfPtrs;
  };

int           CSubIndiRegistry::barsRequired;
CSubIndiBase* CSubIndiRegistry::ptrs[];
int           CSubIndiRegistry::numOfPtrs = 0;

//---
#undef _reserveSize

class CSubIndiBase
  {
private:
   virtual void assignToAllBuffers(int barIdx, double a_value) = 0;
   
protected:
   int prepareBeforeCalculating(const int rates_total, const int prev_calculated)
     {
      int idxRecalcFrom;
      switch(rates_total - prev_calculated)
        {
         case 0:
         case 1:
            idxRecalcFrom = prev_calculated - 1;
            if(idxRecalcFrom < drawBegin)
              {
               idxRecalcFrom = drawBegin;
               clearLeftFromDrawBegin();
              }
            break;
         default:
            idxRecalcFrom = drawBegin;
            clearLeftFromDrawBegin();
            break;
        }
      return idxRecalcFrom;
     }
   
   void clearLeftFromDrawBegin()
     {
      for(int i = 0; i < drawBegin; i++)
         assignToAllBuffers(i, emptyValue);
     }
   
public:
   const int    barsRequired;
   const int    drawBegin;
   const double emptyValue;
protected:
   CSubIndiBase(int a_barsRequired, double a_emptyValue)
      : barsRequired(a_barsRequired < 1 ? 1 : a_barsRequired),
        drawBegin(barsRequired - 1),
        emptyValue(a_emptyValue)
     {
      if(a_barsRequired < 1)
         PrintFormat(__FUNCTION__": invalid barsRequired value (%i) received; corrected to minimum allowed (%i)", a_barsRequired, barsRequired);
      CSubIndiRegistry::register(this);
     }
  };

class CIndiParamsBase
  {
public:
   int                period;
   double             volumeFactor;
   ENUM_APPLIED_PRICE applyTo;
  };

class CAppliedPrice : public CSubIndiBase
  {
public:
   static double calculate(int barIdx, ENUM_APPLIED_PRICE a_mode, const double &open[], const double &high[], const double &low[],
                           const double &close[])
     {
      switch(a_mode)
        {
         case PRICE_OPEN:     return open[barIdx];
         case PRICE_HIGH:     return high[barIdx];
         case PRICE_LOW:      return low[barIdx];
         case PRICE_MEDIAN:   return (high[barIdx] + low[barIdx]) / 2.0;
         case PRICE_TYPICAL:  return (high[barIdx] + low[barIdx] + close[barIdx]) / 3.0;
         case PRICE_WEIGHTED: return (high[barIdx] + low[barIdx] + close[barIdx] + close[barIdx]) / 4.0;
         default:             return close[barIdx];
        }
     }
   
   void onCalculate(const int rates_total, const int prev_calculated, const double &open[], const double &high[], const double &low[],
                    const double &close[])
     {
      for(int i = prepareBeforeCalculating(rates_total, prev_calculated); i < rates_total; i++)
         buffer[i] = calculate(i, mode, open, high, low, close);
     }
   
private:
   void assignToAllBuffers(int barIdx, double a_value) override { buffer[barIdx] = a_value; }
   
private:
   const ENUM_APPLIED_PRICE mode;
public:
   double                   buffer[];
public:
   CAppliedPrice(ENUM_APPLIED_PRICE a_mode) : CSubIndiBase(1, EMPTY_VALUE), mode(a_mode) {}
  };

class CIndicatorBase
  {
public:
   int onCalculate(const int rates_total, const int prev_calculated, const double &open[], const double &high[], const double &low[],
                   const double &close[], const datetime &time[])
     {
      if(!CSubIndiRegistry::checkRatesTotal(rates_total, prev_calculated))
         return 0;
      internalOnCalculate(rates_total, prev_calculated, open, high, low, close, time);
      return rates_total;
     }
   
private:
   virtual void internalOnCalculate(const int rates_total, const int prev_calculated, const double &open[], const double &high[],
                                    const double &low[], const double &close[], const datetime &time[]) = 0;

protected:
   CIndicatorBase() { CSubIndiRegistry::clear(); }
  };

namespace T3
{
class CStateBase
  {
protected:
   void operator=(const CStateBase& other) {}
   
protected:
   const double alpha;
   const double alphaInv;
   const double coeff6;
   const double coeff5;
   const double coeff4;
   const double coeff3;
public:
   CStateBase(int period, double volumeFactor)
      : alpha(2.0 / (1.0 + period)),
        alphaInv(1.0 - alpha),
        coeff6(-MathPow(volumeFactor, 3.0)),
        coeff5(3.0 * (MathPow(volumeFactor, 2.0) + MathPow(volumeFactor, 3.0))),
        coeff4(3.0 * (2.0 * MathPow(volumeFactor, 2.0) + volumeFactor + MathPow(volumeFactor, 3.0))),
        coeff3(1.0 + 3.0 * volumeFactor + MathPow(volumeFactor, 3.0) + 3.0 * MathPow(volumeFactor, 2.0)) {}
  };

class CState : public CStateBase
  {
public:
   void advance(double &bufferValue, double sourceValue)
     {
      ema1 = alpha * sourceValue + alphaInv * ema1;
      ema2 = alpha * ema1 + alphaInv * ema2;
      ema3 = alpha * ema2 + alphaInv * ema3;
      ema4 = alpha * ema3 + alphaInv * ema4;
      ema5 = alpha * ema4 + alphaInv * ema5;
      ema6 = alpha * ema5 + alphaInv * ema6;
      bufferValue = coeff6 * ema6 + coeff5 * ema5 - coeff4 * ema4 + coeff3 * ema3;
     }
   
   static double forecast(double sourceValue, const CState& prev)
     {
      const double ema1 = prev.alpha * sourceValue + prev.alphaInv * prev.ema1;
      const double ema2 = prev.alpha * ema1 + prev.alphaInv * prev.ema2;
      const double ema3 = prev.alpha * ema2 + prev.alphaInv * prev.ema3;
      const double ema4 = prev.alpha * ema3 + prev.alphaInv * prev.ema4;
      const double ema5 = prev.alpha * ema4 + prev.alphaInv * prev.ema5;
      const double ema6 = prev.alpha * ema5 + prev.alphaInv * prev.ema6;
      return prev.coeff6 * ema6 + prev.coeff5 * ema5 - prev.coeff4 * ema4 + prev.coeff3 * ema3;
     }
   
private:
   double ema1;
   double ema2;
   double ema3;
   double ema4;
   double ema5;
   double ema6;
public:
   CState(double &bufferValue, double sourceValue, const CStateBase &config)
      : CStateBase(config),
        ema1(sourceValue),
        ema2(sourceValue),
        ema3(sourceValue),
        ema4(sourceValue),
        ema5(sourceValue),
        ema6(sourceValue) { bufferValue = sourceValue; }
   
   CState(const CStateBase &config) : CStateBase(config) {}
  };

class CSubIndi : public CSubIndiBase
  {
   int prepareBeforeCalculating(int, int) = delete;
   
   void assignToAllBuffers(int barIdx, double a_value) override { buffer[barIdx] = a_value; }
   
   void recalculAll(const int rates_total, const double &source[], const datetime &time[])
     {
      clearLeftFromDrawBegin();
      CState loopState(buffer[drawBegin], source[drawBegin], config);
      const int idxOfFormedBar = rates_total - 2;
      for(int i = drawBegin + 1; i <= idxOfFormedBar; i++)
         loopState.advance(buffer[i], source[i]);
      formedBar = loopState;
      timeOfFormedBar.set(time[idxOfFormedBar]);
      calculCurrentBar(rates_total, source);
     }
   
   void calculCurrentBar(const int rates_total, const double &source[])
     {
      buffer[rates_total - 1] = CState::forecast(source[rates_total - 1], formedBar);
     }
   
public:
   void onCalculate(const int rates_total, const int prev_calculated, const double &source[], const datetime &time[])
     {
      switch(rates_total - prev_calculated)
        {
         case 0:
            calculCurrentBar(rates_total, source);
            break;
         case 1:
            if(timeOfFormedBar.onNewBar(rates_total, time))
              {
               formedBar.advance(buffer[rates_total - 2], source[rates_total - 2]);
               calculCurrentBar(rates_total, source);
              }
            else recalculAll(rates_total, source, time);
            break;
         default:
            recalculAll(rates_total, source, time);
            break;
        }
     }
   
public:
   double           buffer[];
private:
   const CStateBase config;
   CState           formedBar;
   CFormedBarTime   timeOfFormedBar;
public:
   CSubIndi(int period, double volumeFactor, const CSubIndiBase& source)
      : CSubIndiBase(source.barsRequired, EMPTY_VALUE),
        config(period, volumeFactor),
        formedBar(config) {}
  };
}

//--- INDICATOR_DATA
#define _buffIdxT3      0
//--- INDICATOR_CALCULATIONS
#define _buffIdxApplPrc 1
//--- Plots
#define _plotIdxT3      0
//---

class CIndicator : public CIndicatorBase
  {
private:
   void internalOnCalculate(const int rates_total, const int prev_calculated, const double &open[], const double &high[],
                            const double &low[], const double &close[], const datetime &time[])
     {
      appliedPrice.onCalculate(rates_total, prev_calculated, open, high, low, close);
      t3.onCalculate(rates_total, prev_calculated, appliedPrice.buffer, time);
     }
   
   static void setPlot(int plotIdx, const CSubIndiBase &ref)
     {
      PlotIndexSetDouble(plotIdx, PLOT_EMPTY_VALUE, ref.emptyValue);
     }
   
private:
   CAppliedPrice appliedPrice;
   T3::CSubIndi  t3;
public:
   CIndicator(const CIndiParamsBase &params)
      : appliedPrice(params.applyTo),
        t3(params.period, params.volumeFactor, appliedPrice)
     {
      SetIndexBuffer(_buffIdxT3, t3.buffer, INDICATOR_DATA);
      SetIndexBuffer(_buffIdxApplPrc, appliedPrice.buffer, INDICATOR_CALCULATIONS);
      setPlot(_plotIdxT3, t3);
      PlotIndexSetString(_plotIdxT3, PLOT_LABEL, StringFormat("T3(%i, %.3f)", params.period, params.volumeFactor));
     }
  };

//---
#undef _buffIdxT3
#undef _buffIdxApplPrc
#undef _plotIdxT3

input(name="Period") int                  inpPeriod       = 5;
input(name="Volume factor") double        inpVolumeFactor = 0.7;
input(name="Apply to") ENUM_APPLIED_PRICE inpApplyTo      = PRICE_CLOSE;

class CIndiParams final : public CIndiParamsBase
  {
public:
   CIndiParams() : CIndiParamsBase()
     {
      period = inpPeriod;
      volumeFactor = inpVolumeFactor;
      applyTo = inpApplyTo;
      //---
      if(period < 2)
        {
         Print("Period corrected to 2");
         period = 2;
        }
     }
  };

CIndicator* Indicator;

int OnInit()
  {
   CIndiParams params;
   Indicator = new CIndicator(params);
   return checkCompilerBuild() ? INIT_SUCCEEDED : INIT_FAILED;
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
   return Indicator.onCalculate(rates_total, prev_calculated, open, high, low, close, time);
  }

void OnDeinit(const int reason)
  {
   delete Indicator;
  }

bool checkCompilerBuild()
  {
   if(__MQLBUILD__ >= MIN_MQL_BUILD)
      return true;
   Alert("Outdated compiler build "string(__MQLBUILD__)"! Recompile using compiler build "string(MIN_MQL_BUILD)" or later");
   return false;
  }
