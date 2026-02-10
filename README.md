# GPIO Configuration for OpenFrame

A simple parameterized GPIO pad configuration wrapper for ChipFoundry Openframe projects.

**Set the mode once, forget about pad details.**

## Quick Start

```verilog
// GPIO as OUTPUT
CF_gpio_config #(.MODE(3'd4)) gpio_out_inst (
  .io_out(my_data_out),
  .io_in(),
  .io_oeb(),
  .gpio_zero(gpio_loopback_zero[5]),
  .gpio_one(gpio_loopback_one[5]),
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
CF_gpio_config #(.MODE(3'd3)) gpio_in_inst (
  .io_out(),
  .io_in(my_data_in),
  .io_oeb(),
  .gpio_zero(gpio_loopback_zero[6]),
  .gpio_one(gpio_loopback_one[6]),
  .gpio_in(gpio_in[6]),
  // ... connect config outputs (including gpio_out_val for pull-up)
);
```

## Modes

| MODE | Name | dm | oeb | Description |
|------|------|----|-----|-------------|
| 0 | ANALOG | 000 | 1 | Analog mode - disables input and output buffers |
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

## Openframe Interface

Connect these to your `openframe_project_wrapper` signals:

| Signal | Connect to |
|--------|------------|
| `gpio_zero` | `gpio_loopback_zero[n]` |
| `gpio_one` | `gpio_loopback_one[n]` |
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
CF_gpio_config/
  rtl/
    CF_gpio_config.v   # Main wrapper module
  docs/
    USAGE.md               # Detailed usage guide
    SIGNAL_MAPPING.md      # Mode-to-signal reference
  README.md                # This file
  LICENSE                  # Apache 2.0
```

## License

Apache 2.0 - See [LICENSE](LICENSE)
