/*
 * Copyright (c) 2024 Henry Blount
 * SPDX-License-Identifier: Apache-2.0
*/

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
// All output pins must be assigned. If not used, assign to 0.
assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
assign uio_out = 0;
assign uio_oe  = 0;

// List all unused inputs to prevent warnings
wire _unused = &{ena, clk, rst_n, 1'b0};
	
endmodule

module top (
    input clk,
    input pwm_in, //50Hz PWM input
    input start, 
    input tlm, //Telemetry 
    output reg serial_out, //16bit D-Shot Frame
    output reg busy
);


    // PWM Pulse Width measurement
    reg [15:0] counter;
    reg [15:0] width;
    reg prev;

    // PWM to Throttle mapping
    reg [15:0] throttle;

    always @(posedge clk) begin
        prev <= pwm_in;

        counter <= counter + 16'd1;

        // rising edge → reset counter
        if (pwm_in && !prev)
            counter <= 16'd0;

        // falling edge → latch width
        if (!pwm_in && prev)
            width <= counter;
    end

    always @(*) begin
      
	// clamping
        if (width <= 16'd1000)
            throttle = 16'd48;

        else if (width >= 16'd2000)
            throttle = 16'd2047;

        else
            throttle = (width << 1) - 16'd1952;
    end
    // 16-Bit D-Shot Frame Construction
    reg [15:0] frame;
    reg [11:0] crc_input;
    reg [11:0] crc;
    always @(*) begin
        crc_input = {throttle[10:0], tlm};
        crc = crc_input ^ (crc_input >> 4) ^ (crc_input >> 8);
        frame = {throttle[10:0], tlm, crc[3:0]};
    end

    // Serializer-MSB first
    reg [15:0] shift;
    reg [4:0] bitcount;

    always @(posedge clk) begin

        if (start && !busy) begin
            shift <= frame;
            bitcount <= 5'd16;
            busy <= 1'b1;
        end

        if (busy) begin
            serial_out <= shift[15];
            shift <= shift << 1;
            bitcount <= bitcount - 5'd1;

            if (bitcount == 5'd1)
                busy <= 1'b0;
        end
    end

endmodule
