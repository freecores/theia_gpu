#Setting some stuff
$RegressionTargetDirectory    = "/home/diego/regressions";
$SimulationBinary             = "TestBench_verilog";



%TestList
=
(
  '1_test_2_traingles_texturized_scale17'			 => {path => "../examples/scenes/example1/", core_count => 2, mem_bank_count => 2,  },
  '2_test_2_traingles_texturized_scale17'			 => {path => "../examples/scenes/example1/", core_count => 4, mem_bank_count => 4,  },
  '3_test_2_traingles_texturized_scale17'			 => {path => "../examples/scenes/example1/", core_count => 8, mem_bank_count => 8,  },
  '4_test_2_traingles_texturized_scale17'			 => {path => "../examples/scenes/example1/", core_count => 16, mem_bank_count => 16,},
  '5_test_6_triangles_texturized_scale17'			 => {path => "../examples/scenes/example2/", core_count => 4, mem_bank_count => 4,  },
  '6_test_6_triangles_texturized_scale17'			 => {path => "../examples/scenes/example2/", core_count => 8, mem_bank_count => 8,  },
  '7_test_6_triangles_texturized_scale17'			 => {path => "../examples/scenes/example2/", core_count => 16, mem_bank_count => 16,  },

  
);

