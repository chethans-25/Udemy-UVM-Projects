
`include "uvm_macros.svh"
import uvm_pkg::*;

class spi_config extends uvm_object;
  `uvm_object_utils(spi_config)

  function new(string name = "spi_config");
    super.new(name);
  endfunction

  uvm_active_passive_enum is_active = UVM_ACTIVE;

endclass



typedef enum bit [2:0]
  {
  readd    = 0,
  writed   = 1,
  rstdut   = 2,
  writeerr = 3,
  readerr  = 4
  } oper_mode;

class transaction extends uvm_sequence_item;

  function new(string name = "transaction" );
    super.new(name);
  endfunction

  rand oper_mode op;
  logic wr;
  logic rst;
  randc logic [7:0] addr;
  rand logic [7:0] din;
  logic [7:0] dout;
  logic done;
  logic err;

  `uvm_object_utils_begin (transaction)
    `uvm_field_int (wr, UVM_ALL_ON)
    `uvm_field_int (rst, UVM_ALL_ON)
    `uvm_field_int (addr, UVM_ALL_ON)
    `uvm_field_int (din, UVM_ALL_ON)
    `uvm_field_int (dout, UVM_ALL_ON)
    `uvm_field_int (done, UVM_ALL_ON)
    `uvm_field_int (err, UVM_ALL_ON)
    `uvm_field_enum (oper_mode, op, UVM_DEFAULT)
  `uvm_object_utils_end

  //constraints
  constraint addr_c {addr <= 10;}
  constraint addr_err_c {addr > 31;}


endclass


// write_data sequence
class write_data extends uvm_sequence #(transaction);
  `uvm_object_utils(write_data)

  transaction tr;

  function new( string name = "write_data");
    super.new(name);
  endfunction

  virtual task body();
  repeat(15)
  begin
    tr = transaction::type_id::create("tr");

    tr.addr_c.constraint_mode(1);
    tr.addr_err_c.constraint_mode(0);

    start_item(tr);

    assert(tr.randomize);

    tr.op = writed;

    finish_item(tr);
  end
  endtask

endclass


// write_err sequence
class write_err extends uvm_sequence #(transaction);
  `uvm_object_utils(write_err)

  transaction tr;

  function new( string name = "write_err");
    super.new(name);
  endfunction

  virtual task body();
  repeat(15)
  begin
    tr = transaction::type_id::create("tr");

    tr.addr_c.constraint_mode(0);
    tr.addr_err_c.constraint_mode(1);

    start_item(tr);

    assert(tr.randomize);

    tr.op = writeerr;

    finish_item(tr);
  end
  endtask

endclass

//read_data sequence
class read_data extends uvm_sequence #(transaction);
  `uvm_object_utils(read_data)

  transaction tr;

  function new( string name = "read_data");
    super.new(name);
  endfunction

  virtual task body();
  repeat(15)
  begin
    tr = transaction::type_id::create("tr");

    tr.addr_c.constraint_mode(1);
    tr.addr_err_c.constraint_mode(0);

    start_item(tr);

    assert(tr.randomize);

    tr.op = readd;

    finish_item(tr);
  end
  endtask

endclass


//read_err sequence
class read_err extends uvm_sequence #(transaction);
  `uvm_object_utils(read_err)

  transaction tr;

  function new( string name = "read_err");
    super.new(name);
  endfunction

  virtual task body();
  repeat(15)
  begin
    tr = transaction::type_id::create("tr");

    tr.addr_c.constraint_mode(0);
    tr.addr_err_c.constraint_mode(1);

    start_item(tr);

    assert(tr.randomize);

    tr.op = readerr;

    finish_item(tr);
  end
  endtask

endclass

//rst_dut sequence
class rst_dut extends uvm_sequence #(transaction);
  `uvm_object_utils(rst_dut)

  transaction tr;

  function new( string name = "rst_dut");
    super.new(name);
  endfunction

  virtual task body();
  repeat(15)
  begin
    tr = transaction::type_id::create("tr");

    //address does not matter for reset, but there should be any conflict( i,e both contraints should not be enabled at the same time)
    tr.addr_c.constraint_mode(0);
    tr.addr_err_c.constraint_mode(1);

    start_item(tr);

    assert(tr.randomize);

    tr.op = rstdut;

    finish_item(tr);
  end
  endtask

endclass

//write bulk read bulk sequence
//writeb_readb sequence
class writeb_readb extends uvm_sequence #(transaction);
  `uvm_object_utils(writeb_readb)

  transaction tr;

  function new( string name = "writeb_readb");
    super.new(name);
  endfunction

  virtual task body();
  //loop for writed
  repeat(15)
  begin
    tr = transaction::type_id::create("tr");
    tr.addr_c.constraint_mode(1);
    tr.addr_err_c.constraint_mode(0);

    start_item(tr);

    assert(tr.randomize);

    tr.op = writed;

    finish_item(tr);
  end

  //loop for readd
  repeat(15)
  begin
    tr = transaction::type_id::create("tr");
    tr.addr_c.constraint_mode(1);
    tr.addr_err_c.constraint_mode(0);

    start_item(tr);

    assert(tr.randomize);

    tr.op = readd;

    finish_item(tr);
  end

  endtask

endclass


//driver class
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)

  transaction tr;
  virtual spi_if vif;

  function new(string name = "driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");

    if(!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRIVER", "Virtual interface not found")
  endfunction

  task reset_dut();
    repeat(1)
    begin
      //initialize the signals for reset
      vif.addr <= 0;
      vif.din <= 0;
      vif.wr <= 0;
      vif.rst <= 1; //assert reset
      //info
      `uvm_info("DRIVER", "System Reset: Start of Simulation", UVM_NONE)
      @(posedge vif.clk); //wait for a clock cycle
    end
  endtask

  task drive();
    reset_dut(); 
    forever
    begin
      //wait for a transaction from the sequencer
      seq_item_port.get_next_item(tr);

      if (tr.op == rstdut)
      begin 
        `uvm_info("DRIVER", "Resetting DUT", UVM_NONE)
        reset_dut();
      end

      else if (tr.op == writed)
      begin
        //drive the signals for write operation
        vif.addr <= tr.addr;
        vif.din <= tr.din;
        vif.wr <= 1; //assert write
        vif.rst <= 0; //deassert reset
        @(posedge vif.clk); //wait for a clock cycle
        `uvm_info("DRIVER", $sformatf("Driving Write Transaction: Addr=%0h, Data=%0h", vif.addr, vif.din), UVM_NONE)
        @(posedge vif.done);
      end

      else if (tr.op == readd)
      begin
        //drive the signals for read operation
        vif.addr <= tr.addr;
        vif.wr <= 0; //deassert write
        vif.rst <= 0; //deassert reset
        @(posedge vif.clk); //wait for a clock cycle
        `uvm_info("DRIVER", $sformatf("Driving Read Transaction: Addr=%0h", vif.addr), UVM_NONE)
        @(posedge vif.done);
      end

      seq_item_port.item_done();
    end
  endtask

  task run_phase(uvm_phase phase);
    drive();
  endtask

endclass


//monitor class

class mon extends uvm_monitor;
  `uvm_component_utils(mon)

  virtual spi_if vif;
  transaction tr;
  uvm_analysis_port #(transaction) send;

  function new(string name = "mon", uvm_component parent = null);
    super.new(name, parent);
    send = new("send", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");

    if(!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Virtual interface not found")

  endfunction


  virtual task run_phase(uvm_phase phase);
    forever
    begin
      @(posedge vif.clk);
      if(vif.rst)
      begin
        tr.op = rstdut;
        `uvm_info("MON", "DUT Reset Detected", UVM_NONE)
        send.write(tr);
      end

      else if(vif.wr)
      begin
        @(posedge vif.done);
        //update signals
        tr.op = writed;
        tr.addr = vif.addr;
        tr.din = vif.din;
        tr.err = vif.err;
        //info
        `uvm_info("MON", $sformatf("Write Transaction: Addr=%0h, Data=%0h, Error=%0b", tr.addr, tr.din, tr.err), UVM_NONE)
        send.write(tr);
      end

      else if(!vif.wr)
      begin
        @(posedge vif.done);
        //update signals
        tr.op = readd;
        tr.addr = vif.addr;
        tr.dout = vif.dout;
        tr.err = vif.err;
        //info
        `uvm_info("MON", $sformatf("Read Transaction: Addr=%0h, Data=%0h, Error=%0b", tr.addr, tr.dout, tr.err), UVM_NONE)
        send.write(tr);
      end
    end
  endtask

endclass


//scoreboard class
class sco extends uvm_scoreboard;
  `uvm_component_utils(sco)

  uvm_analysis_imp #(transaction, sco) recv;

  bit [31:0] arr[32] = '{default: 0}; //model of the DUT memory
  bit [31:0] addr;
  bit [31:0] data_rd;


  function new(string name = "sco", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv = new("recv", this);
  endfunction

  virtual function void write(transaction tr);
    if (tr.op == rstdut)
      `uvm_info("SCO", "System Reset Detected", UVM_NONE)
    else if (tr.op == writed)
    begin
      if (tr.err)
        `uvm_error("SCO", $sformatf("Write Error Detected: Addr=%0h, Data=%0h", tr.addr, tr.din))
      else
      begin
      arr[tr.addr] = tr.din; //update the model memory
      `uvm_info("SCO", $sformatf("Scoreboard Write: Addr=%0h, Data=%0h", tr.addr, tr.din), UVM_NONE)
      end
    end
    else if (tr.op == readd)
    begin
      if(tr.err)
        `uvm_error("SCO", $sformatf("Read Error Detected: Addr=%0h, Data=%0h", tr.addr, tr.dout))
      else
      begin
        data_rd = arr[tr.addr]; 
        if (data_rd !== tr.dout)
          `uvm_error("SCO", $sformatf("Data Mismatch: Addr=%0h, Expected=%0h, Got=%0h", tr.addr, data_rd, tr.dout))
        else
          `uvm_info("SCO", $sformatf("Data Matched, Read: Addr=%0h, Data=%0h", tr.addr, tr.dout), UVM_NONE)
      end
    end
  endfunction

endclass