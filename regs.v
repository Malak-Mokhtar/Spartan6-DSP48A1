module regs (
    rst,clk,en,in,out
);
    parameter RSTTYPE = "ASYNC";
    parameter NUM_REGS = 1;
    parameter WIDTH = 4;

    input rst,clk,en;
    input [WIDTH-1:0] in;
    output [WIDTH-1:0] out;

    reg [NUM_REGS-1:0] shift_reg [WIDTH-1:0];
    reg [WIDTH-1:0] out_temp;
    integer i = 0;

    generate
        if(RSTTYPE == "SYNC") begin
            always @(posedge clk) begin
                if(rst) begin
                    out_temp <= 0;
                    for (i = 0; i<WIDTH ; i=i+1) begin
                        shift_reg[i] <= 0;
                    end
                end
                else if(en)
                    for (i=0; i<WIDTH ; i= i+1) begin
                       shift_reg[i] <= {shift_reg[i][NUM_REGS-2:0],in[i]};
                       out_temp[i] <= shift_reg[i][NUM_REGS-1:0];
                    end
            end
        end
        else if(RSTTYPE == "ASYNC") begin
            always @(posedge clk or posedge rst) begin
                if(rst) begin
                    out_temp <= 0;
                    for (i = 0; i<WIDTH ; i=i+1) begin
                        shift_reg[i] <= 0;
                    end
                end
                else if(en)
                    for (i=0; i<WIDTH ; i= i+1) begin
                       shift_reg[i] <= {shift_reg[i][NUM_REGS-2:0],in[i]};
                       out_temp[i] <= shift_reg[i][NUM_REGS-1:0];
                    end
            end
        end
    endgenerate

    assign out = (NUM_REGS == 0) ? in : out_temp;

endmodule

