`include "testing_alu.v"
`define N 8
`define Valid_P 2
`define M 4
`define clock_delay @(posedge clk)
`define arithmetic_modes 12
`define logical_modes 13
`define WID 3
//to generate random numbers in range inclusive of max and min [max,min]
`define RANDOM_IN_RANGE(max,min) (($random % ((max)-(min)+1)) + (min))

`define NONE 3'b000
`define V_A 2'b01
`define V_B 2'b10
`define V_BOTH 2'b11
`define V_NONE 2'b00

`define ADD 4'h0
`define SUB 4'h1
`define ADD_CIN    4'h2
`define SUB_CIN    4'h3
`define INC_A      4'h4
`define DEC_A      4'h5
`define INC_B      4'h6
`define DEC_B      4'h7
`define CMP        4'h8
`define MUL_INC    4'h9
`define MUL_SHL    4'hA
`define SADD       4'hB
`define SSUB       4'hC

`define AND 4'h0
`define NAND 4'h1
`define OR         4'h2
`define NOR        4'h3
`define XOR        4'h4
`define XNOR       4'h5
`define NOT_A      4'h6
`define NOT_B      4'h7
`define SHR1_A     4'h8
`define SHL1_A     4'h9
`define SHR1_B     4'hA
`define SHL1_B     4'hB
`define ROL_A_B    4'hC
`define ROR_A_B    4'hD


module tb;

reg clk;
reg rst;
reg [`Valid_P-1:0] inp_valid;
reg mode;
reg [`M-1:0] cmd;
reg ce;
reg [`N-1:0]opa,opb;
reg cin;
wire err;
wire [2*`N-1:0] res;
wire oflow;
wire cout;
wire G,L,E;


reg [2*`N-1:0] exp_res;
reg exp_err;
reg exp_oflow;
reg exp_cout;
reg exp_G;
reg exp_L;
reg exp_E;

reg [`Valid_P-1:0] r_inp_valid;
reg  r_mode;
reg [`M-1:0] r_cmd;
reg [`N-1:0] r_opa,r_opb;
reg r_ce;
reg r_cin;
reg [2*`N-1:0] mul_s1_res;
reg mul_s1_valid;
reg [`M-1:0] mul_s1_cmd;

reg signed [2*`N-1:0] ref_signed;
reg[`N-1:0] rot_amt;

integer pass_cnt,fail_cnt;
integer cmd_i;
//DUT instantiation
  ALU_DESIGN #(.WIDTH(`N)) dut( .OPA(opa),.OPB(opb),.CIN(cin),.CLK(clk),.RST(rst),.CMD(cmd),.CE(ce),.MODE(mode),.INP_VAD(inp_valid),.COUT(cout),.OFLOW(oflow),.RES(res),.G(G),.L(L),.E(E),.ERR(err));


initial
begin
clk=1'b0;
forever
begin
#5 clk=~clk;
end
end

task reset;
begin
rst=1'b1;
repeat(2)
begin
`clock_delay;
end
rst=1'b0;
end
endtask


task general_arithmetic;
begin
mode=1'b1;
ce=1'b1;
rst=1'b0;
inp_valid=`V_BOTH;

//small values in general
repeat(20)
begin
opa=`RANDOM_IN_RANGE(30,0);
opb=`RANDOM_IN_RANGE(30,0);
  cmd=`RANDOM_IN_RANGE(`arithmetic_modes,0);
cin=$random;
`clock_delay;
end

//medium values in general
repeat(40)
begin
opa=`RANDOM_IN_RANGE(100,31);
opb=`RANDOM_IN_RANGE(100,31);
  cmd=`RANDOM_IN_RANGE(`arithmetic_modes,0);
cin=$random;
`clock_delay;
end

//large values in general
repeat(30)
begin
opa=`RANDOM_IN_RANGE(253,101);
opb=`RANDOM_IN_RANGE(253,101);
  cmd=`RANDOM_IN_RANGE(`arithmetic_modes,0);
cin=$random;
`clock_delay;
end

//max values possible for all the arithmetic commands
  for(cmd_i=0;cmd_i<=`arithmetic_modes;cmd_i=cmd_i+1)
begin
 opa=`RANDOM_IN_RANGE(255,254);
 opb=`RANDOM_IN_RANGE(255,254);
 cmd=cmd_i;
 cin=$random;
 `clock_delay;
end

//driving only zeros
  for(cmd_i=0;cmd_i<=`arithmetic_modes;cmd_i=cmd_i+1)
begin
 opa=0;
 opb=0;
 cmd=cmd_i;
 cin=$random;
 `clock_delay;
end

//opa=opb cases
  for(cmd_i=0;cmd_i<=`arithmetic_modes;cmd_i=cmd_i+1)
begin
 opa=`RANDOM_IN_RANGE(255,0);
 opb=opa;
 cmd=cmd_i;
 cin=$random;
 `clock_delay;
end

//underflow cases
repeat(30)
begin
opb=`RANDOM_IN_RANGE(255,1);
opa=`RANDOM_IN_RANGE(opb-1,0);
cmd=`SUB;
cin=$random;
`clock_delay;
cmd=`SUB_CIN;
`clock_delay;
cmd=`SSUB;
`clock_delay;
end

//when cin=1 for add with cin and sub with cin
repeat(20)
begin
opa=`RANDOM_IN_RANGE(255,0);
opb=`RANDOM_IN_RANGE(255,0);
cin=1'b1;
cmd=`ADD_CIN;
`clock_delay;
cmd=`SUB_CIN;
`clock_delay;
end

end
endtask

task general_logical;
begin
mode=1'b0;
ce=1'b1;
rst=1'b0;
inp_valid=`V_BOTH;

//small values
repeat(20)
begin
opa=`RANDOM_IN_RANGE(30,0);
opb=`RANDOM_IN_RANGE(30,0);
  cmd=`RANDOM_IN_RANGE(`logical_modes,0);
cin=$random;
`clock_delay;
end

//medium range values
repeat(30)
 begin
opa=`RANDOM_IN_RANGE(100,31);
opb=`RANDOM_IN_RANGE(100,31);
   cmd=`RANDOM_IN_RANGE(`logical_modes,0);
cin=$random;
`clock_delay;
end

//high range values
repeat(30)
begin
opa=`RANDOM_IN_RANGE(253,101);
opb=`RANDOM_IN_RANGE(253,101);
  cmd=`RANDOM_IN_RANGE(`logical_modes,0);
cin=$random;
`clock_delay;
end

//MAX VALUES FOR EVERY COMMAND
  for(cmd_i=0;cmd_i<=`logical_modes;cmd_i=cmd_i+1)
begin
 opa=`RANDOM_IN_RANGE(255,254);
 opb=`RANDOM_IN_RANGE(255,254);
 cmd=cmd_i;
 cin=$random;
 `clock_delay;
end

//ALL COMMAND WITH INP AS ZEROS
  for(cmd_i=0;cmd_i<=`logical_modes;cmd_i=cmd_i+1)
begin
 opa=0;
 opb=0;
 cmd=cmd_i;
 cin=$random;
 `clock_delay;
end

//ALL COMMAND WITH OPA=OPB
  for(cmd_i=0;cmd_i<=`logical_modes;cmd_i=cmd_i+1)
begin
 opa=`RANDOM_IN_RANGE(255,0);
 opb=opa;
 cmd=cmd_i;
 cin=$random;
 `clock_delay;
end

//rotation
repeat(15)
begin
opa=`RANDOM_IN_RANGE(255,100);
opb=`RANDOM_IN_RANGE(255,0);
cmd=`RANDOM_IN_RANGE(13,12);
cin=$random;
`clock_delay;
end

//shift corner
repeat(10)
begin
opa=1;
cmd=`RANDOM_IN_RANGE(8,9);//SHIFT LEFT OR RIGHT FOR A
cin=$random;
`clock_delay;
opa=128;
cmd=`RANDOM_IN_RANGE(8,9);//SHIFT LEFT OR RIGHT FOR A
cin=$random;
`clock_delay;
opb=1;
cmd=`RANDOM_IN_RANGE(10,11);//SHIFT LEFT OR RIGHT FOR B
cin=$random;
`clock_delay;
opb=128;
cmd=`RANDOM_IN_RANGE(10,11);//SHIFT LEFT OR RIGHT FOR B
cin=$random;
`clock_delay;
end
end
endtask

//unknown inp for rotation
task unknown_input;
begin
ce=1'b1;
rst=1'b0;
inp_valid=`V_BOTH;
opa[7:4]=4'bxxxx;
opb[7:4]=4'bxxxx;
repeat(20)
begin
mode=0;
opa[3:0]=$random;
opb[3:0]=$random;
cmd=`RANDOM_IN_RANGE(13,12);
cin=$random;
`clock_delay;
end
end
endtask

task invalid_inputs;
begin
ce=1'b1;
rst=1'b0;

repeat(30)
begin
mode=$random;
opa=$random;
opb=$random;
  cmd=`RANDOM_IN_RANGE(`arithmetic_modes,0);
cin=$random;
inp_valid=`RANDOM_IN_RANGE(3,0);
`clock_delay;
end
end
endtask


task clock_enable;
begin
rst=1'b0;
repeat(10)
begin
ce=$random;
mode=$random;
opa=$random;
opb=$random;
  cmd=`RANDOM_IN_RANGE(`arithmetic_modes,0);
cin=$random;
inp_valid=$random;
`clock_delay;
end
end
endtask


task multiplication;
begin
repeat(30)
begin
rst=1'b0;
inp_valid=`V_BOTH;
mode=1'b1;
ce=1'b1;
opa=$random;
opb=$random;
cmd=`RANDOM_IN_RANGE(10,9);
cin=$random;
repeat(2)
begin
`clock_delay;
end
end
end
endtask

//mul cmd change
task mul_change;
begin
repeat(20)
begin
rst=1'b0;
inp_valid=`V_BOTH;
mode=1'b1;
ce=1'b1;
opa=$random;
opb=$random;
cmd=`RANDOM_IN_RANGE(7,10);
cin=$random;
repeat(1)
begin
`clock_delay;
end
end
repeat (15)
begin
mode = 1;
inp_valid= `V_BOTH;
ce = 1'b1;
opa = $random;
opb = $random;
cmd = 8;
`clock_delay;
end

repeat(3)
begin
mode = 1;
inp_valid = `V_NONE;
ce = 1'b1;
opa = $random;
opb = $random;
cmd = 11;
`clock_delay;
end
end
endtask




always @(posedge clk or posedge rst)
begin
if(rst)
begin
r_inp_valid<=0;
r_mode<=0;
r_cmd<=0;
r_opa<=0;
r_opb<=0;
r_cin<=0;
r_ce<=0;
end

else
begin
r_inp_valid<=inp_valid;
r_mode<=mode;
r_cmd<=cmd;
r_opa<=opa;
r_opb<=opb;
r_cin<=cin;
r_ce<=ce;
end
end


always@(posedge clk or posedge rst)
begin
if(rst)
begin
exp_res<=0;
exp_err<=0;
exp_oflow<=0;
exp_cout<=0;
  {exp_G,exp_L,exp_E}<=`NONE;
mul_s1_res<=0;
mul_s1_valid<=0;
mul_s1_cmd<=0;
end
  else if(r_ce)
begin
exp_err<=0;
exp_oflow<=0;
exp_cout<=0;
  {exp_G,exp_L,exp_E}<=`NONE;

  if(mul_s1_valid && r_cmd == `MUL_INC)
begin
exp_res<=mul_s1_res;
mul_s1_valid<=0;
end
  else if(mul_s1_valid && r_cmd == `MUL_SHL)
begin
exp_res<=mul_s1_res;
mul_s1_valid<=0;
end

else
begin
if(r_mode)
  begin
    case(r_cmd)
      `ADD: begin
        {exp_cout,exp_res[`N-1:0]}<=(r_inp_valid==`V_BOTH)?(r_opa+r_opb):{exp_cout,exp_res[`N-1:0]};
        exp_res<=(r_inp_valid==`V_BOTH)?(r_opa+r_opb):exp_res;
             exp_oflow<=0;
        {exp_G,exp_L,exp_E}=`NONE;
        exp_err<=~(r_inp_valid == `V_BOTH);
             end
       `SUB: begin
         exp_res<=(r_inp_valid==`V_BOTH)?({8'h00,r_opa} - {8'h00,r_opb}):exp_res;
             exp_oflow<=(opa<opb);
         {exp_G,exp_L,exp_E}=`NONE;
         exp_err<=~(r_inp_valid == `V_BOTH);
             end
   `ADD_CIN: begin
     {exp_cout,exp_res[`N-1:0]}<=(r_inp_valid==`V_BOTH)?(r_opa+r_opb+r_cin):{exp_cout,exp_res[`N-1:0]};
     exp_res<=(r_inp_valid==`V_BOTH)?(r_opa+r_opb+r_cin):exp_res;
             exp_oflow<=0;
     {exp_G,exp_L,exp_E}=`NONE;
     exp_err<=~(r_inp_valid == `V_BOTH);
             end
   `SUB_CIN: begin
     exp_res<=(r_inp_valid==`V_BOTH)?(r_opa - r_opb - r_cin):exp_res;
             exp_oflow<=({1'b0,r_opa}<({1'b0,r_opb} + r_cin));
             exp_cout<=0;
     {exp_G,exp_L,exp_E}=`NONE;
     exp_err<=~(r_inp_valid == `V_BOTH);
             end
    `INC_A:  begin
      exp_res<= (r_inp_valid==`V_BOTH || r_inp_valid==`V_A)?(r_opa+1):exp_res;
      exp_err<= ~(r_inp_valid==`V_BOTH || r_inp_valid == `V_A);
             exp_cout<=0;
             exp_oflow<=0;
      {exp_G,exp_L,exp_E}=`NONE;
             end
    `DEC_A:  begin
      exp_res<= (r_inp_valid==`V_BOTH || r_inp_valid==`V_A)?(r_opa-1):exp_res;
      exp_err<= ~(r_inp_valid==`V_BOTH || r_inp_valid ==`V_A);
             exp_cout<=0;
             exp_oflow<=0;
      {exp_G,exp_L,exp_E}=`NONE;
             end
    `INC_B:  begin
      exp_res<= (r_inp_valid==`V_BOTH || r_inp_valid==`V_B)?(r_opb+1):exp_res;
      exp_err<= ~(r_inp_valid==`V_BOTH || r_inp_valid == `V_B);
             exp_cout<=0;
             exp_oflow<=0;
      {exp_G,exp_L,exp_E}=`NONE;
             end
    `DEC_B:  begin
      exp_res<= (r_inp_valid==`V_BOTH || r_inp_valid==`V_B)?(r_opb-1):exp_res;
      exp_err<= ~(r_inp_valid==`V_BOTH || r_inp_valid == `V_B);
             exp_cout<=0;
             exp_oflow<=0;
      {exp_G,exp_L,exp_E}=`NONE;
             end
    `CMP:    begin
             exp_res<=0;
             exp_cout<=0;
             exp_oflow<=0;
             {exp_G,exp_L,exp_E}<={(r_opa>r_opb),(r_opa<r_opb),(r_opa==r_opb)};
             end
  `MUL_INC:  begin
    if(r_inp_valid == `V_BOTH)
             begin
             mul_s1_res<=(r_opa + 1) * (r_opb+1);
             mul_s1_valid<=1;
             mul_s1_cmd<=`MUL_INC;
               {exp_G,exp_L,exp_E}=`NONE;
               exp_res<={2*`N{1'bx}};
             end
             else
             begin
             exp_err<=1'b1;
               exp_res<={2*`N{1'bx}};
             end
             end
  `MUL_SHL:  begin
    if(r_inp_valid == `V_BOTH)
             begin
             mul_s1_res <= (r_opa<<1)*r_opb;
             mul_s1_valid <= 1;
             mul_s1_cmd <= `MUL_SHL;
               {exp_G,exp_L,exp_E} <= `NONE;
               exp_res <= {2*`N{1'bx}};
             end
             else
             begin
             exp_err <= 1;
               exp_res <= {2*`N{1'bx}};
             end
             end

   `SADD:    begin
     if (r_inp_valid==`V_BOTH)
             begin
             ref_signed=$signed({1'b0,r_opa}) + $signed({1'b0,r_opb});
             exp_cout<= 0;
               exp_res<={{`N{ref_signed[`N-1]}},ref_signed[`N-1:0]};
               exp_oflow<=(r_opa[`N-1]==r_opb[`N-1]) &&(ref_signed[`N-1]!=r_opa[`N-1]);
             exp_G <= ($signed(r_opa) > $signed(r_opb));
             exp_L <= ($signed(r_opa) < $signed(r_opb));
             exp_E <= ($signed(r_opa) == $signed(r_opb));
             end
             else
             begin
             exp_res<=0;
             exp_cout<=0;
             exp_oflow<=0;
               {exp_G,exp_L,exp_E}<=`NONE;
             end
     exp_err<=~(r_inp_valid==`V_BOTH);
             end

   `SSUB:    begin
     if (r_inp_valid==`V_BOTH)
             begin
             ref_signed=$signed({1'b0,r_opa}) - $signed({1'b0,r_opb});
             exp_cout<= 0;
               exp_res<={{`N{ref_signed[`N-1]}},ref_signed[`N-1:0]};
               exp_oflow<=(r_opa[`N-1]!=r_opb[`N-1]) &&(ref_signed[`N-1]!=r_opa[`N-1]);
             exp_G <= ($signed(r_opa) > $signed(r_opb));
             exp_L <= ($signed(r_opa) < $signed(r_opb));
             exp_E <= ($signed(r_opa) == $signed(r_opb));
             end
             else
             begin
             exp_res<=0;
             exp_cout<=0;
             exp_oflow<=0;
               {exp_G,exp_L,exp_E}<=`NONE;
             end
     exp_err<=~(r_inp_valid==`V_BOTH);
             end

   default: begin
            exp_res<=0;
            exp_cout<=0;
            exp_oflow<=0;
     {exp_G,exp_L,exp_E}<=`NONE;
            exp_err<=0;
            end
    endcase
  end
       else
         begin
            case(r_cmd)

      `AND: begin
        exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH) ? (r_opa & r_opb) : 0;
        exp_res[2*`N-1:`N] <= 0;
            exp_oflow <= 0;
            exp_cout <= 0;
        {exp_G,exp_L,exp_E} <= `NONE;
        exp_err <= ~(r_inp_valid==`V_BOTH);
            end

     `NAND: begin
       exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH) ? ~(r_opa & r_opb) : 0;
       exp_res[2*`N-1:`N] <= 0;
            exp_oflow<= 0;
            exp_cout<= 0;
       {exp_G,exp_L,exp_E} <= `NONE;
       exp_err <= ~(r_inp_valid==`V_BOTH);
            end

       `OR: begin
         exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH) ? (r_opa | r_opb) : 0;
         exp_res[2*`N-1:`N] <= 0;
            exp_oflow<=0;
            exp_cout<=0;
         {exp_G,exp_L,exp_E}<=`NONE;
         exp_err <= ~(r_inp_valid==`V_BOTH);
            end

       `NOR: begin
         exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH) ? ~(r_opa | r_opb) : 0;
         exp_res[2*`N-1:`N] <= 0;
            exp_oflow <= 0;
            exp_cout <= 0;
         {exp_G,exp_L,exp_E} <= `NONE;
         exp_err<= ~(r_inp_valid==`V_BOTH);
            end

        `XOR:begin
          exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH) ? (r_opa ^ r_opb) : 0;
          exp_res[2*`N-1:`N] <= 0;
            exp_oflow <= 0;
            exp_cout <= 0;
          {exp_G,exp_L,exp_E} <= `NONE;
          exp_err <= ~(r_inp_valid==`V_BOTH);
            end

     `XNOR: begin
       exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH) ? ~(r_opa ^ r_opb) : 0;
       exp_res[2*`N-1:`N] <= 0;
            exp_oflow<= 0;
            exp_cout <= 0;
       {exp_G,exp_L,exp_E} <= `NONE;
       exp_err <= ~(r_inp_valid==`V_BOTH);
            end

    `NOT_A: begin
      exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH||r_inp_valid==`V_A) ? ~r_opa : 0;
      exp_res[2*`N-1:`N] <= 0;
            exp_oflow<= 0;
            exp_cout <= 0;
      {exp_G,exp_L,exp_E} <= `NONE;
      exp_err <= ~(r_inp_valid==`V_BOTH||r_inp_valid==`V_A);
            end

    `NOT_B: begin
      exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH||r_inp_valid==`V_B) ? ~r_opb : 0;
      exp_res[2*`N-1:`N] <= 0;
            exp_oflow <= 0;
            exp_cout<= 0;
      {exp_G,exp_L,exp_E} <= `NONE;
      exp_err <= ~(r_inp_valid==`V_BOTH||r_inp_valid==`V_B);
            end

   `SHR1_A: begin
     exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH||r_inp_valid==`V_A) ? r_opa>>1 : 0;
     exp_res[2*`N-1:`N] <= 0;
            exp_oflow<= 0;
            exp_cout <= 0;
     {exp_G,exp_L,exp_E} <= `NONE;
     exp_err<= ~(r_inp_valid==`V_BOTH||r_inp_valid==`V_A);
            end

   `SHL1_A: begin
     exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH||r_inp_valid==`V_A) ? r_opa<<1 : 0;
     exp_res[2*`N-1:`N] <= 0;
            exp_oflow<= 0;
            exp_cout <= 0;
     {exp_G,exp_L,exp_E} <= `NONE;
     exp_err<= ~(r_inp_valid==`V_BOTH||r_inp_valid==`V_A);
            end

  `SHR1_B: begin
    exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH||r_inp_valid==`V_B) ? r_opb>>1 : 0;
    exp_res[2*`N-1:`N] <= 0;
           exp_oflow <= 0;
           exp_cout <= 0;
    {exp_G,exp_L,exp_E} <= `NONE;
    exp_err<= ~(r_inp_valid==`V_BOTH||r_inp_valid==`V_B);
           end

  `SHL1_B: begin
    exp_res[`N-1:0] <= (r_inp_valid==`V_BOTH||r_inp_valid==`V_B) ? r_opb<<1 : 0;
    exp_res[2*`N-1:`N] <= 0;
           exp_oflow<=0;
           exp_cout<=0;
    {exp_G,exp_L,exp_E} <= `NONE;
    exp_err <= ~(r_inp_valid==`V_BOTH||r_inp_valid==`V_B);
           end


`ROL_A_B: begin
  rot_amt = r_opb[`WID-1:0];
  if (|r_opb[`N-1:`WID])
          exp_err <= 1;
          else
          exp_err<= 0;
  exp_res[`N-1:0] <=(r_opa<< rot_amt) |(r_opa >> (`N - rot_amt));
  exp_res[2*`N-1:`N] <= 0;
          exp_oflow<= 0;
          exp_cout <= 0;
  {exp_G,exp_L,exp_E} <= `NONE;
          end


`ROR_A_B: begin
  rot_amt = r_opb[`WID-1:0];
  if (|r_opb[`N-1:`WID])
          exp_err <= 1;
          else
          exp_err <= 0;
  exp_res[`N-1:0] <=(r_opa >> rot_amt) |(r_opa << (`N - rot_amt));
  exp_res[2*`N-1:`N] <= 0;
          exp_oflow <= 0;
          exp_cout <= 0;
  {exp_G,exp_L,exp_E} <= `NONE;
          end

default: begin
         exp_res <= 0;
         exp_cout <= 0;
         exp_oflow <= 0;
  {exp_G, exp_L, exp_E} <= `NONE;
         exp_err<=0;
         end

endcase
end
end
end
end

always @(negedge clk)
begin
if (!rst && r_ce)
begin
#1;

if (res !== exp_res)
$display("%-6s @%0t | MODE=%b CMD=%02h OPA=%3d OPB=%3d | RES=%0d EXP_RES=%0d","FAIL", $time, r_mode, r_cmd, r_opa, r_opb, res, exp_res);
else
$display("%-6s @%0t | MODE=%b CMD=%02h OPA=%3d OPB=%3d | RES=%0d","PASS", $time, r_mode, r_cmd, r_opa, r_opb, res);

if (err !== exp_err)
$display("FAIL_ERR @%0t | ERR=%b EXP_ERR=%b", $time, err, exp_err);

if (oflow !== exp_oflow)
$display("FAIL_OFLOW @%0t | OFLOW=%b EXP_OFLOW=%b",$time, oflow, exp_oflow);

if (cout !== exp_cout)
$display("FAIL_COUT @%0t | COUT=%b EXP_COUT=%b", $time, cout, exp_cout);

if ({G,L,E} !== {exp_G,exp_L,exp_E})
$display("FAIL_GLE @%0t | GLE=%b%b%b EXP=%b%b%b",$time, G,L,E, exp_G,exp_L,exp_E);

if (res === exp_res && err === exp_err && oflow === exp_oflow && cout === exp_cout && {G,L,E} === {exp_G,exp_L,exp_E})
pass_cnt = pass_cnt + 1;
else
fail_cnt = fail_cnt + 1;
end
end

initial begin
pass_cnt = 0;
fail_cnt = 0;
reset;
general_arithmetic;
general_logical;
unknown_input;
clock_enable;
invalid_inputs;
multiplication;
mul_change;
reset;
multiplication;
mul_change;


repeat(3) `clock_delay;

$display("=================================================");
$display(" SIMULATION COMPLETE");
$display(" PASS : %0d", pass_cnt);
$display(" FAIL : %0d", fail_cnt);
$display("=================================================");

$finish;
end



initial begin
$dumpfile("dump.vcd");
$dumpvars;
end

endmodule
