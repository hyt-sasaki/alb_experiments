import Client from "@dagger.io/dagger";
import { Container } from "../types/dagger.js";
import { setupAwsSecrets } from "./aws.js";

const mountDirectory = "/src";
const workingDirectory = `${mountDirectory}/terraform`;
const pluginDirName = ".terraform";
const downloadDirName = ".terragrunt";

/**
 * srcファイルやAWSクレデンシャルの設定が完了したコンテナを返す
 *
 * @param client dagger client
 */
export const getTerragruntContainer = async (client: Client) => {
  const src = client
    .host()
    .directory(".", {
      include: [
        "terraform/**/*.tf",
        "terraform/**/*.hcl",
        "terraform/.terraform-version",
      ],
      exclude: [
        "**/.terragrunt-cache",
        "**/.terraform.lock.hcl",
        "**/.terraform",
      ],
    })
    .withNewDirectory(`/${pluginDirName}`)
    .withNewDirectory(`/${downloadDirName}`);
  const terraformVersion = (
    await src.file("terraform/.terraform-version").contents()
  ).trim();

  return client
    .container()
    .from(`alpine/terragrunt:${terraformVersion}`)
    .withMountedDirectory(mountDirectory, src)
    .withWorkdir(workingDirectory)
    .with(setupTerraform(client))
    .with(setupAwsSecrets(client));
};

const setupTerraform = (client: Client) => (container: Container) => {
  const pluginDir = `${mountDirectory}/${pluginDirName}`;
  const terragruntDir = `${mountDirectory}/${downloadDirName}`;
  return container
    .withEnvVariable("TF_PLUGIN_CACHE_DIR", pluginDir)
    .withEnvVariable("TERRAGRUNT_DOWNLOAD_DIR", terragruntDir)
    .withEnvVariable("TERRAGRUNT_FETCH_DEPENDENCY_OUTPUT_FROM_STATE", "true")
    .withEnvVariable("TERRAGRUNT_USE_PARTIAL_PARSE_CONFIG_CACHE", "true")
    .withMountedCache(pluginDir, client.cacheVolume(pluginDir));
};
