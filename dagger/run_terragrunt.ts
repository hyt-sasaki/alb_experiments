/**
 * run-all planによる差分検知を行う
 * ローカルで実行する場合にはホスト環境からコンテナにAWSのアクセスキーIDとシークレットキーを渡すため以下で環境変数をセットしておくこと
 * eval $(aws configure export-credentials --format=env)
 */
import Client, { connect } from '@dagger.io/dagger';
import { green } from 'console-log-colors'
import { genMountAwsSecretCallback } from "./local.js";
import { Container } from "./dagger.js";
import { Change, PlanResult, ResourceChange } from "./terraform.js";


const PLAN_OUT_FILE = "tfplan.binary"

type DetectedChange = {
    targetDir: string,
    changedResources: ResourceChange[],
    changedOutputs: OutputChange[],

}
type OutputChange = {
    name: string,
    change: Change,
}

void connect(
    async (client: Client) => {
        // srcコードとAWSのクレデンシャルをホストから取得しセットする
        const src = client.host().directory(".", {
            include: ["terraform"]
        })
        const runner = client.container()
            .from("alpine/terragrunt")
            .withMountedDirectory("/src", src)
            .withWorkdir("/src/terraform")
            .with(genMountAwsSecretCallback(client))

        // run-all plan
        const { container: afterPlan, targetDirectories } = await runPlanAll(runner)

        // 差分のあるディレクトリを検出
        const detectedChanges = (await Promise.all(targetDirectories.map(detectChange(afterPlan))))
            .filter(detectChange => detectChange.changedResources.length > 0 || detectChange.changedOutputs.length > 0)

        // 差分のあるディレクトリのplan結果を表示
        for (const detectedChange of detectedChanges) {
            const { targetDir } = detectedChange
            const plan = await afterPlan.withExec([
                "terragrunt", "show", PLAN_OUT_FILE,
                `--terragrunt-working-dir=${targetDir}`, "--terragrunt-no-auto-init"
            ]).stdout()
            console.log(green(`TARGET_DIR = ${targetDir}`))
            console.log(plan)
        }

        // 差分が検知された場合にexit codeを1にする
        if (detectedChanges.length > 0) {
            process.exit(1)
        }
    }, {
        Workdir: ".."
    }
);

/**
 * run-all planを実行し、その結果のバイナリファイルが生成された新たなコンテナを返す
 * 加えてrun-allの対象になったディレクトリ一覧を返す
 *
 * @param terragrunt terragruntの設定が完了しているコンテナ
 */
const runPlanAll = async (terragrunt: Container) => {
    const resultContainer = terragrunt
        .withExec(["terragrunt", "run-all", "plan", "-out", PLAN_OUT_FILE])
        .withExec(["find", ".", "-name", PLAN_OUT_FILE])
    const targetDirectories = await resultContainer.stdout().then(
        result => result.split("\n")
            .filter(i => i)     // 空文字を除外
            .filter(path => !path.startsWith("./."))    // rootディレクトリを除外
            .map(path => path.slice(0, path.indexOf('.terragrunt-cache')))  // `.terragrunt-cache`の前までの文字列 (= target dir) を取得
    )

    return {
        container: resultContainer,
        targetDirectories: Array.from(new Set(targetDirectories)),  // 重複を除外 (複数のterragrunt-cacheが存在する場合に除外が必要)
    }
}

/**
 * plan結果のバイナリファイルを走査し、検出された差分(DetectedChangeオブジェクト)を返す
 *
 * @param afterPlan plan結果のバイナリファイルが配置されているコンテナ
 */
const detectChange = (afterPlan: Container) =>
    async (targetDir: string): Promise<DetectedChange> => {
        // バイナリファイルからjsonファイルを生成
        const json = await afterPlan
            .withExec([
                "terragrunt", "show", "-json", PLAN_OUT_FILE,
                `--terragrunt-working-dir=${targetDir}`, "--terragrunt-no-auto-init"
            ]).stdout()
        // jsonフォーマット: https://developer.hashicorp.com/terraform/internals/json-format
        const planResult = JSON.parse(json) as PlanResult

        // no-op 以外の差分があった時にのみplan結果を表示する
        // resourceに差分があるかどうか
        const changedResources = planResult.resource_changes
            .filter(resourceChange => !resourceChange.change.actions.includes("no-op"))
        // outputに差分があるかどうか
        const outputChanges = planResult.output_changes
        const changedOutputs = outputChanges ? Object.keys(outputChanges)
            .filter(key => !outputChanges[key].actions.includes("no-op"))
            .map(key => ({
                name: key,
                change: outputChanges[key]
            }) satisfies OutputChange) : []

        return {
            targetDir,
            changedResources,
            changedOutputs,
        }
    }
