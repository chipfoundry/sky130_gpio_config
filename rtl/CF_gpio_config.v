//=============================================================================
// Module: CF_gpio_config
// Description: Sky130 GPIO Pad Configuration Wrapper for Efabless Openframe
//              Simple parameterized module - set MODE and forget about pad details
// License: Apache 2.0
//=============================================================================

`default_nettype none

module CF_gpio_config #(
  parameter [2:0] MODE = 3'd1  // 0=ANALOG, 1=INPUT, 2=INPUT_PD, 3=INPUT_PU, 4=OUTPUT, 5=BIDIR
)(
  //-------------------------------------------------------------------------
  // User Interface - Connect these to your design
  //-------------------------------------------------------------------------
  input  wire        io_out,       // Data to drive pad (used in OUTPUT/BIDIR modes)
  output wire        io_in,        // Data from pad (directly from gpio_in)
  input  wire        io_oeb,       // Output enable bar (BIDIR mode: 0=drive, 1=hi-z)
  input  wire        analog,       // {analog_sel, analog_pol} for ANALOG mode

  //-------------------------------------------------------------------------
  // Openframe Interface - From openframe_project_wrapper
  //-------------------------------------------------------------------------
  input  wire        gpio_in,      // Pad input (connect to gpio_in[n])

  //-------------------------------------------------------------------------
  // Openframe Interface - To openframe_project_wrapper pad config
  //-------------------------------------------------------------------------
  output wire [2:0]  gpio_dm,      // Drive mode {dm2, dm1, dm0}
  output wire        gpio_inp_dis, // Input disable
  output wire        gpio_oeb_out, // Output enable bar (active low)
  output wire        gpio_out_val, // Output value for gpio_out (includes pull mode values)
  output wire        gpio_analog_en,
  output wire        gpio_analog_sel,
  output wire        gpio_analog_pol,
  output wire        gpio_ib_mode_sel,
  output wire        gpio_vtrip_sel,
  output wire        gpio_slow_sel,
  output wire        gpio_holdover
);

  //-------------------------------------------------------------------------
  // Mode Definitions
  //-------------------------------------------------------------------------
  localparam [2:0] MODE_ANALOG   = 3'd0;  // Analog mode - input/output disabled
  localparam [2:0] MODE_INPUT    = 3'd1;  // Digital input, no pull resistor
  localparam [2:0] MODE_INPUT_PD = 3'd2;  // Digital input with pull-down
  localparam [2:0] MODE_INPUT_PU = 3'd3;  // Digital input with pull-up
  localparam [2:0] MODE_OUTPUT   = 3'd4;  // Digital output, push-pull
  localparam [2:0] MODE_BIDIR    = 3'd5;  // Bidirectional, direction from io_oeb

  //-------------------------------------------------------------------------
  // Drive Mode (dm[2:0]) - Based on Sky130 pad behavioral model
  //-------------------------------------------------------------------------
  // The Sky130 GPIO pad uses bufif1 primitives with specific strengths:
  //   dm=010: bufif1(pull1, strong0) - weak 1, strong 0
  //   dm=011: bufif1(strong1, pull0) - strong 1, weak 0
  //
  // For weak pull behavior:
  //   - Pull-DOWN (read 0 when floating): dm=011 with out=0 gives weak pull to 0
  //   - Pull-UP (read 1 when floating):   dm=010 with out=1 gives weak pull to 1
  //
  // MODE_ANALOG:   dm=000 (Hi-Z, analog mode)
  // MODE_INPUT:    dm=001 (Input only, no pull)
  // MODE_INPUT_PD: dm=011 (Weak pull to 0, requires oeb=0 and out=0)
  // MODE_INPUT_PU: dm=010 (Weak pull to 1, requires oeb=0 and out=1)
  // MODE_OUTPUT:   dm=110 (Strong push-pull)
  // MODE_BIDIR:    dm=110 (Strong push-pull, direction from io_oeb)
  //-------------------------------------------------------------------------
  assign gpio_dm = (MODE == MODE_ANALOG)   ? 3'b000 :
                   (MODE == MODE_INPUT)    ? 3'b001 :
                   (MODE == MODE_INPUT_PD) ? 3'b011 :  // Weak 0 (pull-down)
                   (MODE == MODE_INPUT_PU) ? 3'b010 :  // Weak 1 (pull-up)
                   (MODE == MODE_OUTPUT)   ? 3'b110 :
                   (MODE == MODE_BIDIR)    ? 3'b110 : 3'b001;  // Default: INPUT

  //-------------------------------------------------------------------------
  // Input Disable
  //-------------------------------------------------------------------------
  // Disable input buffer for ANALOG and OUTPUT modes (not reading pad)
  assign gpio_inp_dis = (MODE == MODE_ANALOG) || (MODE == MODE_OUTPUT);

  //-------------------------------------------------------------------------
  // Output Enable Bar (active low: 0=driving, 1=hi-z)
  //-------------------------------------------------------------------------
  // OUTPUT:   always driving (oeb=0)
  // BIDIR:    controlled by user's io_oeb signal
  // INPUT_PD: must drive to enable weak pull (oeb=0)
  // INPUT_PU: must drive to enable weak pull (oeb=0)
  // Others:   always hi-z (oeb=1)
  assign gpio_oeb_out = (MODE == MODE_OUTPUT)   ? 1'b0 :
                        (MODE == MODE_BIDIR)    ? io_oeb :
                        (MODE == MODE_INPUT_PD) ? 1'b0 :  // Enable weak pull driver
                        (MODE == MODE_INPUT_PU) ? 1'b0 :  // Enable weak pull driver
                        1'b1;

  //-------------------------------------------------------------------------
  // Fixed Configuration (safe defaults for all modes)
  //-------------------------------------------------------------------------
  assign gpio_analog_en   = 1'b0;  // Enable amuxbus_a/b for ground/power
  assign gpio_analog_sel  = 1'b0;  // Choose amuxbus_a (0) or amuxbus_b (1)
  assign gpio_analog_pol  = 1'b0;  // Use amuxbus_a/b as ground (0) or power (1)
  assign gpio_ib_mode_sel = 1'b0;  // Input buffer mode: VDDIO
  assign gpio_vtrip_sel   = 1'b0;  // Trip point: CMOS
  assign gpio_slow_sel    = 1'b0;  // Slew rate: fast
  assign gpio_holdover    = 1'b0;  // No holdover

  //-------------------------------------------------------------------------
  // Output Value
  //-------------------------------------------------------------------------
  // For pull modes, drive the correct value to activate weak pull:
  //   INPUT_PD: out=0 to get weak pull to 0
  //   INPUT_PU: out=1 to get weak pull to 1
  // For OUTPUT/BIDIR: pass through user's io_out
  // For others: drive 0 (doesn't matter since oeb=1)
  assign gpio_out_val = (MODE == MODE_OUTPUT)   ? io_out :
                        (MODE == MODE_BIDIR)    ? io_out :
                        (MODE == MODE_INPUT_PD) ? 1'b0 :  // Drive 0 for weak pull-down
                        (MODE == MODE_INPUT_PU) ? 1'b1 :  // Drive 1 for weak pull-up
                        1'b0;

  //-------------------------------------------------------------------------
  // Input Passthrough
  //-------------------------------------------------------------------------
  assign io_in = gpio_in;

endmodule

`default_nettype wire
