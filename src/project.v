/*
 * Copyright (c) 2024 Henry Blount
 * SPDX-License-Identifier: Apache-2.0
 */
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
