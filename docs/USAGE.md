# Usage Guide

## Overview

`CF_gpio_config` is a simple parameterized wrapper that configures Sky130 GPIO pads for Efabless Openframe projects. You set the `MODE` parameter at instantiation, and the module generates all the required pad configuration signals.

## Basic Usage

### Step 1: Add RTL to your project

Include `rtl/CF_gpio_config.v` in your design.

### Step 2: Instantiate one module per GPIO

```verilog
CF_gpio_config #(
  .MODE(3'd4)  // OUTPUT mode
) gpio_inst (
  // User interface
  .io_out(my_output_data),
  .io_in(),                    // Unused for OUTPUT
  .io_oeb(1'b0),               // Unused for OUTPUT
  .analog(2'b00),              // Unused for OUTPUT
  
  // From openframe
  .gpio_in(gpio_in[N]),
  
  // To openframe pad config
  .gpio_dm({gpio_dm2[N], gpio_dm1[N], gpio_dm0[N]}),
  .gpio_inp_dis(gpio_inp_dis[N]),
  .gpio_oeb_out(gpio_oeb[N]),
  .gpio_out_val(gpio_out[N]),  // Connects directly - handles output data and pull values
  .gpio_analog_en(gpio_analog_en[N]),
  .gpio_analog_sel(gpio_analog_sel[N]),
  .gpio_analog_pol(gpio_analog_pol[N]),
  .gpio_ib_mode_sel(gpio_ib_mode_sel[N]),
  .gpio_vtrip_sel(gpio_vtrip_sel[N]),
  .gpio_slow_sel(gpio_slow_sel[N]),
  .gpio_holdover(gpio_holdover[N])
);
```

### Step 3: Choose the right MODE

| MODE | Use case |
|------|----------|
| `3'd0` (ANALOG) | ADC input, capacitive sensing, analog passthrough |
| `3'd1` (INPUT) | External signal input, no pull resistor needed |
| `3'd2` (INPUT_PD) | Button with external pull-up, or default-low input |
| `3'd3` (INPUT_PU) | Button with external pull-down, or default-high input |
| `3'd4` (OUTPUT) | Driving LEDs, signals, always output |
| `3'd5` (BIDIR) | I2C, bidirectional buses, tri-state capable |

## Mode Examples

### OUTPUT Mode (MODE=4)

For driving outputs like LEDs or control signals:

```verilog
wire led_data;

CF_gpio_config #(.MODE(3'd4)) gpio_led (
  .io_out(led_data),
  .io_in(),
  .io_oeb(1'b0),
  .analog(2'b00),
  .gpio_in(gpio_in[10]),
  .gpio_out_val(gpio_out[10]),  // gpio_out_val passes through io_out
  // ... other config outputs
);
```

### INPUT with Pull-Up (MODE=3)

For buttons that pull low when pressed:

```verilog
wire button_pressed;

CF_gpio_config #(.MODE(3'd3)) gpio_button (
  .io_out(1'b0),             // Unused - wrapper drives 1 for pull-up
  .io_in(button_pressed),    // Will be 1 when idle, 0 when pressed
  .io_oeb(1'b1),             // Unused - wrapper drives oeb=0 to enable weak pull
  .analog(2'b00),
  .gpio_in(gpio_in[11]),
  .gpio_out_val(gpio_out[11]),  // Drives 1 to activate ~5kΩ pull-up
  // ... other config outputs
);
```

**Note:** For pull modes (INPUT_PD/INPUT_PU), the wrapper automatically:
- Sets `oeb=0` to enable the output driver in weak mode
- Sets `gpio_out_val` to the correct value (0 for pull-down, 1 for pull-up)
- The input buffer remains enabled so you can read the pad value

### BIDIR Mode (MODE=5)

For bidirectional buses like I2C SDA:

```verilog
wire sda_out;
wire sda_in;
wire sda_oeb;  // 0 = driving, 1 = reading

CF_gpio_config #(.MODE(3'd5)) gpio_sda (
  .io_out(sda_out),
  .io_in(sda_in),
  .io_oeb(sda_oeb),
  .analog(2'b00),
  .gpio_in(gpio_in[12]),
  .gpio_out_val(gpio_out[12]),  // Passes through sda_out
  // ... other config outputs
);
```

### ANALOG Mode (MODE=0)

For analog functions:

```verilog
wire [1:0] analog_config;  // {sel, pol}

CF_gpio_config #(.MODE(3'd0)) gpio_analog (
  .io_out(1'b0),
  .io_in(),
  .io_oeb(1'b1),
  .analog(analog_config),
  .gpio_in(gpio_in[13]),
  // ... config outputs
);
```

## Multiple GPIOs with Generate

For arrays of GPIOs with the same mode:

```verilog
genvar i;
generate
  for (i = 0; i < 8; i = i + 1) begin : gpio_outputs
    CF_gpio_config #(.MODE(3'd4)) gpio_inst (
      .io_out(my_outputs[i]),
      .io_in(),
      .io_oeb(1'b0),
      .analog(2'b00),
      .gpio_in(gpio_in[i+10]),
      .gpio_dm({gpio_dm2[i+10], gpio_dm1[i+10], gpio_dm0[i+10]}),
      .gpio_inp_dis(gpio_inp_dis[i+10]),
      .gpio_oeb_out(gpio_oeb[i+10]),
      .gpio_out_val(gpio_out[i+10]),
      .gpio_analog_en(gpio_analog_en[i+10]),
      .gpio_analog_sel(gpio_analog_sel[i+10]),
      .gpio_analog_pol(gpio_analog_pol[i+10]),
      .gpio_ib_mode_sel(gpio_ib_mode_sel[i+10]),
      .gpio_vtrip_sel(gpio_vtrip_sel[i+10]),
      .gpio_slow_sel(gpio_slow_sel[i+10]),
      .gpio_holdover(gpio_holdover[i+10])
    );
  end
endgenerate
```

## Important Notes

1. **gpio_out_val output**: The wrapper provides `gpio_out_val` which should be connected to `gpio_out[N]`. This output automatically handles:
   - Passing through `io_out` for OUTPUT and BIDIR modes
   - Driving the correct value for pull resistor activation (0 for pull-down, 1 for pull-up)

2. **Pure combinational**: The wrapper is purely combinational (no clocks, no flip-flops). The `io_in` output is a direct passthrough from `gpio_in`.

3. **No runtime reconfiguration**: The MODE is set at synthesis time via parameter. If you need runtime mode changes, use the register-based core instead.

4. **Pull resistor implementation**: The Sky130 GPIO pad implements pull resistors using weak output drivers. This is why INPUT_PD and INPUT_PU modes have `oeb=0` - the output driver must be enabled in weak mode to provide the pull.
