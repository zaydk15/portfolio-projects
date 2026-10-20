module crc16 (
    input  logic clk,
    input  logic rst_n,
    input  logic data_valid,
    input  logic last,
    input  logic [7:0] data_in,
    output logic [15:0] crc_out,
    output logic crc_valid
);

logic [15:0] crc_q;
logic last_q;

function automatic [15:0] next_crc(input [15:0] crc, input [7:0] d);
    bit [15:0] c = crc;
    bit [7:0] b = d;
    // bytewise update (MSB-first)
    for (int i = 0; i < 8; i++) begin
        bit bitval = c[15] ^ b[7-i];
        c = {c[14:0], 1'b0};
        if (bitval) c = c ^ 16'h1021;
    end
    return c;
endfunction

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_q <= 16'hFFFF;
        crc_out <= 16'h0000;
        crc_valid <= 1'b0;
        last_q <= 1'b0;
    end else begin
        last_q <= data_valid && last;
        if (data_valid) begin
            crc_q <= next_crc(crc_q, data_in);
        end
        if (last_q) begin
            crc_out <= crc_q;
            crc_valid <= 1'b1;
            crc_q <= 16'hFFFF; // re-seed for next frame
        end else begin
            crc_valid <= 1'b0;
        end
    end
end

endmodule