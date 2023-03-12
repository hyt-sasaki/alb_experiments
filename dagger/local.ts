import Client from '@dagger.io/dagger';
import { Container } from './dagger.js';

const AWS_ACCESS_KEY_ID = "AWS_ACCESS_KEY_ID"

const AWS_SECRET_ACCESS_KEY = "AWS_SECRET_ACCESS_KEY"
// @ts-ignore
/**
 * daggerのホストに設定されている以下の環境変数をセットしたコンテナを返す
 * - AWS_ACCESS_KEY_ID
 * - AWS_SECRET_ACCESS_KEY
 *
 * @param client dagger client
 */
export const genMountAwsSecretCallback = (client: Client) =>
    (container: Container) => {
        const awsKey = client.host().envVariable(AWS_ACCESS_KEY_ID).secret()
        const awsSecret = client.host().envVariable(AWS_SECRET_ACCESS_KEY).secret()
        return container
            .withSecretVariable(AWS_ACCESS_KEY_ID, awsKey)
            .withSecretVariable(AWS_SECRET_ACCESS_KEY, awsSecret)
    }