export interface PlanResult {
  resource_changes: ResourceChange[];
  output_changes?: OutputChanges;
}
interface ResourceChange {
  address: string;
  change: Change;
}
interface OutputChanges {
  [key: string]: Change;
}
interface Change {
  actions: ("no-op" | "create" | "read" | "update" | "delete")[];
}
