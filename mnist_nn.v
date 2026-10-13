module mnist_nn(

    input clk,
    input reset,

    input start,

    input [7:0] pixel_in,
    input pixel_valid,

    output reg done,
    output reg [3:0] prediction

);

    // ==========================
    // MEMORY
    // ==========================

    reg signed [7:0] weight_mem [0:7839];
    reg signed [31:0] bias_mem [0:9];

    initial begin
        $readmemh("weights.mem", weight_mem);
        $readmemh("bias.mem", bias_mem);
    end

    // ==========================
    // PIXEL STORAGE
    // ==========================

    reg [7:0] pixels [0:783];

    reg [9:0] load_index;

    // ==========================
    // FSM STATES
    // ==========================

    reg [2:0] state;

    parameter IDLE      = 0;
    parameter LOAD      = 1;
    parameter COMPUTE   = 2;
    parameter NEXTDIGIT = 3;
    parameter FINISH    = 4;

    // ==========================
    // COMPUTE VARIABLES
    // ==========================

    reg [9:0] pixel_index;

    reg [3:0] digit;

    reg signed [31:0] accumulator;

    reg signed [31:0] scores [0:9];

    reg signed [31:0] max_score;

    integer i;

    // ==========================
    // MAIN FSM
    // ==========================

    always @(posedge clk or posedge reset)
    begin

        if(reset)
        begin

            state <= IDLE;

            load_index <= 0;

            pixel_index <= 0;

            digit <= 0;

            accumulator <= 0;

            prediction <= 0;

            done <= 0;

            max_score <= -2147483648;

        end

        else
        begin

            case(state)

            // ======================
            // IDLE
            // ======================

            IDLE:
            begin

                done <= 0;

                if(start)
                begin

                    load_index <= 0;

                    state <= LOAD;

                end

            end

            // ======================
            // LOAD PIXELS
            // ======================

            LOAD:
            begin

                if(pixel_valid)
                begin

                    pixels[load_index] <= pixel_in;

                    load_index <= load_index + 1;

                    if(load_index == 783)
                    begin

                        digit <= 0;

                        pixel_index <= 0;

                        accumulator <= 0;

                        max_score <= -2147483648;

                        prediction <= 0;

                        state <= COMPUTE;

                    end

                end

            end

            // ======================
            // COMPUTE
            // ======================

            COMPUTE:
            begin

                accumulator <= accumulator +

                $signed(weight_mem[digit*784 + pixel_index]) *
                $signed({1'b0, pixels[pixel_index]});

                pixel_index <= pixel_index + 1;

                if(pixel_index == 783)
                begin

                    scores[digit] <= accumulator + bias_mem[digit];

                    state <= NEXTDIGIT;

                end

            end

            // ======================
            // NEXT DIGIT
            // ======================

            NEXTDIGIT:
            begin

                // compare score

                if(scores[digit] > max_score)
                begin

                    max_score <= scores[digit];

                    prediction <= digit;

                end

                // next digit

                if(digit == 9)
                begin

                    state <= FINISH;

                end

                else
                begin

                    digit <= digit + 1;

                    pixel_index <= 0;

                    accumulator <= 0;

                    state <= COMPUTE;

                end

            end

            // ======================
            // FINISH
            // ======================

            FINISH:
            begin

                done <= 1;

                state <= IDLE;

            end

            endcase

        end

    end

endmodule