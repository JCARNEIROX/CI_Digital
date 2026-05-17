module Mux_2x1 #( parameter N = 8 ) (
    input wire  [N-1:0] a,
    input wire  [N-1:0] b,
    input wire         sel,
    output wire [N-1:0] out
) ;

    // Logica do Mux
    assign out = sel ? b : a;

endmodule
