`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2020 01:22:36 AM
// Design Name: 
// Module Name: win_graphics
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module win_graphics(
    input clk,
    input reset,

//    output logic play,
//    output logic stop,
//    output logic [4:0] sound_id,

    output logic should_render,
    output logic render_dirty,
    output logic [7:0] num_objects,
    output logic [7:0] new_object_waddr,
    output logic new_object_we,
    output logic [35:0] new_object_properties,
    input render_ack,

    output logic [7:0] texturemap_id,
    output logic should_load_texturemap,
    input texturemap_load_ack,

    input confirm,

    output logic confirmed
);

    assign confirmed = confirm;

    // GRAPHICS CODE
    logic [0:0] to_draw;

    localparam BLINK_DELAY = 12_000_000;    // approx half a second
    logic [31:0] blink_counter;
    logic blink, blink_last;    // if HIGH, show the cursor
    always_ff @(posedge clk) begin
        blink_last <= blink;

        if (reset) begin
            blink_counter <= BLINK_DELAY;
            blink <= 1'b1;
        end else begin
            if (!blink_counter) begin
                blink_counter <= BLINK_DELAY;
                blink <= ~blink;
            end else begin
                blink_counter <= blink_counter - 1;
            end
        end
    end

    localparam FIRST_BACKGROUND_TEXTUREMAP = 11;

    logic [2:0] backgrounds_loaded;
    logic [1:0] background_state, background_state_last;

    always_ff @(posedge clk) begin
        background_state_last <= background_state;
    end

    localparam BACKGROUND_STATE_WAITING = 2'b00;
    localparam BACKGROUND_STATE_LOADING_TEXTUREMAP = 2'b01;
    localparam BACKGROUND_STATE_RENDERING = 2'b10;
    // we need to load the bg, then wait for an ack
    logic background_should_render;
    logic background_should_load_texturemap;

    logic texturemap_loaded;    // have we loaded the texturemap yet?
    logic texturemap_ready;    // has the texturemap been fully loaded?
    localparam TEXTUREMAP_ID = 15;

    // handle background state
    always_ff @(posedge clk) begin
        if (reset) begin
            backgrounds_loaded <= 3'd0;
            background_state <= BACKGROUND_STATE_WAITING;
        end else if (backgrounds_loaded < 4) begin
            // load backgrounds
            case (background_state)
                BACKGROUND_STATE_WAITING: begin
                    background_state <= BACKGROUND_STATE_LOADING_TEXTUREMAP;
                end

                BACKGROUND_STATE_LOADING_TEXTUREMAP: begin
                    if (texturemap_load_ack) begin
                        background_state <= BACKGROUND_STATE_RENDERING;
                    end
                end

                BACKGROUND_STATE_RENDERING: begin
                    if (render_ack) begin
                        backgrounds_loaded <= backgrounds_loaded + 1;
                        background_state <= BACKGROUND_STATE_LOADING_TEXTUREMAP;
                    end
                end
            endcase
        end
    end

    // load the right texturemap!
    always_ff @(posedge clk) begin
        if (should_load_texturemap) should_load_texturemap <= 0;    // should be a pulse

        if (reset) begin
            texturemap_loaded <= 1'b0;
            texturemap_ready <= 1'b0;

            should_load_texturemap <= 1'b0;
        end else if (backgrounds_loaded < 4) begin
            if (background_state == BACKGROUND_STATE_LOADING_TEXTUREMAP &&
                background_state != background_state_last) begin
                texturemap_id <= FIRST_BACKGROUND_TEXTUREMAP + backgrounds_loaded;
                should_load_texturemap <= 1'b1;
            end
        end else begin
            if (!texturemap_loaded) begin
                // TODO THIS SHOULD BE THE TEXTUREMAP YOU WANT
                texturemap_id <= TEXTUREMAP_ID;
                texturemap_loaded <= 1'b1;
                texturemap_ready <= 1'b0;

                should_load_texturemap <= 1'b1;
            end else if (texturemap_load_ack) begin
                texturemap_ready <= 1'b1;
            end
        end
    end

    // configuration stuff
//    assign render_dirty = 1'b0;
    assign render_dirty = 1'b1;
//    assign num_objects = 8'd2;

    // draw things!
    always_ff @(posedge clk) begin
        if (new_object_we) new_object_we <= 0;
        if (should_render) should_render <= 0;

        if (reset) begin
            to_draw <= 1'b1;
        end else if (backgrounds_loaded < 4) begin
            num_objects <= 1;

            if (background_state == BACKGROUND_STATE_RENDERING &&
                background_state != background_state_last) begin
                new_object_we <= 1;
                new_object_waddr <= 0;
                new_object_properties <= {backgrounds_loaded[0] ? 10'd320 : 10'd0, backgrounds_loaded[1] ? 10'd240 : 10'd0, 10'h2FF, 4'h00, backgrounds_loaded[1:0]};
                should_render <= 1'b1;
            end
        end else begin
            num_objects <= 1;
            if (blink != blink_last) begin
                to_draw <= 1'b1;
            end else if (to_draw && texturemap_ready) begin
                new_object_we <= 1;
                should_render <= 1'b1;

                new_object_waddr <= 0;
                new_object_properties <= {10'd441, 10'd365, 10'h2FF, blink ? 6'h00: 6'h01};
                to_draw <= 0;
            end
        end
    end

endmodule
