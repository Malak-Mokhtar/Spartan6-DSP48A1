module regs (
    rst,clk,en,in,num_reg,out
);
    parameter RSTTYPE = "ASYNC";
    parameter WIDTH = 4;

    input rst,clk,en,num_reg;
    input [WIDTH-1:0] in;
    output [WIDTH-1:0] out;

    reg [WIDTH-1:0] out_temp;

    generate
        if(RSTTYPE == "SYNC") begin
            always @(posedge clk) begin
                if(rst) begin
                    out_temp <= 0;
                end
                else if(en)
                    out_temp <= in;
            end
        end
        else if(RSTTYPE == "ASYNC") begin
            always @(posedge clk or posedge rst) begin
                if(rst) begin
                    out_temp <= 0;
                end
                else if(en)
                    out_temp <= in;
            end
        end
    endgenerate

    assign out = (num_reg == 0) ? in : out_temp;

endmodule

