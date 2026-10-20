module crc16_top (
    input  logic clk,
    input  logic rst_n,
    input  logic data_valid,
    input  logic last,
    input  logic [7:0] data_in,
    output logic [15:0] crc_out,
    output logic crc_valid
);
crc16 dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_valid(data_valid),
    .last(last),
    .data_in(data_in),
    .crc_out(crc_out),
    .crc_valid(crc_valid)
);
endmodule
