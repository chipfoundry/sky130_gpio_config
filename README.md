# Sky130 GPIO Config

A simple parameterized GPIO pad configuration wrapper for ChipFoundry Openframe projects.

**Set the mode once, forget about pad details.**

## Quick Start

```verilog
// GPIO as OUTPUT
sky130_gpio_config #(.MODE(3'd4)) gpio_out_inst (
  .io_out(my_data_out),
  .io_in(),
  .io_oeb(1'b0),
  .analog(2'b00),
  .gpio_in(gpio_in[5]),
  .gpio_dm({gpio_dm2[5], gpio_dm1[5], gpio_dm0[5]}),
  .gpio_inp_dis(gpio_inp_dis[5]),
  .gpio_oeb_out(gpio_oeb[5]),
  .gpio_out_val(gpio_out[5]),
  .gpio_analog_en(gpio_analog_en[5]),
  .gpio_analog_sel(gpio_analog_sel[5]),
  .gpio_analog_pol(gpio_analog_pol[5]),
  .gpio_ib_mode_sel(gpio_ib_mode_sel[5]),
  .gpio_vtrip_sel(gpio_vtrip_sel[5]),
  .gpio_slow_sel(gpio_slow_sel[5]),
  .gpio_holdover(gpio_holdover[5])
);

// GPIO as INPUT with pull-up
sky130_gpio_config #(.MODE(3'd3)) gpio_in_inst (
  .io_out(1'b0),
  .io_in(my_data_in),
  .io_oeb(1'b1),
  .analog(2'b00),
  .gpio_in(gpio_in[6]),
  // ... connect config outputs (including gpio_out_val for pull-up)
);
```

## Modes

| MODE | Name | dm | oeb | Description |
|------|------|----|-----|-------------|
| 0 | ANALOG | 000 | 1 | Analog mode - connects pad to AMUXBUS |
| 1 | INPUT | 001 | 1 | Digital input, no pull resistor (floating) |
| 2 | INPUT_PD | 011 | 0 | Digital input with pull-down (~5kΩ) |
| 3 | INPUT_PU | 010 | 0 | Digital input with pull-up (~5kΩ) |
| 4 | OUTPUT | 110 | 0 | Digital output, push-pull driver |
| 5 | BIDIR | 110 | io_oeb | Bidirectional - direction controlled by io_oeb |

## User Interface

| Signal | Direction | Description |
|--------|-----------|-------------|
| `io_out` | input | Data to drive the pad (OUTPUT/BIDIR modes) |
| `io_in` | output | Data from the pad |
| `io_oeb` | input | Output enable bar (BIDIR: 0=drive, 1=hi-z) |
| `analog[1:0]` | input | {analog_sel, analog_pol} for ANALOG mode |

## Openframe Interface

Connect these to your `openframe_project_wrapper` signals:

| Signal | Connect to |
|--------|------------|
| `gpio_in` | `gpio_in[n]` |
| `gpio_dm[2:0]` | `{gpio_dm2[n], gpio_dm1[n], gpio_dm0[n]}` |
| `gpio_inp_dis` | `gpio_inp_dis[n]` |
| `gpio_oeb_out` | `gpio_oeb[n]` |
| `gpio_out_val` | `gpio_out[n]` |
| `gpio_analog_en` | `gpio_analog_en[n]` |
| `gpio_analog_sel` | `gpio_analog_sel[n]` |
| `gpio_analog_pol` | `gpio_analog_pol[n]` |
| `gpio_ib_mode_sel` | `gpio_ib_mode_sel[n]` |
| `gpio_vtrip_sel` | `gpio_vtrip_sel[n]` |
| `gpio_slow_sel` | `gpio_slow_sel[n]` |
| `gpio_holdover` | `gpio_holdover[n]` |

**Note:** The `gpio_out_val` output handles both user data and pull-mode values automatically:
- For OUTPUT/BIDIR modes: passes through your `io_out` signal
- For INPUT_PD: drives 0 to activate weak pull-down
- For INPUT_PU: drives 1 to activate weak pull-up

## Files

```
sky130_gpio_config/
  rtl/
    sky130_gpio_config.v   # Main wrapper module
  docs/
    USAGE.md               # Detailed usage guide
    SIGNAL_MAPPING.md      # Mode-to-signal reference
  README.md                # This file
  LICENSE                  # Apache 2.0
```

## License

Apache 2.0 - See [LICENSE](LICENSE)
