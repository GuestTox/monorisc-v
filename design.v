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