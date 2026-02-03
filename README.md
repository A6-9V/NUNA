# MQL5 Trading Robots

This repository contains a collection of MQL5 trading robots (Expert Advisors).

## Robots

*   **DarkCloud PiercingLine CCI**: This robot uses the Dark Cloud Cover and Piercing Line candlestick patterns in conjunction with the Commodity Channel Index (CCI) to identify trading opportunities.
*   **HangingMan Hammer CCI**: This robot uses the Hanging Man and Hammer candlestick patterns in conjunction with the Commodity Channel Index (CCI) to identify trading opportunities.
*   **DarkCloud PiercingLine RSI**: This robot uses the Dark Cloud Cover and Piercing Line candlestick patterns in conjunction with the Relative Strength Index (RSI) to identify trading opportunities.

## Common Parameters

All robots share a common set of input parameters for configuration.

### Indicator Parameters
*   `InpAverBodyPeriod`: Period for calculating the average candlestick size (default: 12).
*   `InpMAPeriod`: Trend MA period (default: 5).
*   `InpPrice`: Price type to use for calculations (default: `PRICE_CLOSE`).

### Specific Indicator Parameters
*   `InpPeriodCCI` (for CCI-based robots): CCI period (default: 37).
*   `InpPeriodRSI` (for RSI-based robots): RSI period (default: 37).

### Trade Parameters
*   `InpDuration`: Position holding time in bars (default: 10).
*   `InpSL`: Stop Loss in points (default: 200).
*   `InpTP`: Take Profit in points (default: 200).
*   `InpSlippage`: Slippage in points (default: 10).

### Money Management
*   `InpLot`: Lot size for trades (default: 0.1).

### Expert ID
*   `InpMagicNumber`: A unique number to identify trades opened by a specific EA.
    *   `DarkCloud PiercingLine CCI`: 120500
    *   `HangingMan Hammer CCI`: 124100
    *   `DarkCloud PiercingLine RSI`: 120700
