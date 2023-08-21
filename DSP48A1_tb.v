module DSP48A1_tb ();

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


reg [17:0] A,B,D,BCIN;
reg [47:0] C,PCIN;
reg CARRYIN, CLK;
reg [7:0] OPMODE;
reg CEA,CEB,CEC,CECARRYIN,CED,CEM,CEOPMODE,CEP;
reg RSTA,RSTB,RSTC,RSTCARRYIN,RSTD,RSTM,RSTOPMODE,RSTP; 

wire [35:0] M;
wire [47:0] P,PCOUT;
wire CARRYOUT,CARRYOUTF; 
wire [17:0] BCOUT;

integer i = 0;

    
// Instantiation:
DSP48A1 #(.A0REG(A0REG),.B0REG(B0REG),.A1REG(A1REG),.B1REG(B1REG),.CREG(CREG),.DREG(DREG),.MREG(MREG),.PREG(PREG),
           .CARRYINREG(CARRYINREG),.CARRYOUTREG(CARRYOUTREG),.OPMODEREG(OPMODEREG),.CARRYINSEL(CARRYINSEL),.B_INPUT(B_INPUT),.RSTTYPE(RSTTYPE))
            DSP_dut (
                        .A(A),.B(B),.C(C),.D(D),
                        .CLK(CLK),.CARRYIN(CARRYIN),.OPMODE(OPMODE),.BCIN(BCIN),
                        .RSTA(RSTA),.RSTB(RSTB),.RSTM(RSTM),.RSTP(RSTP),.RSTC(RSTC),.RSTD(RSTD),.RSTCARRYIN(RSTCARRYIN),.RSTOPMODE(RSTOPMODE),
                        .CEA(CEA),.CEB(CEB),.CEM(CEM),.CEP(CEP),.CEC(CEC),.CED(CED),.CECARRYIN(CECARRYIN),.CEOPMODE(CEOPMODE),
                        .PCIN(PCIN),
                        .BCOUT(BCOUT),.PCOUT(PCOUT),.P(P),.M(M),.CARRYOUT(CARRYOUT),.CARRYOUTF(CARRYOUTF)
                    );


initial begin
    CLK = 0;
    forever #1 CLK = ~CLK;
end

initial begin
    // Assert all resets
    {RSTA,RSTB,RSTC,RSTCARRYIN,RSTD,RSTM,RSTOPMODE,RSTP} = 8'b1111_1111;
    // Force all inputs with zeroes
    {A,B,C,D,CARRYIN,OPMODE} = 0;
    {CEA,CEB,CEC,CECARRYIN,CED,CEM,CEOPMODE,CEP} = 0;
    {PCIN,BCIN} = 0;
    #50;
    // De-assert all resets
    {RSTA,RSTB,RSTC,RSTCARRYIN,RSTD,RSTM,RSTOPMODE,RSTP} = 0;
    // Force all clock enables with 1
    {CEA,CEB,CEC,CECARRYIN,CED,CEM,CEOPMODE,CEP} = 8'b1111_1111;
    #100;
    //for (i = 0; i<1000 ; i=i+1) begin
    //    @(negedge CLK)
    //    A = $random;
    //    B = $random;
    //    C = $random;
    //    D = $random;
    //    CARRYIN = $random;
    //    OPMODE = $random;
    //    PCIN = $random;
    //    BCIN = $random;
    //end

    OPMODE[6] = 1; // D-B
    OPMODE[4] = 0;
    CARRYIN = 0;
    OPMODE[5] = 1;
    OPMODE[1:0] = 2'b10;
    OPMODE[3:2] = 2'b11;
    OPMODE[7] = 0;
    D = 255000; 
    C = 1200000;
    @(negedge CLK);
    A = 100000;
    B = 67000;


    #50 $stop;

end

endmodule
