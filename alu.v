module alu #(parameter N=8, M=4)(

    input clk,
    input rst,
    input ce,
    input mode,
    input cin,

    input [1:0] inp_valid,
    input [M-1:0] cmd,

    input [N-1:0] opa,
    input [N-1:0] opb,

    output reg [2*N-1:0] res,

    output reg oflow,
    output reg cout,

    output reg G,
    output reg L,
    output reg E,

    output reg err
);



// =====================================
// INTERNALS
// =====================================

reg [N:0] temp;

reg signed [N:0] signed_result;


// MULT PIPELINE
reg count;

reg [N-1:0] opa_r;
reg [N-1:0] opb_r;

reg valid_r;

reg prev_mode;
reg [M-1:0] prev_cmd;


// =====================================
// ROTATION
// =====================================

localparam SHIFT_W = $clog2(N);

wire [SHIFT_W-1:0] rot_amt;

assign rot_amt = opb[SHIFT_W-1:0];

wire [N-1:0] rol_result;
wire [N-1:0] ror_result;

assign rol_result =
        (opa << rot_amt) |
        (opa >> (N - rot_amt));

assign ror_result =
        (opa >> rot_amt) |
        (opa << (N - rot_amt));



// =====================================
// ALU
// =====================================

always @(posedge clk or posedge rst) begin

    if (rst) begin

        res <= 0;

        oflow <= 0;
        cout <= 0;

        G <= 0;
        L <= 0;
        E <= 0;

        err <= 0;

        count <= 0;

        opa_r <= 0;
        opb_r <= 0;

        valid_r <= 0;

        prev_cmd <= 0;
        prev_mode <= 0;
    end


    else if (ce) begin

        // DEFAULTS
        res <= 0;

        oflow <= 0;
        cout <= 0;

        G <= 0;
        L <= 0;
        E <= 0;

        err <= 0;


        // RESET MULT PIPELINE
        if (mode && (cmd==9 || cmd==10)) begin

            if (prev_cmd != cmd ||
                prev_mode != mode) begin

                count <= 0;
            end
        end

        else begin
            count <= 0;
        end



// =====================================
// ARITHMETIC MODE
// =====================================

        if (mode) begin

            case(cmd)


// =====================================
// ADD
// =====================================

            0: begin

                if (inp_valid == 2'b11) begin

                    temp = opa + opb;

                    res <= {{(N-1){1'b0}}, temp};

                    cout <= temp[N];
                end

                else
                    err <= 1;
            end



// =====================================
// SUB
// =====================================

            1: begin

                if (inp_valid == 2'b11) begin

                    temp =
                        {1'b0, opa} -
                        {1'b0, opb};

                    res <=
                        {{(N-1){1'b0}}, temp};

                    oflow <=
                        ({1'b0,opa} <
                         {1'b0,opb});
                end

                else
                    err <= 1;
            end



// =====================================
// ADD WITH CIN
// =====================================

            2: begin

                if (inp_valid == 2'b11) begin

                    temp = opa + opb + cin;

                    res <=
                        {{(N-1){1'b0}}, temp};

                    cout <= temp[N];
                end

                else
                    err <= 1;
            end



// =====================================
// SUB WITH CIN
// =====================================

            3: begin

                if (inp_valid == 2'b11) begin

                    temp =
                        {1'b0,opa} -
                        {1'b0,opb} -
                        cin;

                    res <=
                        {{(N-1){1'b0}}, temp};

                    oflow <=
                        ({1'b0,opa} <
                         ({1'b0,opb} + cin));
                end

                else
                    err <= 1;
            end



// =====================================
// INC A
// =====================================

            4: begin

                if (inp_valid[0])
                    res <= opa + 1;

                else
                    err <= 1;
            end



// =====================================
// DEC A
// =====================================

            5: begin

                if (inp_valid[0])
                    res <= opa - 1;

                else
                    err <= 1;
            end



// =====================================
// INC B
// =====================================

            6: begin

                if (inp_valid[1])
                    res <= opb + 1;

                else
                    err <= 1;
            end



// =====================================
// DEC B
// =====================================

            7: begin

                if (inp_valid[1])
                    res <= opb - 1;

                else
                    err <= 1;
            end



// =====================================
// COMPARE
// =====================================

            8: begin

                if (inp_valid == 2'b11) begin

                    G <= (opa > opb);
                    L <= (opa < opb);
                    E <= (opa == opb);
                end

                else
                    err <= 1;
            end




            9: begin

                // SAMPLE
                if (count == 0) begin

                    opa_r <= opa;
                    opb_r <= opb;

                    valid_r <=
                        (inp_valid == 2'b11);

                    count <= 1;
                end


                // OUTPUT + RESAMPLE
                else begin

                    if (valid_r)
                        res <=
                            (opa_r + 1) *
                            (opb_r + 1);

                    else
                        err <= 1;

                    // SAMPLE NEXT INPUT
                    opa_r <= opa;
                    opb_r <= opb;

                    valid_r <=
                        (inp_valid == 2'b11);

                    count <= 0;
                end
            end




            10: begin

                // SAMPLE
                if (count == 0) begin

                    opa_r <= opa;
                    opb_r <= opb;

                    valid_r <=
                        (inp_valid == 2'b11);

                    count <= 1;
                end


                // OUTPUT + RESAMPLE
                else begin

                    if (valid_r)
                        res <=
                            (opa_r << 1) *
                            opb_r;

                    else
                        err <= 1;

                    // SAMPLE NEXT INPUT
                    opa_r <= opa;
                    opb_r <= opb;

                    valid_r <=
                        (inp_valid == 2'b11);

                    count <= 0;
                end
            end



// =====================================
// SIGNED ADD
// =====================================

            11: begin

                if (inp_valid == 2'b11) begin

                    signed_result =
                        $signed({opa[N-1],opa}) +
                        $signed({opb[N-1],opb});

                    res <=
                        {{N{signed_result[N-1]}},
                          signed_result[N-1:0]};

                    oflow <=
                        (signed_result[N] !=
                         signed_result[N-1]);

                    G <=
                        ($signed(opa) >
                         $signed(opb));

                    L <=
                        ($signed(opa) <
                         $signed(opb));

                    E <=
                        ($signed(opa) ==
                         $signed(opb));
                end

                else
                    err <= 1;
            end



// =====================================
// SIGNED SUB
// =====================================

            12: begin

                if (inp_valid == 2'b11) begin

                    signed_result =
                        $signed({opa[N-1],opa}) -
                        $signed({opb[N-1],opb});

                    res <=
                        {{N{signed_result[N-1]}},
                          signed_result[N-1:0]};

                    oflow <=
                        (signed_result[N] !=
                         signed_result[N-1]);

                    G <=
                        ($signed(opa) >
                         $signed(opb));

                    L <=
                        ($signed(opa) <
                         $signed(opb));

                    E <=
                        ($signed(opa) ==
                         $signed(opb));
                end

                else
                    err <= 1;
            end



// =====================================
// DEFAULT
// =====================================

            default: begin

                err <= 1;
            end

            endcase
        end



// =====================================
// LOGICAL MODE
// =====================================

        else begin

            case(cmd)


// AND
            0: begin

                if (inp_valid == 2'b11)
                    res[N-1:0] <= opa & opb;
                else
                    err <= 1;
            end


// NAND
            1: begin

                if (inp_valid == 2'b11)
                    res[N-1:0] <= ~(opa & opb);
                else
                    err <= 1;
            end


// OR
            2: begin

                if (inp_valid == 2'b11)
                    res[N-1:0] <= opa | opb;
                else
                    err <= 1;
            end


// NOR
            3: begin

                if (inp_valid == 2'b11)
                    res[N-1:0] <= ~(opa | opb);
                else
                    err <= 1;
            end


// XOR
            4: begin

                if (inp_valid == 2'b11)
                    res[N-1:0] <= opa ^ opb;
                else
                    err <= 1;
            end


// XNOR
            5: begin

                if (inp_valid == 2'b11)
                    res[N-1:0] <= ~(opa ^ opb);
                else
                    err <= 1;
            end


// NOT A
            6: begin

                if (inp_valid[0])
                    res <= {{N{1'b0}}, ~opa};
                else
                    err <= 1;
            end


// NOT B
            7: begin

                if (inp_valid[1])
                    res <= {{N{1'b0}}, ~opb};
                else
                    err <= 1;
            end


// A RIGHT SHIFT
            8: begin

                if (inp_valid[0])
                    res <= {{N{1'b0}}, (opa >> 1)};
                else
                    err <= 1;
            end


// A LEFT SHIFT
            9: begin

                if (inp_valid[0])
                    res <= {{N{1'b0}}, (opa << 1)};
                else
                    err <= 1;
            end


// B RIGHT SHIFT
            10: begin

                if (inp_valid[1])
                    res <= {{N{1'b0}}, (opb >> 1)};
                else
                    err <= 1;
            end


// B LEFT SHIFT
            11: begin

                if (inp_valid[1])
                    res <= {{N{1'b0}}, (opb << 1)};
                else
                    err <= 1;
            end


// ROL
            12: begin

                if (inp_valid == 2'b11) begin

                    err <= (opb >= N);

                    if (rot_amt == 0)
                        res <= {{N{1'b0}}, opa};
                    else
                        res <= {{N{1'b0}}, rol_result};
                end

                else begin

                    err <= 1;
                    res <= 0;
                end
            end


// ROR
            13: begin

                if (inp_valid == 2'b11) begin

                    err <= (opb >= N);

                    if (rot_amt == 0)
                        res <= {{N{1'b0}}, opa};
                    else
                        res <= {{N{1'b0}}, ror_result};
                end

                else begin

                    err <= 1;
                    res <= 0;
                end
            end


// DEFAULT
            default: begin

                err <= 1;
            end

            endcase
        end


        prev_cmd <= cmd;
        prev_mode <= mode;

    end
end

endmodule
