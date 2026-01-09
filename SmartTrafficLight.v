module SmartTrafficLight(
    input clk, rst,
    input VS, PB,
    output [2:0] light_main,  // {RED,YEL,GRN}
    output [2:0] light_side,  // {RED,YEL,GRN}
    output walk
);

    reg [6:0] state;

    parameter GRR = 7'b0011000;
    parameter YRR = 7'b0101000;
    parameter RRR = 7'b1001000;
    parameter RGR = 7'b1000010;
    parameter RYR = 7'b1000100;
    parameter RRG = 7'b1001001;

    reg [7:0] timer_limit;
    reg [7:0] timer;
    reg PB_queued;

    assign {light_main, light_side, walk} = state;

    always @(posedge clk, negedge rst) begin
        if (!rst)
            timer <= 0;
        else if (timer >= timer_limit)
            timer <= 0;
        else
            timer <= timer + 1;
    end

    always @(*) begin
        case (state)
            GRR: timer_limit = 60;
            RGR: timer_limit = 40;
            RRR: timer_limit = 40;
            default: timer_limit = 5;
        endcase
    end

    always @(posedge clk, negedge rst) begin
        if (!rst)
            PB_queued <= 1'b0;
        else begin
            if (PB)
                PB_queued <= 1'b1;
            else if (state == RRG)
                PB_queued <= 1'b0;   // clear if after pedestrian walk
        end
    end

    always @(posedge clk, negedge rst) begin
        if (!rst)
            state <= GRR;
        else if (timer >= timer_limit) begin   // for all cases if timer is less than the limit no change
            case (state)
                GRR: state <= YRR;
                YRR: state <= RRR;
                RRR: begin
                    if (PB_queued || PB)
                        state <= RRG;        // priority for pedestrian
                    else if (VS)
                        state <= RGR;
                    else
                        state <= GRR;        // VS =0 && PB =0
                end

                RGR: state <= RYR;
                RYR: state <= RRR;
                RRG: state <= RRR;
                default: state <= GRR;
            endcase
        end
    end
endmodule
