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

reg [35:0] M_expected;
reg [47:0] P_expected;
reg Carry_expected; 
reg [17:0] BCOUT_expected;

reg check1, check2, check3;

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
    forever #2 CLK = ~CLK;
end

// In this testbench, all inputs would be randomized except for the OPMODEs

/* --------------------------------------- OPMODE Pin Descriptions --------------------------------------- //

    OPMODE[1:0] Specifies the source of the X input to the post-adder/subtracter
                2'b00 - Place all zeroes (disable the post-adder/subtracter and propagate the Z result to P) 
                2'b01 - Use the multiplier product
                2'b10 - Use the P output signal (accumulator)
                2'b11 - Use the concatenated D:A:B input signals
    
    OPMODE[3:2] Specifies the source of the Z input to the post-adder/subtracter
                2'b00 - Place all zeroes (disable the post-adder/subtracter and propagate the multiplier product or other X result to P) 
                2'b01 - Use the PCIN
                2'b10 - Use the P output signal (accumulator)
                2'b11 - Use the C port
    
    OPMODE[4]   Specifies the use of the pre-adder/subtracter
                1'b0  - Bypass the pre-adder supplying the data on port B directly to the multiplier
                1'b1  - Selects to use the pre-adder adding or subtracting the values on the B and D ports prior to the multiplier

    OPMODE[5]   Forces a value on the carry input of the carry-in-register (CYI) or direct to the CIN to the post-adder. Only applicable when CARRYINSEL = OPMODE5

    OPMODE[6]  Specifies whether the pre-adder/subtracter is an adder or subtracter
               1'b0   - Perform addition operation
               1'b1   - Perform subtraction operation (D-B)

    OPMODE[7]  Specifies whether the post-adder/subtracter is an adder or subtracter
               1'b0   - Perform addition operation
               1'b1   - Perform subtraction operation (Z-(X+CIN))

// --------------------------------------------------------------------------------------------------------- */

initial begin
    // Assert all resets
    {RSTA,RSTB,RSTC,RSTCARRYIN,RSTD,RSTM,RSTOPMODE,RSTP} = 8'b1111_1111;
    // Force all inputs with zeroes
    {A,B,C,D,CARRYIN,OPMODE} = 0;
    {CEA,CEB,CEC,CECARRYIN,CED,CEM,CEOPMODE,CEP} = 0;
    {PCIN,BCIN} = 0;
    {check1,check2,check3} = 0;
    #50;
    // De-assert all resets
    {RSTA,RSTB,RSTC,RSTCARRYIN,RSTD,RSTM,RSTOPMODE,RSTP} = 0;
    // Force all clock enables with 1
    {CEA,CEB,CEC,CECARRYIN,CED,CEM,CEOPMODE,CEP} = 8'b1111_1111;
    #100;

// --------------------------------------------------------------------  OPMODE[6] & OPMODE[4] -------------------------------------------------------------------- //
// ---------------------------------- Testcase 1: ---------------------------------- //
    i = 1;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 1; // Pre-Adder/Subtracter selector: D-B0
    OPMODE[4] = 1; // mux selector: Pre-Adder/Subtracter output (D-B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b01; // X mux selector:  Use the multiplier product ((D-B0)xA1)
    OPMODE[3:2] = 2'b11; // Z mux selector: Use the C Port
    OPMODE[7] = 0; // Post-Adder/Subtracter selector: ((D-B0)xA1) + C
    BCOUT_expected = D-B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (M_expected + C) + OPMODE[5]; // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 2: ---------------------------------- //
    i = 2;
    D = $random;
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 1; // mux selector: Pre-Adder/Subtracter output (D+B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b01; // X mux selector:  Use the multiplier product ((D+B0)xA1)
    OPMODE[3:2] = 2'b11; // Z mux selector: Use the C Port
    OPMODE[7] = 0; // Post-Adder/Subtracter selector: ((D+B0)xA1) + C
    BCOUT_expected = D+B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (M_expected + C) + OPMODE[5]; // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 3: ---------------------------------- //
    i = 3;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b01; // X mux selector:  Use the multiplier product ((D+B0)xA1)
    OPMODE[3:2] = 2'b11; // Z mux selector: Use the C Port
    OPMODE[7] = 0; // Post-Adder/Subtracter selector: ((D+B0)xA1) + C
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (M_expected + C) + OPMODE[5]; // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 4: ---------------------------------- //
    i = 4;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 1; // Pre-Adder/Subtracter selector: D-B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b01; // X mux selector:  Use the multiplier product ((D+B0)xA1)
    OPMODE[3:2] = 2'b11; // Z mux selector: Use the C Port
    OPMODE[7] = 0; // Post-Adder/Subtracter selector: ((D+B0)xA1) + C
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (M_expected + C) + OPMODE[5]; // Since CARRYINSEL = OPMODE5
    check3 = 1;

// --------------------------------------------------------------------  OPMODE[1:0] & OPMODE[3:2] -------------------------------------------------------------------- //
// ---------------------------------- Testcase 5: ---------------------------------- //
    i = 5;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b00; // X mux selector: 0
    OPMODE[3:2] = 2'b01; // Z mux selector: PCIN
    OPMODE[7] = 1; // Post-Adder/Subtracter selector: ((PCIN-(0 + C))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (PCIN - (0 + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;
// ---------------------------------- Testcase 6: ---------------------------------- //
    i = 6;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b00; // X mux selector: 0
    OPMODE[3:2] = 2'b10; // Z mux selector: PCOUT (feedback)
    OPMODE[7] = 1; // Post-Adder/Subtracter selector: ((PCOUT-(0 + C))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (PCOUT - (0 + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 7: ---------------------------------- //
    i = 7;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b00; // X mux selector: 0
    OPMODE[3:2] = 2'b11; // Z mux selector: C
    OPMODE[7] = 1; // Post-Adder/Subtracter selector: ((C-(0 + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (C - (0 + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 8: ---------------------------------- //
    i = 8;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b00; // X mux selector: 0
    OPMODE[3:2] = 2'b00; // Z mux selector: 0
    OPMODE[7] = 1; // Post-Adder/Subtracter selector: ((0-(0 + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (0 - (0 + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 9: ---------------------------------- //
    i = 9;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b01; // X mux selector: Multiplier output
    OPMODE[3:2] = 2'b00; // Z mux selector: 0
    OPMODE[7] = 0; // Post-Adder/Subtracter selector: ((0+(M + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (0 + (M_expected + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 10: ---------------------------------- //
    i = 10;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b10; // X mux selector: PCOUT (feedback)
    OPMODE[3:2] = 2'b00; // Z mux selector: 0
    OPMODE[7] = 0; // Post-Adder/Subtracter selector: ((0+(PCOUT + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (0 + (PCOUT + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 11: ---------------------------------- //
    i = 11;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b11; // X mux selector: D:A:B
    OPMODE[3:2] = 2'b00; // Z mux selector: 0
    OPMODE[7] = 0; // Post-Adder/Subtracter selector: ((0+({D[11:0],A,B} + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (0 + ({D[11:0],A,B} + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 12: ---------------------------------- //
    i = 12;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b01; // X mux selector: Multiplier output
    OPMODE[3:2] = 2'b01; // Z mux selector: PCIN
    OPMODE[7] = 1; // Post-Adder/Subtracter selector: ((PCIN-(M + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (PCIN - (M_expected + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 13: ---------------------------------- //
    i = 13;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b01; // X mux selector: Multiplier output
    OPMODE[3:2] = 2'b10; // Z mux selector: PCOUT (feedback)
    OPMODE[7] = 1; // Post-Adder/Subtracter selector: ((PCOUT-(M + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (PCOUT - (M_expected + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 14: ---------------------------------- //
    i = 14;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b01; // X mux selector: Multiplier output
    OPMODE[3:2] = 2'b11; // Z mux selector: C
    OPMODE[7] = 1; // Post-Adder/Subtracter selector: ((C-(M + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (C - (M_expected + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 15: ---------------------------------- //
    i = 15;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b10; // X mux selector: PCOUT feedback
    OPMODE[3:2] = 2'b01; // Z mux selector: PCIN
    OPMODE[7] = 1; // Post-Adder/Subtracter selector: ((PCIN-(PCOUT + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (PCIN - (PCOUT + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 16: ---------------------------------- //
    i = 16;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b10; // X mux selector: PCOUT feedback
    OPMODE[3:2] = 2'b10; // Z mux selector: PCOUT feedback
    OPMODE[7] = 0; // Post-Adder/Subtracter selector: ((PCOUT+(PCOUT + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (PCOUT + (PCOUT + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 17: ---------------------------------- //
    i = 17;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b10; // X mux selector: PCOUT feedback
    OPMODE[3:2] = 2'b11; // Z mux selector: C
    OPMODE[7] = 0; // Post-Adder/Subtracter selector: ((C+(PCOUT + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (C + (PCOUT + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

// ---------------------------------- Testcase 18: ---------------------------------- //
    i = 18;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b11; // X mux selector: D:A:B
    OPMODE[3:2] = 2'b11; // Z mux selector: C
    OPMODE[7] = 0; // Post-Adder/Subtracter selector: ((C+(D:A:B + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (C + ({D[11:0],A,B} + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

    // ---------------------------------- Testcase 19: ---------------------------------- //
    i = 19;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b11; // X mux selector: D:A:B
    OPMODE[3:2] = 2'b10; // Z mux selector: PCOUT
    OPMODE[7] = 1; // Post-Adder/Subtracter selector: ((POUTC-(D:A:B + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (PCOUT - ({D[11:0],A,B} + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;
    
    // ---------------------------------- Testcase 20: ---------------------------------- //
    i = 20;
    D = $random; 
    C = $random;
    // OPMODES provided here since OPMODEREG = 1
    OPMODE[6] = 0; // Pre-Adder/Subtracter selector: D+B0
    OPMODE[4] = 0; // mux selector: Bypass the pre-adder supplying the data on port B directly to the multiplier (B0)

    @(negedge CLK); // Since A0REG,B0REG = 0
    A = $random; // A1
    B = $random; // B1
    OPMODE[5] = $random; // CARRYINSEL = OPMODE5


    @(negedge CLK);
    // Carry Cascade mux inputs:
    CARRYIN = $random;
    OPMODE[1:0] = 2'b11; // X mux selector: D:A:B
    OPMODE[3:2] = 2'b01; // Z mux selector: PCIN
    OPMODE[7] = 1; // Post-Adder/Subtracter selector: ((PCIN-(D:A:B + Carry))
    BCOUT_expected = B;
    check1 = 1;

    @(negedge CLK)
    M_expected = BCOUT_expected*A;
    check2 = 1;

    @(negedge CLK)
    {Carry_expected,P_expected} = (PCIN - ({D[11:0],A,B} + OPMODE[5])); // Since CARRYINSEL = OPMODE5
    check3 = 1;

    #100 $stop;

end

always @(i) begin
    $display("Testcase, %d",i);
end

// -------------------------------------------- SELF-CHECKING -------------------------------------------- //
always @(check1) begin
    if(check1) begin
        @(posedge CLK);
        #1  if(BCOUT_expected !== BCOUT) begin
                $display("Error BCOUT");
                $stop;
            end
        check1 = 0;
    end
end

always @(check2) begin
    if (check2) begin
        @(posedge CLK);
        #1  if (M_expected !== M) begin
                $display("Error M");
                $stop;
            end
        check2 = 0;
    end
end

always @(check3) begin
    if (check3) begin
        @(posedge CLK) #1;
        if (P_expected !== P) begin
            $display("Error P");
            $stop;
        end
        if (P_expected !== PCOUT) begin
            $display("Error PCOUT");
            $stop;
        end
        if (Carry_expected !== CARRYOUT) begin
            $display("Error CARRYOUT");
            $stop;
        end
        if (Carry_expected !== CARRYOUTF) begin
            $display("Error CARRYOUTF");
            $stop;
        end
        check3 = 0;
    end
end

endmodule
