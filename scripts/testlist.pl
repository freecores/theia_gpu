#Setting some stuff
$RegressionTargetDirectory    = "/home/diego/regressions";
$SimulationBinary             = "TestBench_verilog";



%TestList
=
(
  'test_1'			 => {run_index => 1, path => "../examples/scenes/example1/", core_count => 2, mem_bank_count => 2,  },
  'test_2'			 => {run_index => 2, path => "../examples/scenes/example1/", core_count => 4, mem_bank_count => 4,  },
  'test_3'			 => {run_index => 3, path => "../examples/scenes/example1/", core_count => 8, mem_bank_count => 8,  },
  'test_4'			 => {run_index => 4, path => "../examples/scenes/example1/", core_count => 16, mem_bank_count => 16,},
  'test_5'			 => {run_index => 5, path => "../examples/scenes/example2/", core_count => 4, mem_bank_count => 4,  },
  'test_6'			 => {run_index => 6, path => "../examples/scenes/example2/", core_count => 8, mem_bank_count => 8,  },
  'test_7'			 => {run_index => 7, path => "../examples/scenes/example2/", core_count => 16, mem_bank_count => 16,  },
  'test_8'			 => {run_index => 8, path => "../examples/scenes/example3/", core_count => 4, mem_bank_count => 4,  },
  'test_9'			 => {run_index => 9, path => "../examples/scenes/example3/", core_count => 8, mem_bank_count => 8,  },
  'test_10'			 => {run_index => 10, path => "../examples/scenes/example3/", core_count => 16, mem_bank_count => 16,  },

  
);

