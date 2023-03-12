import Client from "@dagger.io/dagger";

export type Container = ReturnType<typeof Client.prototype.container>
