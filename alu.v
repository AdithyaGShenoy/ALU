module alu #(parameter N=8, M=4)(

    input clk, rst, ce, mode, cin,
    input [1:0] inp_valid,
    input [M-1:0] cmd,
    input [N-1:0] opa, opb,
    output reg [2*N-1:0] res,
    output reg oflow, cout, G, L, E, err
);


reg [N:0] temp;
reg signed [2*N-1:0] signed_result;


reg [1:0] count;
reg [N-1:0] opa_r, opb_r;
reg [2*N-1:0] mult_result;
reg valid_r;
reg prev_mode;
reg [M-1:0] prev_cmd;


localparam shift_width = $clog2(N);
wire [shift_width-1:0] rot_amt = opb[shift_width-1:0];

wire [N-1:0] rol_result =
    (opa << rot_amt) | (opa >> (N - rot_amt));

wire [N-1:0] ror_result =
    (opa >> rot_amt) | (opa << (N - rot_amt));

//alu
always @(posedge clk or posedge rst) begin
    if (rst) begin
        res<=0; oflow<=0; cout<=0;
        G<=0; L<=0; E<=0; err<=0;
        count<=0; prev_cmd<=0; prev_mode<=0;
    end
    else if (ce) begin


        res<=0; oflow<=0; cout<=0;
        G<=0; L<=0; E<=0; err<=0;


        // COUNTER CONTROL

        if (mode && (cmd==9 || cmd==10)) begin
            if (prev_cmd!=cmd || prev_mode!=mode)
                count <= 0;
            else if (count < 2)
                count <= count + 1;
        end else begin
            count <= 0;
        end


        // MODE = 1 (ARITHMETIC)

        if (mode) begin
            case (cmd)

            // ADD
            0: begin
                if (inp_valid==2'b11) begin
                    temp = opa + opb;
                    res  <= {{(N-1){1'b0}}, temp};
                    cout <= temp[N];
                end
                oflow<=0; {G,L,E}<=0;
                err <= ~(inp_valid==2'b11);
            end

            // SUB
            1: begin
                if (inp_valid==2'b11) begin
                    temp = {1'b0,opa} - {1'b0,opb};
                    res  <= {{(N-1){1'b0}}, temp};
                    oflow <= (opa < opb);
                end
                cout<=0; {G,L,E}<=0;
                err <= ~(inp_valid==2'b11);
            end

            // ADD WITH CIN
            2: begin
                if (inp_valid==2'b11) begin
                    temp = opa + opb + cin;
                    res  <= {{(N-1){1'b0}}, temp};
                    cout <= temp[N];
                end
                oflow<=0; {G,L,E}<=0;
                err <= ~(inp_valid==2'b11);
            end

            // SUB WITH CIN
            3: begin
                if (inp_valid==2'b11) begin
                    temp = {1'b0,opa} - {1'b0,opb} - cin;
                    res  <= {{(N-1){1'b0}}, temp};
                    oflow <= (opa < (opb+cin));
                end
                cout<=0; {G,L,E}<=0;
                err <= ~(inp_valid==2'b11);
            end

            // INC / DEC
            4: begin if (inp_valid[0]) res <=  opa+1;
               cout<=0; oflow<=0; {G,L,E}<=0; err<=~inp_valid[0]; end

            5: begin if (inp_valid[0]) res <=  opa-1;
               cout<=0; oflow<=0; {G,L,E}<=0; err<=~inp_valid[0]; end

            6: begin if (inp_valid[1]) res <= opb+1;
               cout<=0; oflow<=0; {G,L,E}<=0; err<=~inp_valid[1]; end

            7: begin if (inp_valid[1]) res <= opb-1;
               cout<=0; oflow<=0; {G,L,E}<=0; err<=~inp_valid[1]; end

            //  COMPARE
            8: begin
                if (inp_valid==2'b11)
                    {G,L,E} <= {(opa>opb),(opa<opb),(opa==opb)};
                res<=0; cout<=0; oflow<=0;
                err <= ~(inp_valid==2'b11);
            end

            //  (opa+1)*(opb+1)
            9: begin
                if (count==0) begin
                    opa_r<=opa; opb_r<=opb;
                    valid_r <= (inp_valid==2'b11);
                end
                if (count==1)
                    mult_result <= (opa_r+1)*(opb_r+1);
                if (count==2) begin
                    if (valid_r) res <= mult_result;
                    else err <= 1;
                end
                cout<=0; oflow<=0; {G,L,E}<=0;
            end

            //  (opa<<1)*opb
            10: begin
                if (count==0) begin
                    opa_r<=opa; opb_r<=opb;
                    valid_r <= (inp_valid==2'b11);
                end
                if (count==1)
                    mult_result <= (opa_r << 1) * opb_r;
                if (count==2) begin
                    if (valid_r) res <= mult_result;
                    else err <= 1;
                end
                cout<=0; oflow<=0; {G,L,E}<=0;
            end

            // SIGNED ADD
            11: begin
                if (inp_valid==2'b11) begin
                    signed_result = $signed(opa) + $signed(opb);
		    res <= signed_result;
                    oflow <= (opa[N-1]==opb[N-1]) &&
                             (signed_result[2*N-1]!=opa[N-1]);

                    G <= ($signed(opa) > $signed(opb));
                    L <= ($signed(opa) < $signed(opb));
                    E <= ($signed(opa) == $signed(opb));
                end
                else begin
                    res<=0; oflow<=0; {G,L,E}<=0;
                end
                cout<=0;
                err <= ~(inp_valid==2'b11);
            end

            // SIGNED SUB
            12: begin
                if (inp_valid==2'b11) begin
                    signed_result = $signed(opa) - $signed(opb);
		    res <= signed_result;
                    oflow <= (opa[N-1]!=opb[N-1]) &&
                             (signed_result[2*N-1]!=opa[N-1]);

                    G <= ($signed(opa) > $signed(opb));
                    L <= ($signed(opa) < $signed(opb));
                    E <= ($signed(opa) == $signed(opb));
                end
                else begin
                    res<=0; oflow<=0; {G,L,E}<=0;
                end
                cout<=0;
                err <= ~(inp_valid==2'b11);
            end

            default: begin
                res<=0; cout<=0; oflow<=0; {G,L,E}<=0; err<=1;
            end
            endcase
        end


        // MODE = 0 (LOGICAL)

        else begin
            case (cmd)
//AND
            0: begin res[N-1:0] <= (inp_valid==2'b11)?(opa&opb):0;
               oflow<=0; cout<=0; {G,L,E}<=0; err<=~(inp_valid==2'b11); end
//NAND
            1: begin res[N-1:0] <= (inp_valid==2'b11)?~(opa&opb):0;
               oflow<=0; cout<=0; {G,L,E}<=0; err<=~(inp_valid==2'b11); end
//OR
            2: begin res[N-1:0] <= (inp_valid==2'b11)?(opa|opb):0;
               oflow<=0; cout<=0; {G,L,E}<=0; err<=~(inp_valid==2'b11); end
//NOR
            3: begin res[N-1:0] <= (inp_valid==2'b11)?~(opa|opb):0;
               oflow<=0; cout<=0; {G,L,E}<=0; err<=~(inp_valid==2'b11); end
//XOR
            4: begin res[N-1:0] <= (inp_valid==2'b11)?(opa^opb):0;
               oflow<=0; cout<=0; {G,L,E}<=0; err<=~(inp_valid==2'b11); end
//XNOR

            5: begin res[N-1:0] <= (inp_valid==2'b11)?~(opa^opb):0;
               oflow<=0; cout<=0; {G,L,E}<=0; err<=~(inp_valid==2'b11); end

//NOT_A
            6: begin res <= (inp_valid[0])? {{N{1'b0}}, ~opa}:0;
               oflow<=0; cout<=0; {G,L,E}<=0; err<=~inp_valid[0]; end

//NOT_B
            7: begin res <= (inp_valid[1])? {{N{1'b0}}, ~opb}:0;
               oflow<=0; cout<=0; {G,L,E}<=0; err<=~inp_valid[1]; end
//A RIGHT SHIFT

            8: begin res <= (inp_valid[0])? {{N{1'b0}}, (opa>>1)}:0;
               oflow<=0; cout<=0; {G,L,E}<=0; err<=~inp_valid[0]; end

//A LEFT SHIFT
            9: begin res <= (inp_valid[0])? {{N{1'b0}}, (opa<<1)}:0;
               oflow<=0; cout<=0; {G,L,E}<=0; err<=~inp_valid[0]; end

//B RIGHT SHIFT
            10: begin res <= (inp_valid[1])? {{N{1'b0}}, (opb>>1)}:0;
                oflow<=0; cout<=0; {G,L,E}<=0; err<=~inp_valid[1]; end

      //B LEFT SHIFT
            11: begin res <= (inp_valid[1])? {{N{1'b0}}, (opb<<1)}:0;
                oflow<=0; cout<=0; {G,L,E}<=0; err<=~inp_valid[1]; end

           //ROL
            12: begin
                if (inp_valid==2'b11) begin
                    err <= |opb[N-1:N/2];
                    if (rot_amt==0)
                        res <= {{N{1'b0}}, opa};
                    else
                        res <= {{N{1'b0}}, rol_result};
                end
                else begin
                    err <= 1;
                    res <= 0;
                end
                cout<=0; oflow<=0; {G,L,E}<=0;
            end

            // ROR
            13: begin
                if (inp_valid==2'b11) begin
                    err <= |opb[N-1:N/2];
                    if (rot_amt==0)
                        res <= {{N{1'b0}}, opa};
                    else
                        res <= {{N{1'b0}}, ror_result};
                end
                else begin
                    err <= 1;
                    res <= 0;
                end
                cout<=0; oflow<=0; {G,L,E}<=0;
            end

            default: begin
                res<=0; cout<=0; oflow<=0; {G,L,E}<=0; err<=1;
            end
            endcase
        end

        prev_cmd  <= cmd;
        prev_mode <= mode;
    end
end

endmodule
