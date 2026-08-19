`timescale 1ns/1ns

module tb_Mux_2x1;
    
    parameter N =8; 
    reg [N-1:0] a, b;
    reg sel;
    wire [N-1:0] out;
    

    Mux_2x1 #(
        .N(N)
    ) dut(
        .a(a),
        .b(b),
        .sel(sel),
        .out(out)
    );

    initial begin
        $dumpfile("Mux_2x1.vcd");
        $dumpvars(0, tb_Mux_2x1);
        $monitor("Time: %0t | a: %b | b: %b | sel: %b | out: %b", $time, a, b, sel, out);

        // Inicialização
        a = 8'd1;
        b = 8'd0;
        sel = 1'b0;

        #5;
        a = 8'd2;
        b = 8'd4;
        sel = 1'b1;
        // Estímulos do teste aqui

        #20 
        $finish;
    end

endmodule
