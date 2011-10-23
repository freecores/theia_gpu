#Setting some stuff
$RegressionTargetDirectory    = "/home/diego/regressions";
$SimulationBinary             = "TestBench_verilog";



%TestList
=
(
  'test_2_traingles_texturized_scale17'			 => {index => 1, path => "../examples/scenes/example1/", core_count => 2, mem_bank_count => 2,  },
  'test_2_traingles_texturized_scale17'			 => {index => 2, path => "../examples/scenes/example1/", core_count => 4, mem_bank_count => 4,  },
  'test_2_traingles_texturized_scale17'			 => {index => 3, path => "../examples/scenes/example1/", core_count => 8, mem_bank_count => 8,  },
  'test_2_traingles_texturized_scale17'			 => {index => 4, path => "../examples/scenes/example1/", core_count => 16, mem_bank_count => 16,},
  'test_6_triangles_texturized_scale17'			 => {index => 5, path => "../examples/scenes/example2/", core_count => 4, mem_bank_count => 4,  },
  'test_6_triangles_texturized_scale17'			 => {index => 6, path => "../examples/scenes/example2/", core_count => 8, mem_bank_count => 8,  },
  'test_6_triangles_texturized_scale17'			 => {index => 7, path => "../examples/scenes/example2/", core_count => 16, mem_bank_count => 16,  },
  'test_6_triangles_texturized_scale17'			 => {index => 8, path => "../examples/scenes/example3/", core_count => 4, mem_bank_count => 4,  },
  'test_6_triangles_texturized_scale17'			 => {index => 9, path => "../examples/scenes/example3/", core_count => 8, mem_bank_count => 8,  },
  'test_6_triangles_texturized_scale17'			 => {index => 10, path => "../examples/scenes/example3/", core_count => 16, mem_bank_count => 16,  },

  
);

