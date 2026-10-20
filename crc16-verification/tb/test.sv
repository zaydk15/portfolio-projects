`timescale 1ns/1ps
import crc_ref_pkg::*;
import crc_env_pkg::*;

module test;
  logic clk = 0; always #5 clk = ~clk;
  crc_if cif(clk);
  crc_env env;

  // DUT instantiation
  crc16_top dut (
    .clk(clk),
    .rst_n(cif.rst_n),
    .data_valid(cif.data_valid),
    .last(cif.last),
    .data_in(cif.data_in),
    .crc_out(cif.crc_out),
    .crc_valid(cif.crc_valid)
  );

  // basic reset + defaults
  initial begin
    cif.rst_n = 0;
    cif.data_valid = 0;
    cif.last = 0;
    cif.data_in = 0;
    cif.crc_match = 0;
    #20 cif.rst_n = 1;
  end

  // start environment & finish/check
  initial begin
    env = new(cif);
    env.run();

    // allow time for generator to send directed+random packets
    #5000;

    if (env.scb.pass) $display("\n✅ ALL TESTS PASSED (brute-force scoreboard pass=%0d)", env.scb.pass);
    else              $display("\n❌ SOME TEST FAILED (brute-force scoreboard pass=%0d)", env.scb.pass);

    // keep final match flag visible for a little while, then finish
    #50;
    $finish;
  end
endmodule
