import Client from "@dagger.io/dagger";
import { Container } from "../types/dagger.js";

const AWS_ACCESS_KEY_ID = "AWS_ACCESS_KEY_ID";
const AWS_SECRET_ACCESS_KEY = "AWS_SECRET_ACCESS_KEY";

/**
 * daggerのホストに設定されている以下の環境変数をセットしたコンテナを返す
 * - AWS_ACCESS_KEY_ID
 * - AWS_SECRET_ACCESS_KEY
 *
 * @param client dagger client
 */
export const setupAwsSecrets = (client: Client) => (container: Container) => {
  const awsKey = client.host().envVariable(AWS_ACCESS_KEY_ID).secret();
  const awsSecret = client.host().envVariable(AWS_SECRET_ACCESS_KEY).secret();
  return container
    .withSecretVariable(AWS_ACCESS_KEY_ID, awsKey)
    .withSecretVariable(AWS_SECRET_ACCESS_KEY, awsSecret);
};

/**
 * ホスト環境に以下の環境変数がセットされているか確認する
 * - AWS_ACCESS_KEY_ID
 * - AWS_SECRET_ACCESS_KEY
 */
export const validateAwsEnvVariables = () => {
  if (!process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) {
    console.error(
      "AWS_ACCESS_KEY_IDとAWS_SECRET_ACCESS_KEYの環境変数をセットしてください"
    );
    process.exit(1);
  }
};
