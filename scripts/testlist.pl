#Setting some stuff
$RegressionTargetDirectory    = "/home/diego/regressions";
$SimulationBinary             = "TestBench_verilog";



%TestList
=
(
  '1_test_2_traingles_texturized_scale17'			 => {path => "../examples/scenes/example1/", core_count => 4, mem_bank_count => 4,  },
  '2_test_2_traingles_texturized_scale17'			 => {path => "../examples/scenes/example1/", core_count => 8, mem_bank_count => 8,  },
  '3_test_2_traingles_texturized_scale17'			 => {path => "../examples/scenes/example1/", core_count => 16, mem_bank_count => 16,},
  '4_test_6_triangles_texturized_scale17'			 => {path => "../examples/scenes/example2/", core_count => 4, mem_bank_count => 4,  },
  '5_test_6_triangles_texturized_scale17'			 => {path => "../examples/scenes/example2/", core_count => 8, mem_bank_count => 8,  },
  '6_test_6_triangles_texturized_scale17'			 => {path => "../examples/scenes/example2/", core_count => 16, mem_bank_count => 16,  },

  
);

