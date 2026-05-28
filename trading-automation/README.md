# SmartTrendEA — MetaTrader 5 Trading Automation

An automated trading robot (Expert Advisor) for **MetaTrader 5**, built to run on a
**PU Prime MT5** account. It is intended for **paper trading (demo account)** and
**backtesting in the Strategy Tester** first — not for blindly going live.

> ⚠️ **Risk warning.** Automated trading can lose money fast. This EA is provided for
> education and testing. Run it on a **demo account** and in the **Strategy Tester**
> until you fully understand its behaviour. Past backtest results do not guarantee
> future performance. Only ever risk money you can afford to lose, and never go live
> without thorough testing.

---

## What it does (the strategy)

A trend-following crossover system with a strict risk model:

1. **Entry signal** — Fast EMA (12) crosses the Slow EMA (26).
   - Cross **up** → look to **buy**.
   - Cross **down** → look to **sell**.
2. **Trend filter** — trades are only taken in the direction of the 200-EMA
   (buy only when price is above it, sell only when below). This avoids fighting the
   dominant trend. Can be turned off.
3. **Exits / risk** — every trade gets:
   - **Stop loss** = ATR × 2.0
   - **Take profit** = ATR × 3.0 (so the default reward:risk is ~1.5:1)
   - An optional **ATR trailing stop** that locks in profit as price moves your way.
4. **Position sizing** — by default it risks a fixed **% of account balance** per trade
   (1% default) and computes the lot size from the stop distance. You can switch to a
   fixed lot instead.
5. **Filters** — optional max-spread filter and trading-hours window.

Only one position per direction is held at a time. An opposite signal closes the
current trade and opens the new one.

---

## Files

```
trading-automation/
├── Experts/
│   └── SmartTrendEA.mq5   ← the Expert Advisor source
└── README.md              ← this file
```

---

## 1. Install into MetaTrader 5

1. Open MT5 (the PU Prime MT5 terminal).
2. Menu **File → Open Data Folder**. This opens the terminal's data directory.
3. Navigate into `MQL5/Experts/`.
4. Copy **`SmartTrendEA.mq5`** into that `Experts` folder.
5. Back in MT5, open **MetaEditor** (the toolbar icon, or `F4`).
6. In MetaEditor's Navigator, find `Experts → SmartTrendEA.mq5`, open it, and click
   **Compile** (`F7`). You should see `0 errors, 0 warnings`. This produces
   `SmartTrendEA.ex5`, which MT5 can run.

---

## 2. Backtest it (Strategy Tester)

1. In MT5, open the **Strategy Tester**: menu **View → Strategy Tester** (`Ctrl+R`).
2. Set:
   - **Expert:** `SmartTrendEA`
   - **Symbol:** the instrument you want (e.g. `EURUSD`, `XAUUSD` — use the exact name
     from your PU Prime symbol list).
   - **Period:** the timeframe (e.g. `H1`).
   - **Date range:** a meaningful span (e.g. the last 1–2 years).
   - **Modelling:** *Every tick based on real ticks* is the most realistic.
   - **Deposit:** a realistic starting balance.
3. Optionally open the **Inputs** tab to adjust parameters (see table below).
4. Click **Start**. Review the **Graph**, **Report** (profit factor, drawdown, win
   rate), and **Backtest** journal.
5. Use the **Optimization** mode to sweep parameter ranges if you want to tune it —
   but beware of curve-fitting; always validate on an out-of-sample period.

---

## 3. Paper trade on a PU Prime demo account

1. Open a **demo** account in MT5: **File → Open an Account**, choose the PU Prime
   server, and select **Demo**. (No real money is involved.)
2. Log in to the demo account.
3. Enable algo trading: toolbar **Algo Trading** button must be green
   (Tools → Options → Expert Advisors → *Allow algorithmic trading*).
4. Open a chart for your chosen symbol and timeframe.
5. From the Navigator, drag **`SmartTrendEA`** onto the chart.
6. In the dialog, on the **Common** tab tick *Allow algo trading*; set inputs on the
   **Inputs** tab; click **OK**.
7. A smiley face in the top-right of the chart means it's running. Watch the
   **Experts** and **Journal** tabs (Toolbox) and the **Trade** tab for activity.

Leave it running on demo for a while and compare live behaviour against your backtest
before ever considering real funds.

---

## Input parameters

| Input | Default | Meaning |
|---|---|---|
| `InpTimeframe` | `PERIOD_CURRENT` | Timeframe for signals (current chart by default). |
| `InpFastEMA` | `12` | Fast EMA period. |
| `InpSlowEMA` | `26` | Slow EMA period (must be > fast). |
| `InpTrendEMA` | `200` | Trend-filter EMA period. |
| `InpUseTrend` | `true` | Require price on the trend side of the Trend EMA. |
| `InpRiskPercent` | `1.0` | Risk per trade as % of balance (used when `InpFixedLot` = 0). |
| `InpFixedLot` | `0.0` | Fixed lot size; `0` = size automatically by risk %. |
| `InpATRPeriod` | `14` | ATR period for stops/targets/trailing. |
| `InpSLatrMult` | `2.0` | Stop loss = ATR × this. |
| `InpTPatrMult` | `3.0` | Take profit = ATR × this. |
| `InpUseTrailing` | `true` | Enable ATR trailing stop. |
| `InpTrailATRmult` | `2.0` | Trailing distance = ATR × this. |
| `InpMaxSpreadPts` | `30` | Skip entries when spread exceeds this (points); `0` = ignore. |
| `InpUseTimeFilter` | `false` | Only trade within an hour window (server time). |
| `InpStartHour` / `InpEndHour` | `7` / `20` | The trading window when the time filter is on. |
| `InpMagic` | `20240601` | Unique ID for this EA's trades (change per chart/instance). |
| `InpSlippagePts` | `10` | Max allowed deviation/slippage in points. |

---

## Tips & notes

- **Symbol names differ per broker.** Use the exact symbol string shown in your PU
  Prime *Market Watch* (some have suffixes like `EURUSD.x`).
- **Start conservative.** 1% risk or less per trade; test before increasing.
- **One EA per (symbol, magic).** If you run it on multiple charts, give each a
  different `InpMagic` so they don't interfere.
- **It evaluates entries on bar close**, so signals appear once per completed candle —
  this is intentional to avoid intrabar noise.
- This is a starting framework. Tell me if you want a different strategy (RSI
  mean-reversion, grid/DCA, breakout), extra features (news filter, daily loss limit,
  Telegram alerts), or a Python version using the `MetaTrader5` package.
