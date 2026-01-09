// Smart Traffic Light Controller with Pedestrian Request
// FSM-based traffic light controller for main road, side road, and pedestrian crossing

module traffic_ctrl(
    input clk,
    input rst,
    input VS,              // Vehicle Sensor on side road
    input PB,              // Pedestrian Button
    output reg [2:0] light_main,  // {RED, YELLOW, GREEN}
    output reg [2:0] light_side,  // {RED, YELLOW, GREEN}
    output reg walk               // Pedestrian walk signal (1=GREEN, 0=RED)
);

    // State encoding
    localparam M_GREEN    = 3'b000;  // Main green, side red
    localparam M_YELLOW   = 3'b001;  // Main yellow, side red
    localparam ALL_RED_1  = 3'b010;  // Transition: all red (main->side/ped)
    localparam S_GREEN    = 3'b011;  // Side green, main red
    localparam P_WALK     = 3'b100;  // Pedestrian walk, all red
    localparam S_YELLOW   = 3'b101;  // Side yellow, main red
    localparam ALL_RED_2  = 3'b110;  // Transition: all red (side->main)

    // Timing parameters (in clock cycles)
    localparam M_GREEN_MIN = 60;  // Minimum time for main green
    localparam YELLOW_TIME = 5;   // Yellow light duration
    localparam ALL_RED_TIME = 2;  // All-red safety buffer
    localparam SIDE_TIME = 40;    // Side green duration
    localparam PED_TIME = 40;     // Pedestrian walk duration

    // State registers
    reg [2:0] current_state, next_state;

    // Timer counter
    reg [6:0] timer;  // 7 bits to count up to 60

    // Pedestrian request flag (latched)
    reg pb_request;

    // Light encoding constants
    localparam RED    = 3'b100;
    localparam YELLOW = 3'b010;
    localparam GREEN  = 3'b001;

    // State register with synchronous reset
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= M_GREEN;
            timer <= 0;
            pb_request <= 0;
        end else begin
            current_state <= next_state;

            // Timer logic
            if (current_state != next_state) begin
                timer <= 0;  // Reset timer on state change
            end else begin
                timer <= timer + 1;
            end

            // Latch pedestrian button press
            if (PB) begin
                pb_request <= 1;
            end else if (current_state == P_WALK) begin
                pb_request <= 0;  // Clear after pedestrian walk
            end
        end
    end

    // Next state logic
    always @(*) begin
        next_state = current_state;  // Default: stay in current state

        case (current_state)
            M_GREEN: begin
                // Stay green until minimum time AND (VS=1 or PB=1)
                if (timer >= M_GREEN_MIN && (VS || PB || pb_request)) begin
                    next_state = M_YELLOW;
                end
            end

            M_YELLOW: begin
                if (timer >= YELLOW_TIME) begin
                    next_state = ALL_RED_1;
                end
            end

            ALL_RED_1: begin
                if (timer >= ALL_RED_TIME) begin
                    // Prioritize pedestrian if button was pressed
                    if (PB || pb_request) begin
                        next_state = P_WALK;
                    end else begin
                        next_state = S_GREEN;
                    end
                end
            end

            S_GREEN: begin
                // Latch pedestrian requests during side green for next cycle
                if (timer >= SIDE_TIME) begin
                    next_state = S_YELLOW;
                end
            end

            P_WALK: begin
                if (timer >= PED_TIME) begin
                    next_state = S_YELLOW;  // Go to side yellow after pedestrian
                end
            end

            S_YELLOW: begin
                if (timer >= YELLOW_TIME) begin
                    next_state = ALL_RED_2;
                end
            end

            ALL_RED_2: begin
                if (timer >= ALL_RED_TIME) begin
                    next_state = M_GREEN;
                end
            end

            default: next_state = M_GREEN;
        endcase
    end

    // Output logic
    always @(*) begin
        // Default: all red, no walk
        light_main = RED;
        light_side = RED;
        walk = 0;

        case (current_state)
            M_GREEN: begin
                light_main = GREEN;
                light_side = RED;
                walk = 0;
            end

            M_YELLOW: begin
                light_main = YELLOW;
                light_side = RED;
                walk = 0;
            end

            ALL_RED_1: begin
                light_main = RED;
                light_side = RED;
                walk = 0;
            end

            S_GREEN: begin
                light_main = RED;
                light_side = GREEN;
                walk = 0;
            end

            P_WALK: begin
                light_main = RED;
                light_side = RED;
                walk = 1;  // Pedestrian walk signal
            end

            S_YELLOW: begin
                light_main = RED;
                light_side = YELLOW;
                walk = 0;
            end

            ALL_RED_2: begin
                light_main = RED;
                light_side = RED;
                walk = 0;
            end

            default: begin
                light_main = RED;
                light_side = RED;
                walk = 0;
            end
        endcase
    end

endmodule
