`timescale 1ns/1ns

module tb_Subtractor;

    parameter WIDTH = 8;
    reg [WIDTH-1:0] x,y;
    reg Bin;
    wire [WIDTH-1:0] D;
    wire Bout;

    Subtractor #(.WIDTH(WIDTH)) dut 
    (
        .x(x),
        .y(y),
        .Bin(Bin),
        .D(D),
        .Bout(Bout)
    );

    initial begin
        $dumpfile("Subtractor.vcd");
        $dumpvars(0, tb_Subtractor);
        $monitor("At time %t: x=%d, y=%d, Bin=%b, D=%b, Bout=%b", 
                $time, dut.x, dut.y, dut.Bin, dut.D, dut.Bout);

        // Inicialização
        x = 0;
        y = 0;
        Bin = 0;

        #10 
        x = 3;
        y = 1;
        Bin = 0; // 3-1-0 = 2

        #10
        x = 3;
        y = 1;
        Bin = 1; // 3-1-1 = 1

        #10
        x = 1;
        y = 3;
        Bin = 0; // 1-3-0 = -2 (Bout=1, D=2)

        #10
        x = 1;
        y = 3;
        Bin = 1; // 1-3-1 = -3 (Bout=1, D=1)

        // Estímulos do teste aqui

        #50 $finish;
    end

endmodule
