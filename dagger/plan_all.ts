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
import {
  DetectedChange,
  PLAN_OUT_FILE,
  runAllPlanAndDetectChanges,
} from "./utilities/plan.js";
import { Container } from "./types/dagger.js";
import { findGitRootDir } from "./utilities/git.js";
import { dedent } from "ts-dedent";
import stripAnsi from "strip-ansi";

type PlanSummary = {
  targetDir: string;
  planResult: string;
};

validateAwsEnvVariables();

void connect(
  async (client: Client) => {
    const terragruntContainer = await getTerragruntContainer(client);

    // 差分のあるディレクトリを検出
    // afterPlanContainerにはplan結果が PLAN_OUT_FILE　としてファイル出力される
    const { detectedChanges, container: afterPlanContainer } =
      await runAllPlanAndDetectChanges(terragruntContainer);

    // PLAN_OUT_FILEをもとに差分のあるディレクトリのplan結果を算出
    const planResultExtractor = getPlanResultExtractor(afterPlanContainer);
    const planSummaries: PlanSummary[] = await Promise.all(
      detectedChanges.map(async (detectedChange) => ({
        targetDir: detectedChange.targetDir,
        planResult: await planResultExtractor(detectedChange),
      }))
    );

    // 標準出力
    planSummaries.forEach((planSummary) => {
      const { targetDir, planResult } = planSummary;
      console.log(green(`TARGET_DIR = ${targetDir}`));
      console.log(planResult);
    });

    if (detectedChanges.length > 0) {
      // 結果をファイル出力
      await exportSummaryFile(planSummaries, client);
      // 差分が検知された場合にexit codeを1にする
      process.exit(1);
    } else {
      console.log(
        green("No Changes for Any Resources. Infrastructure is UP-TO-DATE.")
      );
    }
  },
  {
    Workdir: findGitRootDir(), // projectのroot
  }
);

const getPlanResultExtractor =
  (container: Container) =>
  async ({ targetDir }: DetectedChange) => {
    return await container
      .withExec([
        "terragrunt",
        "show",
        PLAN_OUT_FILE,
        `--terragrunt-working-dir=${targetDir}`,
        "--terragrunt-no-auto-init",
      ])
      .stdout();
  };

const exportSummaryFile = async (
  planSummaries: PlanSummary[],
  client: Client
) => {
  const summary = planSummaries.reduce(
    (acc: string, planSummary: PlanSummary): string => {
      return dedent`${acc}
        TARGET_DIR = ${planSummary.targetDir}
        ${stripAnsi(planSummary.planResult)}

      `;
    },
    ""
  );
  await client
    .container()
    .from("alpine")
    .withNewFile("/build/summary.txt", {
      contents: summary.trim(),
    })
    .directory("build")
    .export("build");
};
