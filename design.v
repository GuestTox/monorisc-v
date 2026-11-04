module monoBitAdder (
    input in1,
    input in2,
    input c1,
    output o,
    output c2
);

    assign o = in1 ^ in2 ^ c1;
    assign c2 = (in1 & in2) | (c1 & (in1 ^ in2));

endmodule

module nBitFullAddSub #(parameter WIDTH) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cIn,
    input wire sub,
    output wire [WIDTH-1:0] out,
    output wire cOut
);
    wire [WIDTH-1:0] twosCompB;

    // inverting b for two's complement
    assign twosCompB = b ^ {WIDTH{sub}};
    // adding the 1 for cp2 as a carry in
    wire initial_cIn = sub ? 1'b1 : cIn;

    wire [WIDTH:0] carry;
    
    assign carry[0] = initial_cIn;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : addSubLoop
            monoBitAdder iterationAdd (
                .in1(a[i]),
                .in2(twosCompB[i]),
                .c1(carry[i]),
                .o(out[i]),
                .c2(carry[i+1])
            );
        end
    endgenerate
    
    assign cOut = carry[WIDTH];

endmodule

module nBitMultiplicator #(parameter WIDTH = 4) (
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2, 
    output [2*WIDTH-1:0] o 
);

    wire [WIDTH-1:0] partialProds [WIDTH-1:0];

    wire [WIDTH-1:0] sumOfRows [WIDTH-1:0];
    wire [WIDTH-1:0] rowCarry;

    genvar r, c;
    generate
        for (r = 0; r < WIDTH; r = r + 1) begin : rowGen
            for (c = 0; c < WIDTH; c = c + 1) begin : colGun
                assign partialProds[r][c] = in1[c] & in2[r];
            end
        end
    endgenerate

    assign o[0] = partialProds[0][0];
    
    wire [WIDTH-1:0] firstAcc = {1'b0, partialProds[0][WIDTH-1:1]};
    
    generate
        for (r = 1; r < WIDTH; r = r + 1) begin : rowAdders
            wire [WIDTH-1:0] accumIn = (r == 1) ? firstAcc : {rowCarry[r-1], sumOfRows[r-1][WIDTH-1:1]};

            nBitFullAddSub #(.WIDTH(WIDTH)) rowAdder (
                .a(accumIn),
                .b(partialProds[r]),
                .cIn(1'b0),
                .sub(1'b0),
                .out(sumOfRows[r]),
                .cOut(rowCarry[r])
            );

            assign o[r] = sumOfRows[r][0];
        end
    endgenerate

    generate
        for (c = 1; c < WIDTH; c = c + 1) begin : finalBits
            assign o[WIDTH - 1 + c] = sumOfRows[WIDTH-1][c];
        end
    endgenerate
    
    assign o[2*WIDTH-1] = rowCarry[WIDTH-1];

endmodule