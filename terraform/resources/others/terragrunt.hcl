include "root" {
  path = find_in_parent_folders()
}

dependency "network" {
  config_path = "${path_relative_from_include()}/resources/network"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "show"]
  mock_outputs = {
      vpc_id = "aws_vpc_id_dummy"
      public_1a_subnet_id = "public_1a_subnet_id_dummy"
      public_1c_subnet_id = "public_1c_subnet_id_dummy"
  }
}

dependencies {
  paths = [
    "${path_relative_from_include()}/resources/network"
  ]
}

inputs = {
  vpc_id = dependency.network.outputs.vpc_id
  public_1a_subnet_id = dependency.network.outputs.public_1a_subnet_id
  public_1c_subnet_id = dependency.network.outputs.public_1c_subnet_id
}
