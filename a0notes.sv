


*************************** Multiplier ***************************
It is easy, nothing new to learn from this design. Hence skipping the notes.


*************************** D flip flop ***************************

// configure agent type based on the need

class config_dff extends uvm_object;

  `uvm_object_utils(config_dff) //factory registration

  uvm_active_passive_enum agent_type = UVM_ACTIVE;  // monitor, scoreboard, driver
  uvm_active_passive_enum agent_type = UVM_PASSIVE; // monitor

// write standard constructor code
// ...
// ...

endclass

// set config access inside environment class. ( use set method )

// use the config class inside agent
// use uvm_config_db to access variables inside config class.( use get method )

// use different seq class for differnt sequences
// reset_seq, valid_seq, random_seq, etc


// can use different test classes, or use same test class for all sequences


*************************** Section 9: Sequence Library ***************************

instead of adding sequeces in test class, we can create a sequence library and add all the sequences there.

class sequence_library extends from uvm_sequence_library;
`uvm_object_utils(sequence_library)
`uvm_sequence_library_utils(sequence_library)

function new (string name = "sequence_library");
  super.new(name);
  add_typewide_sequence(reset_seq::get_type());
  add_typewide_sequence(valid_seq::get_type());

  // if seq instance is not used, use :: operator
  // if seq instance is used, use . operator
  
endfunction

class test extends uvm_test;
  `uvm_component_utils(test)

  sequence_library seq_lib;
  environment env;

  function new (string name = "test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = environment::type_id::create("env", this);
    seq_lib = sequence_library::type_id::create("seq_lib", this);
    seq_lib.selection_mode = UVM_SELECT_RANDOM; // can also be UVM_SELECT_ALL, UVM_SELECT_ONE
    seq_lib.min_random_count = 5; // default is 1, can be set to any value
    seq_lib.max_random_count = 10; // default is 1, can be set to any value
    seq_lib.init_sequence_library(); // initialize the sequence library
    seq_lib.print(); // print the sequence library
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    assert(seq_lib.randomize()); // randomize the sequence library
    seq_lib.start(env.agent.seqr); // start the sequence library on the agent
    phase.drop_objection(this);
  endtask



  *************************** Section 10: TLM Analysis FIFO ***************************
Sender component might be faster than the receiver component. Hence we can use TLM analysis FIFO to store the transactions until the receiver is ready to process them.

uvm_tlm_fifo #(logic [7:0]) fifo; // create a TLM FIFO of size 8 bits

//inside build phase
fifo = new("fifo", this, 10); // create the FIFO of depth 10


  *************************** Section 11: Virtual Sequencers ***************************
