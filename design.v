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

    wire [WIDTH-1:0] partialProds [0:WIDTH-1];

    wire [WIDTH-1:0] sumOfRows [0:WIDTH-1];
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
    assign sumOfRows[0] = firstAcc;
    assign rowCarry[0]  = 1'b0;

    generate
        for (r = 1; r < WIDTH; r = r + 1) begin : rowAdders
            wire [WIDTH-1:0] accumIn = {rowCarry[r-1], sumOfRows[r-1][WIDTH-1:1]};

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

module combinationalDivider #(parameter WIDTH = 32) (
    input wire [WIDTH-1:0] dividend,
    input wire [WIDTH-1:0] divisor,
    output wire [WIDTH-1:0] quotient,
    output wire [WIDTH-1:0] remainder
);

    
    wire [WIDTH-1:0] currentRem [0:WIDTH];
    wire [WIDTH-1:0] outSub [0:WIDTH-1];
    wire [WIDTH-1:0] quotientBits;

    assign currentRem[0] = { {(WIDTH-1){1'b0}}, dividend[WIDTH-1] };

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : div_rows
            
            nBitFullAddSub #(.WIDTH(WIDTH)) row_sub (
                .a(current_rem[i]),
                .b(divisor),
                .cIn(1'b0),
                .sub(1'b1), 
                .out(outSub[i]),
                .cOut() 
            );

            wire subtract_successful = (current_rem[i] >= divisor);
            assign quotientBits[WIDTH-1-i] = subtract_successful;
            
            wire [WIDTH-1:0] next_rem_base = subtract_successful ? outSub[i] : current_rem[i];

            if (i < WIDTH-1) begin: next_row_connection
                assign current_rem[i+1] = { next_rem_base[WIDTH-2:0], dividend[WIDTH-2-i] };
            end else begin: final_row_connection
                assign remainder = next_rem_base;
            end
        end
    endgenerate

    assign quotient = quotientBits;

endmodule