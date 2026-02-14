# THzGS_LinkBudget_Calcs

## Relevant Mission Commentary
Plan and expect a 6-month-long mission. Design satellite bus as though we were doing 1-year-long mission.

Expected number of passes over Boston NU Campus (during 6 month-long mission) that reach X degrees of elevation (from GS pov) for at least 20 seconds shown in the table below. pairings (600km, 73°) and (550km, 67°) are done based on what elevation angle closes the link budget at the corresponding altitude during the summer season when using a 75 dBi effective ground dish antenna.  
| Orbit Inclination | Altitude | X Elev. | Num. Passes | Commentary | 
|-----------|---------|---------|---------|---------|
| 45-60° | 600 km | 73° | TBD | Typical rideshare orbits |
| 45-60° | 550 km | 67° | TBD | Typical rideshare orbits |
| 51.6° | 416 km| 60° | ~140 | ISS orbit |

## Relevant Dish Commentary
Closes for 75 dB effective GS antenna gain. For 5 dB efficiency loss, this corresponds with 80 dBi directivity which is just under 5 meters in diameter!


#### Orbit & Geometry

| Parameter | Value |
|-----------|---------|
| Orbit Altitude (worst case) | 600 km |
| Earth Mean Radius | 6371 km |
| GS Antenna Height (ASL) | 33.2 m |
| GS Coordinates | (42.33°, −71.09°) |

---

### RF & Waveform

| Parameter | Value |
|-----------|---------|
| Center Frequency | 225 GHz |
| Modulation | BPSK |
| Target Bit Rate | 100 Mbit/s |
| Roll-off Factor | 0.3 |
| RF Bandwidth | 130 MHz |

---

### Payload (Spacecraft and Ground Station)

| Parameter | Value |
|-----------|---------|
| Transmit Power | 24.98 dBm |
| Antenna Effective Gain | 38 dBi |
| Antenna Effective Gain Sweep | 69–75 dBi |
| Environment Noise Temp | 300 K |
| Receiver Equivalent Noise Temp | 1163 K |
| Feeding Network Loss | 2.48 dB |
| Radome Loss (guesstimate) | 1.50 dB |
| Implementation Loss | 1.15 dB |


