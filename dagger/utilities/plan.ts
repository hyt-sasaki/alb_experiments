import { Change, PlanResult, ResourceChange } from "../types/terraform.js";
import { Container } from "../types/dagger.js";

type DetectedChange = {
  targetDir: string;
  changedResources: ResourceChange[];
  changedOutputs: OutputChange[];
};
type OutputChange = {
  name: string;
  change: Change;
};

export const PLAN_OUT_FILE = "tfplan.binary";

/**
 * run-all planを実行し、そのplan結果を PLAN_OUT_FILE にファイル出力したコンテナを返す
 * 加えて、run-all planをしたなかで差分が発生していたディレクトリの一覧をDetectedChange[]として返す
 *
 * @param container
 */
export const runAllPlanAndDetectChanges = async (container: Container) => {
  const { container: afterPlan, targetDirectories } = await runPlanAll(
    container
  );

  // 差分のあるディレクトリを検出
  const detectedChanges = (
    await Promise.all(targetDirectories.map(detectChange(afterPlan)))
  ).filter(
    (detectChange) =>
      detectChange.changedResources.length > 0 ||
      detectChange.changedOutputs.length > 0
  );

  return {
    detectedChanges,
    container: afterPlan,
  };
};

/**
 * run-all planを実行し、その結果のバイナリファイルが生成された新たなコンテナを返す
 * 加えてrun-allの対象になったディレクトリ一覧を返す
 *
 * @param terragrunt terragruntの設定が完了しているコンテナ
 */
const runPlanAll = async (terragrunt: Container) => {
  await validateWorkingDir(terragrunt);
  const resultContainer = terragrunt.withExec([
    "terragrunt",
    "run-all",
    "plan",
    "-out",
    PLAN_OUT_FILE,
    "--terragrunt-exclude-dir",
    ".",
  ]);
  const targetDirectories = await resultContainer
    .withExec(["find", ".", "-name", PLAN_OUT_FILE])
    .stdout()
    .then(
      (findCommandResult) =>
        findCommandResult
          .trim()
          .split("\n")
          .map((path) => path.slice(0, path.indexOf(".terragrunt-cache"))) // `.terragrunt-cache`の前までの文字列 (= target dir) を取得
    );

  return {
    container: resultContainer,
    targetDirectories: Array.from(new Set(targetDirectories)), // 重複を除外 (複数のterragrunt-cacheが存在する場合に除外が必要)
  };
};

/**
 * plan結果のバイナリファイルを走査し、検出された差分(DetectedChangeオブジェクト)を返す
 *
 * @param afterPlan plan結果のバイナリファイルが配置されているコンテナ
 */
const detectChange =
  (afterPlan: Container) =>
  async (targetDir: string): Promise<DetectedChange> => {
    await validateWorkingDir(afterPlan);
    // バイナリファイルからjsonファイルを生成
    const json = await afterPlan
      .withExec([
        "terragrunt",
        "show",
        "-json",
        PLAN_OUT_FILE,
        `--terragrunt-working-dir=${targetDir}`,
        "--terragrunt-no-auto-init",
      ])
      .stdout();
    // jsonフォーマット: https://developer.hashicorp.com/terraform/internals/json-format
    const planResult = JSON.parse(json) as PlanResult;

    // no-op 以外の差分があった時にのみplan結果を表示する
    // resourceに差分があるかどうか
    const changedResources = planResult.resource_changes.filter(
      (resourceChange) => !resourceChange.change.actions.includes("no-op")
    );
    // outputに差分があるかどうか
    const outputChanges = planResult.output_changes;
    const changedOutputs = outputChanges
      ? Object.keys(outputChanges)
          .filter((key) => !outputChanges[key].actions.includes("no-op"))
          .map((key) => ({
            name: key,
            change: outputChanges[key],
          }))
      : [];

    return {
      targetDir,
      changedResources,
      changedOutputs,
    };
  };

const validateWorkingDir = async (container: Container) => {
  if ((await container.workdir()) !== "/src/terraform") {
    throw Error("Working directory must be /src/terraform .");
  }
};
