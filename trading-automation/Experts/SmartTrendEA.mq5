//+------------------------------------------------------------------+
//|                                                 SmartTrendEA.mq5  |
//|        EMA crossover + 200-EMA trend filter + ATR risk model     |
//|                                                                  |
//|  Designed for MetaTrader 5 (e.g. PU Prime MT5).                  |
//|  Built for DEMO / paper trading and Strategy Tester backtesting. |
//+------------------------------------------------------------------+
#property copyright "SmartTrendEA"
#property version   "1.00"
#property description "EMA crossover with trend filter, ATR stops/targets,"
#property description "risk-percent position sizing and ATR trailing stop."
#property description "Use on a DEMO account or the Strategy Tester first."

#include <Trade/Trade.mqh>

CTrade trade;

//============================ INPUTS =================================
input group "=== Strategy (entry signal) ==="
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT; // Timeframe (PERIOD_CURRENT = chart)
input int             InpFastEMA   = 12;             // Fast EMA period
input int             InpSlowEMA   = 26;             // Slow EMA period
input int             InpTrendEMA  = 200;            // Trend filter EMA period
input bool            InpUseTrend  = true;           // Require price on trend side of Trend EMA

input group "=== Risk & money management ==="
input double InpRiskPercent = 1.0;   // Risk per trade (% of balance); used when FixedLot = 0
input double InpFixedLot    = 0.0;   // Fixed lot size (0 = size by risk %)
input int    InpATRPeriod   = 14;    // ATR period (stops/targets/trailing)
input double InpSLatrMult   = 2.0;   // Stop loss   = ATR * this
input double InpTPatrMult   = 3.0;   // Take profit = ATR * this  (RR = TP/SL)
input bool   InpUseTrailing = true;  // Enable ATR trailing stop
input double InpTrailATRmult= 2.0;   // Trailing distance = ATR * this

input group "=== Filters ==="
input int  InpMaxSpreadPts  = 30;    // Max spread in points (0 = ignore)
input bool InpUseTimeFilter = false; // Restrict trading to an hour window (server time)
input int  InpStartHour     = 7;     // Start hour (0-23)
input int  InpEndHour       = 20;    // End hour (0-23)

input group "=== General ==="
input long InpMagic       = 20240601; // Magic number (unique per EA/chart)
input int  InpSlippagePts = 10;       // Max deviation/slippage in points

//============================ GLOBALS ===============================
int      hFast = INVALID_HANDLE;
int      hSlow = INVALID_HANDLE;
int      hTrend = INVALID_HANDLE;
int      hATR  = INVALID_HANDLE;
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(InpFastEMA >= InpSlowEMA)
   {
      Print("Config error: Fast EMA must be smaller than Slow EMA.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   hFast  = iMA(_Symbol, InpTimeframe, InpFastEMA,  0, MODE_EMA, PRICE_CLOSE);
   hSlow  = iMA(_Symbol, InpTimeframe, InpSlowEMA,  0, MODE_EMA, PRICE_CLOSE);
   hTrend = iMA(_Symbol, InpTimeframe, InpTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   hATR   = iATR(_Symbol, InpTimeframe, InpATRPeriod);

   if(hFast == INVALID_HANDLE || hSlow == INVALID_HANDLE ||
      hTrend == INVALID_HANDLE || hATR == INVALID_HANDLE)
   {
      Print("Failed to create indicator handles.");
      return(INIT_FAILED);
   }

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippagePts);
   trade.SetTypeFillingBySymbol(_Symbol);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Cleanup                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(hFast  != INVALID_HANDLE) IndicatorRelease(hFast);
   if(hSlow  != INVALID_HANDLE) IndicatorRelease(hSlow);
   if(hTrend != INVALID_HANDLE) IndicatorRelease(hTrend);
   if(hATR   != INVALID_HANDLE) IndicatorRelease(hATR);
}

//+------------------------------------------------------------------+
//| Main tick handler                                                |
//+------------------------------------------------------------------+
void OnTick()
{
   // Trailing runs every tick so stops follow price closely.
   if(InpUseTrailing)
      ManageTrailing();

   // Entries are evaluated only once per closed bar.
   if(!IsNewBar())
      return;

   if(!SpreadOK())
      return;

   if(InpUseTimeFilter && !TimeOK())
      return;

   // Pull the last two CLOSED bars for the EMAs (shift 1 and shift 2).
   double fast[], slow[], trend[], atr[];
   ArraySetAsSeries(fast,  true);
   ArraySetAsSeries(slow,  true);
   ArraySetAsSeries(trend, true);
   ArraySetAsSeries(atr,   true);

   if(CopyBuffer(hFast,  0, 1, 2, fast)  < 2) return;
   if(CopyBuffer(hSlow,  0, 1, 2, slow)  < 2) return;
   if(CopyBuffer(hTrend, 0, 1, 1, trend) < 1) return;
   if(CopyBuffer(hATR,   0, 1, 1, atr)   < 1) return;

   double atrVal = atr[0];
   if(atrVal <= 0) return;

   double trendVal   = trend[0];
   double closePrice = iClose(_Symbol, InpTimeframe, 1);

   // fast[0]/slow[0] = last closed bar; fast[1]/slow[1] = bar before it.
   bool crossUp   = (fast[1] <= slow[1] && fast[0] > slow[0]);
   bool crossDown = (fast[1] >= slow[1] && fast[0] < slow[0]);

   bool trendUpOK   = (!InpUseTrend || closePrice > trendVal);
   bool trendDownOK = (!InpUseTrend || closePrice < trendVal);

   if(crossUp && trendUpOK)
   {
      CloseDirection(POSITION_TYPE_SELL);
      if(CountPositions(POSITION_TYPE_BUY) == 0)
         OpenTrade(ORDER_TYPE_BUY, atrVal);
   }
   else if(crossDown && trendDownOK)
   {
      CloseDirection(POSITION_TYPE_BUY);
      if(CountPositions(POSITION_TYPE_SELL) == 0)
         OpenTrade(ORDER_TYPE_SELL, atrVal);
   }
}

//+------------------------------------------------------------------+
//| Open a position with ATR-based SL/TP and risk-based sizing       |
//+------------------------------------------------------------------+
void OpenTrade(const ENUM_ORDER_TYPE type, const double atrVal)
{
   double point      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   long   stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist    = stopsLevel * point;

   double slDist = atrVal * InpSLatrMult;
   double tpDist = atrVal * InpTPatrMult;
   if(slDist < minDist) slDist = minDist;
   if(tpDist < minDist) tpDist = minDist;

   double price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                           : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double sl, tp;
   if(type == ORDER_TYPE_BUY)
   {
      sl = price - slDist;
      tp = price + tpDist;
   }
   else
   {
      sl = price + slDist;
      tp = price - tpDist;
   }

   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   double lot = CalcLot(slDist);
   if(lot <= 0)
   {
      Print("Lot size resolved to 0 - trade skipped.");
      return;
   }

   if(!trade.PositionOpen(_Symbol, type, lot, price, sl, tp, "SmartTrendEA"))
      PrintFormat("Open failed (%d): %s", trade.ResultRetcode(), trade.ResultComment());
}

//+------------------------------------------------------------------+
//| Position sizing: risk % of balance over the SL distance         |
//+------------------------------------------------------------------+
double CalcLot(const double slDistPrice)
{
   if(InpFixedLot > 0.0)
      return NormalizeLot(InpFixedLot);

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmt = balance * InpRiskPercent / 100.0;

   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSz  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSz <= 0 || tickVal <= 0)
      return 0.0;

   double lossPerLot = (slDistPrice / tickSz) * tickVal;
   if(lossPerLot <= 0)
      return 0.0;

   double lot = riskAmt / lossPerLot;
   return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| Clamp a lot value to the symbol's min/max/step                  |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;

   lot = MathFloor(lot / step) * step;
   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;

   return lot;
}

//+------------------------------------------------------------------+
//| Count this EA's open positions of a given direction             |
//+------------------------------------------------------------------+
int CountPositions(const ENUM_POSITION_TYPE ptype)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == ptype)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Close all of this EA's positions of a given direction           |
//+------------------------------------------------------------------+
void CloseDirection(const ENUM_POSITION_TYPE ptype)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == ptype)
         trade.PositionClose(ticket);
   }
}

//+------------------------------------------------------------------+
//| ATR trailing stop for this EA's positions                       |
//+------------------------------------------------------------------+
void ManageTrailing()
{
   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(hATR, 0, 0, 1, atr) < 1) return;

   double trailDist = atr[0] * InpTrailATRmult;
   if(trailDist <= 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;

      ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL     = PositionGetDouble(POSITION_SL);
      double curTP     = PositionGetDouble(POSITION_TP);

      if(ptype == POSITION_TYPE_BUY)
      {
         double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double newSL = NormalizeDouble(bid - trailDist, _Digits);
         // Only move SL up, and only once trade is in profit beyond entry.
         if(newSL > openPrice && (curSL == 0.0 || newSL > curSL))
            trade.PositionModify(ticket, newSL, curTP);
      }
      else if(ptype == POSITION_TYPE_SELL)
      {
         double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double newSL = NormalizeDouble(ask + trailDist, _Digits);
         if(newSL < openPrice && (curSL == 0.0 || newSL < curSL))
            trade.PositionModify(ticket, newSL, curTP);
      }
   }
}

//+------------------------------------------------------------------+
//| True once per new bar on the working timeframe                  |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime t = iTime(_Symbol, InpTimeframe, 0);
   if(t != lastBarTime)
   {
      lastBarTime = t;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Spread filter                                                   |
//+------------------------------------------------------------------+
bool SpreadOK()
{
   if(InpMaxSpreadPts <= 0) return true;
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return (spread <= InpMaxSpreadPts);
}

//+------------------------------------------------------------------+
//| Trading-hours filter (server time)                              |
//+------------------------------------------------------------------+
bool TimeOK()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(InpStartHour <= InpEndHour)
      return (dt.hour >= InpStartHour && dt.hour < InpEndHour);
   // Overnight window (e.g. 22 -> 6)
   return (dt.hour >= InpStartHour || dt.hour < InpEndHour);
}
//+------------------------------------------------------------------+
