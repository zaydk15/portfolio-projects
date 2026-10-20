interface crc_if(input logic clk);

    // DUT control / status
    logic rst_n;
    logic data_valid;
    logic last;
    logic [7:0] data_in;
    logic [15:0] crc_out;
    logic crc_valid;

    // NEW: brute-force match flag visible in waveform
    logic crc_match;

endinterface
