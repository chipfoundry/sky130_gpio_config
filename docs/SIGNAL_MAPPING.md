# Signal Mapping Reference

## Mode-to-Signal Truth Table

| MODE | Name | dm[2:0] | inp_dis | oeb | out_val | analog_en | analog_sel | analog_pol |
|------|------|---------|---------|-----|---------|-----------|------------|------------|
| 0 | ANALOG | 000 | 1 | 1 | 0 | 1 | analog[1] | analog[0] |
| 1 | INPUT | 001 | 0 | 1 | 0 | 0 | 0 | 0 |
| 2 | INPUT_PD | 011 | 0 | 0 | 0 | 0 | 0 | 0 |
| 3 | INPUT_PU | 010 | 0 | 0 | 1 | 0 | 0 | 0 |
| 4 | OUTPUT | 110 | 1 | 0 | io_out | 0 | 0 | 0 |
| 5 | BIDIR | 110 | 0 | io_oeb | io_out | 0 | 0 | 0 |

**Note on pull modes (INPUT_PD, INPUT_PU):** The Sky130 GPIO pad requires `oeb=0` (output enabled) with the appropriate `dm` and `out_val` settings to activate the weak pull resistors. This is because the pull behavior comes from the output driver stage operating in a weak drive mode.

## Fixed Configuration Signals

These signals are set to safe defaults for all modes:

| Signal | Value | Description |
|--------|-------|-------------|
| `gpio_ib_mode_sel` | 0 | Input buffer mode: VDDIO |
| `gpio_vtrip_sel` | 0 | Trip point: CMOS |
| `gpio_slow_sel` | 0 | Slew rate: fast |
| `gpio_holdover` | 0 | No holdover |

## Sky130 Drive Mode Reference

The `dm[2:0]` signal controls the Sky130 pad's output driver. The Sky130 GPIO uses `bufif1` primitives with specific drive strengths:

| dm[2:0] | Description | Effect with oeb=0 | Use |
|---------|-------------|-------------------|-----|
| 000 | Hi-Z | Disabled | Analog mode |
| 001 | Input only | No output driver | Digital input, no pull |
| 010 | pull1, strong0 | out=1 gives weak pull-up | INPUT_PU (with oeb=0, out=1) |
| 011 | strong1, pull0 | out=0 gives weak pull-down | INPUT_PD (with oeb=0, out=0) |
| 110 | strong1, strong0 | Strong push-pull | OUTPUT, BIDIR |

**How pull resistors work:**
- **Pull-UP (INPUT_PU):** dm=010, oeb=0, out=1 → weak drive to 1 (~5kΩ pull-up)
- **Pull-DOWN (INPUT_PD):** dm=011, oeb=0, out=0 → weak drive to 0 (~5kΩ pull-down)

## Signal Descriptions

### User Interface Signals

| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| `io_out` | 1 | input | Data to drive the pad. Connect your output signal here. |
| `io_in` | 1 | output | Data from the pad. Direct passthrough from gpio_in. |
| `io_oeb` | 1 | input | Output enable bar. Only used in BIDIR mode. 0=drive, 1=hi-z. |
| `analog` | 2 | input | Analog configuration {sel, pol}. Only used in ANALOG mode. |

### Openframe Interface Signals

| Signal | Width | Direction | Connect to |
|--------|-------|-----------|------------|
| `gpio_in` | 1 | input | `gpio_in[n]` from openframe_project_wrapper |
| `gpio_dm` | 3 | output | `{gpio_dm2[n], gpio_dm1[n], gpio_dm0[n]}` |
| `gpio_inp_dis` | 1 | output | `gpio_inp_dis[n]` |
| `gpio_oeb_out` | 1 | output | `gpio_oeb[n]` |
| `gpio_analog_en` | 1 | output | `gpio_analog_en[n]` |
| `gpio_analog_sel` | 1 | output | `gpio_analog_sel[n]` |
| `gpio_analog_pol` | 1 | output | `gpio_analog_pol[n]` |
| `gpio_ib_mode_sel` | 1 | output | `gpio_ib_mode_sel[n]` |
| `gpio_vtrip_sel` | 1 | output | `gpio_vtrip_sel[n]` |
| `gpio_slow_sel` | 1 | output | `gpio_slow_sel[n]` |
| `gpio_holdover` | 1 | output | `gpio_holdover[n]` |

## Mode Behavior Details

### ANALOG (MODE=0)

- Digital input buffer disabled (`inp_dis=1`)
- Digital output buffer disabled (`oeb=1`, `dm=000`)
- Analog path enabled (`analog_en=1`)
- Pad connected to AMUXBUS via `analog_sel` (0=AMUXBUS_A, 1=AMUXBUS_B)
- Polarity controlled by `analog_pol`

### INPUT (MODE=1)

- Digital input buffer enabled (`inp_dis=0`)
- No output driver (`oeb=1`)
- No pull resistor (`dm=001`)
- Pad floats when not driven externally

### INPUT_PD (MODE=2)

- Digital input buffer enabled (`inp_dis=0`)
- Output driver enabled for weak pull (`oeb=0`, `out=0`)
- Drive mode set for weak 0 (`dm=011`)
- Pad defaults low (~5kΩ pull-down) when not driven externally

### INPUT_PU (MODE=3)

- Digital input buffer enabled (`inp_dis=0`)
- Output driver enabled for weak pull (`oeb=0`, `out=1`)
- Drive mode set for weak 1 (`dm=010`)
- Pad defaults high (~5kΩ pull-up) when not driven externally

### OUTPUT (MODE=4)

- Digital input buffer disabled (`inp_dis=1`)
- Strong push-pull driver (`dm=110`, `oeb=0`)
- Always driving based on `io_out`

### BIDIR (MODE=5)

- Digital input buffer always enabled (`inp_dis=0`)
- Strong push-pull driver when enabled (`dm=110`)
- Direction controlled by `io_oeb`:
  - `io_oeb=0`: Driving pad with `io_out`
  - `io_oeb=1`: Hi-Z, reading pad via `io_in`
