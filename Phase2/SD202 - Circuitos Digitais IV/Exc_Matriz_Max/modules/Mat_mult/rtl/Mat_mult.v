// Code your design here
module Mat_mult(A, B, Result);

    //input and output ports.

    //The size 72 bits which is 3*3=9 elements, each of which is 8 bits wide.

    input [71:0] A;
    input [71:0] B;
    output [71:0] Result;// result value cant be greater that 64


    //internal variables

    reg [71:0] Result;
    reg [7:0] A1 [0:2][0:2];
    reg [7:0] B1 [0:2][0:2];
    reg [15:0] R1 [0:2][0:2]; 

    integer i,j,k;

    always@ (A or B) begin

        //Initialize the matrices-convert 1 D to 3D arrays

        {   A1[0][0],A1[0][1],A1[0][2],
            A1[1][0],A1[1][1],A1[1][2],
            A1[2][0],A1[2][1],A1[2][2]  } = A;

        {   B1[0][0],B1[0][1],B1[0][2],
            B1[1][0],B1[1][1],B1[1][2],
            B1[2][0],B1[2][1],B1[2][2]  } = B;

        i = 0;
        j = 0;
        k = 0;

        {   R1[0][0],R1[0][1],R1[0][2],
            R1[1][0],R1[1][1],R1[1][2],
            R1[2][0],R1[2][1],R1[2][2]  } = 72'd0; //initialize to zeros.

        //Matrix multiplication
        for(i=0;i < 3;i=i+1)
            for(j=0;j < 3;j=j+1)
                for(k=0;k < 3;k=k+1)
                    R1[i][j] = R1[i][j] + (A1[i][k] * B1[k][j]);


        Result = {  R1[0][0],R1[0][1],R1[0][2],
                    R1[1][0],R1[1][1],R1[1][2],
                    R1[2][0],R1[2][1],R1[2][2]  };

    end


endmodule 


