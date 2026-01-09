// Fixed version of SmartTrafficLight with corrections
module traffic_ctrl(  // Changed from SmartTrafficLight to match spec
    input clk,
    input rst,        // Now active-high synchronous reset
    input VS,
    input PB,
    output [2:0] light_main,  // {RED,YEL,GRN}
    output [2:0] light_side,  // {RED,YEL,GRN}
    output walk
);

    reg [6:0] state;

    // State encoding (output encoding)
    parameter GRR = 7'b0011000;  // Main Green
    parameter YRR = 7'b0101000;  // Main Yellow
    parameter RRR1 = 7'b1001000; // All Red 1 (main->side/ped)
    parameter RGR = 7'b1000010;  // Side Green
    parameter RYR = 7'b1000100;  // Side Yellow
    parameter RRG = 7'b1001001;  // Pedestrian Walk
    parameter RRR2 = 7'b1001000; // All Red 2 (side->main)

    reg [7:0] timer_limit;
    reg [7:0] timer;
    reg PB_queued;

    assign {light_main, light_side, walk} = state;

    // Timer logic
    always @(posedge clk) begin  // Changed to synchronous
        if (rst)
            timer <= 0;
        else if (timer >= timer_limit - 1)  // Fixed off-by-one
            timer <= 0;
        else
            timer <= timer + 1;
    end

    // Timer limit based on state
    always @(*) begin
        case (state)
            GRR:    timer_limit = 60;
            YRR:    timer_limit = 5;
            RRR1:   timer_limit = 2;   // Fixed: was 40
            RGR:    timer_limit = 40;
            RYR:    timer_limit = 5;
            RRG:    timer_limit = 40;  // Fixed: was using default 5
            RRR2:   timer_limit = 2;   // Fixed: separate state
            default: timer_limit = 5;
        endcase
    end

    // Pedestrian request queuing
    always @(posedge clk) begin  // Changed to synchronous
        if (rst)
            PB_queued <= 1'b0;
        else begin
            if (PB)
                PB_queued <= 1'b1;
            else if (state == RRG)
                PB_queued <= 1'b0;  // Clear after pedestrian walk
        end
    end

    // State machine
    always @(posedge clk) begin  // Changed to synchronous
        if (rst)
            state <= GRR;
        else if (timer >= timer_limit - 1) begin  // Fixed off-by-one
            case (state)
                GRR: begin
                    // Stay green if no requests (FIXED)
                    if (VS || PB || PB_queued)
                        state <= YRR;
                    else
                        state <= GRR;  // Stay green
                end

                YRR:    state <= RRR1;

                RRR1: begin
                    // Priority for pedestrian
                    if (PB_queued || PB)
                        state <= RRG;
                    else if (VS)
                        state <= RGR;
                    else
                        state <= GRR;  // No requests, back to main
                end

                RGR:    state <= RYR;
                RYR:    state <= RRR2;   // Go to second all-red (FIXED)
                RRG:    state <= RYR;    // After pedestrian, go to side yellow
                RRR2:   state <= GRR;    // Back to main green (FIXED)

                default: state <= GRR;
            endcase
        end
    end

endmodule
