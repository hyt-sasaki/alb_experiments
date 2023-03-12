export type PlanResult = {
  resource_changes: ResourceChange[];
  output_changes?: OutputChanges;
};
type ResourceChange = {
  address: string;
  change: Change;
};
type OutputChanges = {
  [key: string]: Change;
};

type Change = {
  actions: ("no-op" | "create" | "read" | "update" | "delete")[];
};
