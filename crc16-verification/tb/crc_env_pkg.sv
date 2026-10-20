package crc_env_pkg;

  import crc_ref_pkg::*; // golden model

  // ---------------- Transaction ----------------
  class crc_transaction;
    rand byte data[];
    rand int unsigned length;
    bit [15:0] exp_crc;   // expected (computed by generator or ref)
    bit [15:0] dut_crc;   // captured by monitor
    constraint len_c { length inside {[1:20]}; data.size()==length; }

    function new();
    endfunction

    function crc_transaction copy();
      crc_transaction t = new();
      t.length = length;
      t.data   = new[length];
      foreach (data[i]) t.data[i] = data[i];
      t.exp_crc = exp_crc;
      t.dut_crc = dut_crc;
      return t;
    endfunction
  endclass

  // ---------------- Generator ----------------
  class crc_generator;
    mailbox #(crc_transaction) gen2drv, gen2scb;
    virtual crc_if vif;

    function new(mailbox #(crc_transaction) d, mailbox #(crc_transaction) s, virtual crc_if v);
      gen2drv = d; gen2scb = s; vif = v;
    endfunction

    task run();
      crc_transaction tr;
      @(posedge vif.clk); wait (vif.rst_n);

      // Directed packet "123456789" (classic CRC test vector)
      tr = new();
      tr.length = 9;
      tr.data = {"1","2","3","4","5","6","7","8","9"};
      // compute expected CRC (brute force generator-side)
      tr.exp_crc = crc16_ref(tr.data);
      gen2drv.put(tr);
      gen2scb.put(tr.copy());

      // Some random packets
      repeat (5) begin
        tr = new();
        // choose random length 3..8
        tr.length = ($urandom_range(3,8));
        tr.data   = new[tr.length];
        for (int i=0; i<tr.length; i++) tr.data[i] = $urandom();
        tr.exp_crc = crc16_ref(tr.data);
        gen2drv.put(tr);
        gen2scb.put(tr.copy());
        // small gap between transactions
        repeat (10) @(posedge vif.clk);
      end
    endtask
  endclass

  // ---------------- Driver ----------------
  class crc_driver;
    mailbox #(crc_transaction) gen2drv;
    virtual crc_if vif;

    function new(mailbox #(crc_transaction) m, virtual crc_if v);
      gen2drv = m; vif = v;
    endfunction

    task run();
      crc_transaction tr;
      forever begin
        gen2drv.get(tr); // blocking get

        // Drive the packet bytes onto interface (1 cycle per byte)
        for (int i=0; i<tr.length; i++) begin
          @(posedge vif.clk);
          vif.data_in    = tr.data[i];
          vif.data_valid = 1;
          vif.last       = (i == tr.length-1);
          // hold for one cycle
          @(posedge vif.clk);
          // clear valid (we clear next cycle)
          vif.data_valid = 0;
          vif.last       = 0;
        end

        // small idle time between packets
        repeat (5) @(posedge vif.clk);
      end
    endtask
  endclass

  // ---------------- Monitor ----------------
  class crc_monitor;
    mailbox #(crc_transaction) mon2scb;
    virtual crc_if vif;

    function new(mailbox #(crc_transaction) m, virtual crc_if v);
      mon2scb = m; vif = v;
    endfunction

    task run();
      crc_transaction tr;
      forever begin
        @(posedge vif.clk);
        if (vif.crc_valid) begin
          // When DUT indicates CRC ready, capture it and send to scoreboard
          tr = new();
          tr.dut_crc = vif.crc_out;
          mon2scb.put(tr);
        end
      end
    endtask
  endclass

  // ---------------- Scoreboard ----------------
  class crc_scoreboard;
    mailbox #(crc_transaction) expq, actq;
    virtual crc_if vif;
    bit pass = 1;

    function new(mailbox #(crc_transaction) e, mailbox #(crc_transaction) a, virtual crc_if v);
      expq = e; actq = a; vif = v;
    endfunction

    task run();
      crc_transaction exp, act;
      forever begin
        // get expected (from generator) and actual (from monitor)
        expq.get(exp);
        actq.get(act);

        // compute expected CRC (brute-force safety)
        exp.exp_crc = crc16_ref(exp.data);

        // compare
        if (exp.exp_crc == act.dut_crc) begin
          vif.crc_match = 1;
          $display("DUT CRC = %h | REF CRC = %h (MATCH) @%0t", act.dut_crc, exp.exp_crc, $time);
        end else begin
          vif.crc_match = 0;
          $display("DUT CRC = %h | REF CRC = %h (MISMATCH) @%0t", act.dut_crc, exp.exp_crc, $time);
          pass = 0;
        end
      end
    endtask
  endclass

  // ---------------- ENV (connects everything) ----------------
  class crc_env;
    crc_generator gen;
    crc_driver drv;
    crc_monitor mon;
    crc_scoreboard scb;

    mailbox #(crc_transaction) gen2drv = new();
    mailbox #(crc_transaction) gen2scb = new();
    mailbox #(crc_transaction) mon2scb = new();

    virtual crc_if vif;

    function new(virtual crc_if v);
      vif = v;
      gen = new(gen2drv, gen2scb, vif);
      drv = new(gen2drv, vif);
      mon = new(mon2scb, vif);
      scb = new(gen2scb, mon2scb, vif);
    endfunction

    task run();
      fork
        gen.run();
        drv.run();
        mon.run();
        scb.run();
      join_none
    endtask
  endclass

endpackage
