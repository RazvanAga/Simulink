This is the official Panasonic NCR18650B datasheet 

Extract the cell specifications and build a Simulink model called 
ncr18650b_thevenin.slx implementing a Thevenin ECM battery model.

From the datasheet:
- Nominal capacity at 20C: Min. 3200mAh
- Nominal capacity at 25C: Min. 3250mAh; Typ. 3350mAh
- Nominal voltage: 3.6V
- Charging Method: Constant Current -Constant Voltage
- Charging voltage: 4.2V 
- Charging Current: Std.1625mA
- Charging Time: 4.0hrs.
- Discharge cutoff voltage: 2.5V
- Standard charge current: 1.625A (0.5C)
- Discharge temperature range: -20°C to +60°C

Use these ECM parameters (from published identification on this cell):
- R0 = 0.0483 Ω (ohmic resistance)
- R1 = 0.0245 Ω, C1 = 1124 F (fast RC branch, τ1 ≈ 27s)
- R2 = 0.0080 Ω, C2 = 4051 F (slow RC branch, τ2 ≈ 32s)
- OCV(SOC) polynomial: use lookup table from 2.5V (SOC=0) to 4.2V (SOC=1)

Simulate a 1C discharge (3.35A constant) from SOC=100% to 0%.
Show terminal voltage and SOC on scopes.
Verify: voltage starts ~4.1V and ends at ~2.5V cutoff.