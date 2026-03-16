


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

