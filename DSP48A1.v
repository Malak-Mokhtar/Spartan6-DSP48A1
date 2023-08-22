module DSP48A1 (
    A,B,C,D,
    CLK,CARRYIN,OPMODE,BCIN,
    RSTA,RSTB,RSTM,RSTP,RSTC,RSTD,RSTCARRYIN,RSTOPMODE,
    CEA,CEB,CEM,CEP,CEC,CED,CECARRYIN,CEOPMODE,
    PCIN,
    BCOUT,PCOUT,P,M,CARRYOUT,CARRYOUTF
);

// -------------------------- PARAMETERS --------------------------  //

// Defines the number of pipeline registers in the A and B input paths:
parameter A0REG = 0;
parameter B0REG = 0; // first stages of the pipelines
parameter A1REG = 1; // second stages of the pipelines
parameter B1REG = 1;

// Defines the number of pipeline stages: (0 (no register) or 1 (registered))
parameter CREG = 1;
parameter DREG = 1;
parameter MREG = 1;
parameter PREG = 1;
parameter CARRYINREG = 1;
parameter CARRYOUTREG = 1;
parameter OPMODEREG = 1;

// Used in the carry cascade input, either the CARRYIN input will be considered or the value of opcode[5]:
parameter CARRYINSEL = "OPMODE5"; // or "CARRYIN" else tie output of mux to 0

// Defines whether the input to the B port is routed from the B input (attribute = DIRECT) or the cascaded input (BCIN) from the previous DSP48A1 slice (attribute = CASCADE).
parameter B_INPUT = "DIRECT"; // or "CASCADE" else tie output of mux to 0

// Selects whether all resets for the DSP48A1 slice should have a synchronous or asynchronous reset capability.
parameter RSTTYPE = "SYNC"; // or "ASYNC"


// ---------------------------- INPUTS ----------------------------  //

// ----- DATA PORTS ----- //

input [17:0] A; // to multiplier, and optionally to post-adder/subtracter depending on the value of OPMODE[1:0].
input [17:0] B; // to pre-adder/subtracter, to multiplier depending on OPMODE[4], or to post-adder/subtracter depending on OPMODE[1:0].
input [47:0] C; // to post-adder/subtracter.
input [17:0] D; // to pre-adder/subtracter. D[11:0] are concatenated with A and B and optionally sent to post-adder/subtracter depending on the value of OPMODE[1:0].
input CARRYIN; // to the post-adder/subtracter

// ----- CONTROL PORTS ----- //

input CLK; // DSP clock
input [7:0] OPMODE; // Control input to select the arithmetic operations of the DSP48A1 slice.

// ----- CLK ENABLE PORTS ----- //

input CEA; // Clock enable for the A port registers: (A0REG & A1REG).
input CEB; // Clock enable for the B port registers: (B0REG & B1REG).
input CEC; // Clock enable for the C port registers (CREG).
input CECARRYIN; // Clock enable for the carry-in register (CYI) and the carry-out register (CYO).
input CED; // Clock enable for the D port register (DREG).
input CEM; // Clock enable for the multiplier register (MREG).
input CEOPMODE; // Clock enable for the opmode register (OPMODEREG).
input CEP; // Clock enable for the P output port registers (PREG = 1).


// ----- RESET PORTS ----- //
/*
    All the resets are active high reset.
    They are either sync or async depending on the parameter RSTTYPE.
*/
input RSTA; // Reset for the A registers: (A0REG & A1REG).
input RSTB; // Reset for the B registers: (B0REG & B1REG).
input RSTC; // Reset for the C registers (CREG).
input RSTCARRYIN; // Reset for the carry-in register (CYI) and the carry-out register (CYO).
input RSTD; // Reset for the D register (DREG).
input RSTM; // Reset for the multiplier register (MREG).
input RSTOPMODE; // Reset for the opmode register (OPMODEREG).
input RSTP; // Reset for the P output registers (PREG = 1).

// ----- CASCADE PORTS ----- //

input [47:0] PCIN; // Cascade input for Port P.
input [17:0] BCIN; // Cascade input for Port B.


// ---------------------------- OUTPUTS ----------------------------  //

// ----- DATA PORTS ----- //

output [35:0] M; // 36-bit buffered multiplier data output, routable to the FPGA logic.
output [47:0] P; // Primary data output from the post-adder/subtracter.
output CARRYOUT; // Cascade carry out signal from post-adder/subtracter. This output is to be connected only to CARRYIN of adjacent DSP48A1 if multiple DSP blocks are used. 
output CARRYOUTF; // Carry out signal from post-adder/subtracter for use in the FPGA logic. It is a copy of the CARRYOUT signal that can be routed to the user logic.

// ----- CASCADE PORTS ----- //

output [17:0] BCOUT; // Cascade output for Port B.
output [47:0] PCOUT; // Cascade output for Port P.

// ---------------------------- INTERNAL SIGNALS ----------------------------  //

wire [17:0] B_BCIN_mux;
wire [17:0] D_mux;
wire [17:0] B0_mux;
wire [17:0] A0_mux;
wire [47:0] C_mux;
wire [7:0] opmode_mux;

wire [17:0] op1_out;
wire [17:0] op1_mux;

wire [17:0] B1_mux;
wire [17:0] A1_mux;

wire [35:0] op2_out;
wire [35:0] M_mux;
wire Carry_mux;
wire CYI_mux;

reg [47:0] X_mux;
reg [47:0] Z_mux;

wire op3_cout;
wire [47:0] op3_out;
wire [47:0] P_mux;

// ---------------------------- CODE ----------------------------  //

// ------- Combinational logic ------- //
assign B_BCIN_mux = (B_INPUT == "DIRECT") ? B : (B_INPUT == "CASCADE") ? BCIN : 0;


// ------- Level 1 FFs ------- //
// -- Data ports -- //
regs #(.RSTTYPE(RSTTYPE),.WIDTH(18)) D_REG (.rst(RSTD),.clk(CLK),.en(CED),.num_reg(DREG),.in(D),.out(D_mux));
regs #(.RSTTYPE(RSTTYPE),.WIDTH(18)) B0_REG (.rst(RSTB),.clk(CLK),.en(CEB),.num_reg(B0REG),.in(B_BCIN_mux),.out(B0_mux));
regs #(.RSTTYPE(RSTTYPE),.WIDTH(18)) A0_REG (.rst(RSTA),.clk(CLK),.en(CEA),.num_reg(A0REG),.in(A),.out(A0_mux));
regs #(.RSTTYPE(RSTTYPE),.WIDTH(48)) C_REG (.rst(RSTC),.clk(CLK),.en(CEC),.num_reg(CREG),.in(C),.out(C_mux));

// -- Control ports -- //
// opmode input has a register and mux pair in the design entry:
regs #(.RSTTYPE(RSTTYPE),.WIDTH(8)) OPMODE_REG (.rst(RSTOPMODE),.clk(CLK),.en(CEOPMODE),.num_reg(OPMODEREG),.in(OPMODE),.out(opmode_mux));


// ------- Combinational logic ------- //
// Pre-Adder/Subtracter
assign op1_out = opmode_mux[6] ? (D_mux-B0_mux) : (D_mux+B0_mux);
assign op1_mux = opmode_mux[4] ? op1_out : B0_mux;


// ------- Level 2 FFs ------- //
regs #(.RSTTYPE(RSTTYPE),.WIDTH(18)) B1_REG (.rst(RSTB),.clk(CLK),.en(CEB),.num_reg(B1REG),.in(op1_mux),.out(B1_mux));
regs #(.RSTTYPE(RSTTYPE),.WIDTH(18)) A1_REG (.rst(RSTA),.clk(CLK),.en(CEA),.num_reg(A1REG),.in(A0_mux),.out(A1_mux));


// ------- Combinational logic ------- //
// Multiplier
assign op2_out = B1_mux * A1_mux;
// Carry Cascade
assign Carry_mux = (CARRYINSEL == "OPMODE5") ? opmode_mux[5] : CARRYIN; //


// ------- Level 3 FFs ------- //
regs #(.RSTTYPE(RSTTYPE),.WIDTH(36)) M_REG (.rst(RSTM),.clk(CLK),.en(CEM),.num_reg(MREG),.in(op2_out),.out(M_mux));
regs #(.RSTTYPE(RSTTYPE),.WIDTH(1)) CYI_REG (.rst(RSTCARRYIN),.clk(CLK),.en(CECARRYIN),.num_reg(CARRYINREG),.in(Carry_mux),.out(CYI_mux));


// ------- Combinational logic ------- //
always @(*) begin
    // X mux
    case (opmode_mux[1:0])
       2'b00 : X_mux = 0;
       2'b01 : X_mux = M_mux;
       2'b10 : X_mux = P_mux;
       default: X_mux = {D_mux[11:0],A0_mux,B0_mux};
    endcase
    // Z mux
    case (opmode_mux[3:2])
       2'b00 : Z_mux = 0;
       2'b01 : Z_mux = PCIN;
       2'b10 : Z_mux = P_mux;
       default: Z_mux = C_mux;
    endcase
end

// Post-Adder/Subtracter
assign {op3_cout,op3_out} = opmode_mux[7] ? (Z_mux - (X_mux + CYI_mux)) : (Z_mux + X_mux + CYI_mux);


// ------- Level 4 FFs ------- //
regs #(.RSTTYPE(RSTTYPE),.WIDTH(1)) CYO_REG (.rst(RSTCARRYIN),.clk(CLK),.en(CECARRYIN),.num_reg(CARRYOUTREG),.in(op3_cout),.out(CARRYOUT));
regs #(.RSTTYPE(RSTTYPE),.WIDTH(48)) P_REG (.rst(RSTP),.clk(CLK),.en(CEP),.num_reg(PREG),.in(op3_out),.out(P_mux));


// ------- Outputs ------- //
assign BCOUT = B1_mux;
assign M = M_mux;
assign CARRYOUTF = CARRYOUT;
assign P = P_mux;
assign PCOUT = P_mux;

endmodule

