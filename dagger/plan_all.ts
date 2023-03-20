/**
 * run-all planによる差分検知を行う
 *
 * ローカルで実行する場合にはホスト環境からコンテナにAWSのアクセスキーIDとシークレットキーを渡すため以下で環境変数をセットしておくこと
 * eval $(aws configure export-credentials --format=env)
 */
import Client, { connect } from "@dagger.io/dagger";
import { green } from "console-log-colors";
import { validateAwsEnvVariables } from "./setups/aws.js";
import { getTerragruntContainer } from "./setups/terraform.js";
import { PLAN_OUT_FILE, runAllPlanAndDetectChanges } from "./utilities/plan.js";

validateAwsEnvVariables();

void connect(
  async (client: Client) => {
    const terragruntContainer = await getTerragruntContainer(client);

    // 差分のあるディレクトリを検出
    const { detectedChanges, container: afterPlanContainer } =
      await runAllPlanAndDetectChanges(terragruntContainer);

    // 差分のあるディレクトリのplan結果を表示
    for (const detectedChange of detectedChanges) {
      const { targetDir } = detectedChange;
      const plan = await afterPlanContainer
        .withExec([
          "terragrunt",
          "show",
          PLAN_OUT_FILE,
          `--terragrunt-working-dir=${targetDir}`,
          "--terragrunt-no-auto-init",
        ])
        .stdout();
      console.log(green(`TARGET_DIR = ${targetDir}`));
      console.log(plan);
    }

    // 差分が検知された場合にexit codeを1にする
    if (detectedChanges.length > 0) {
      process.exit(1);
    } else {
      console.log(
        green("No Changes for Any Resources. Infrastructure is UP-TO-DATE.")
      );
    }
  },
  {
    Workdir: "..", // projectのroot
  }
);
