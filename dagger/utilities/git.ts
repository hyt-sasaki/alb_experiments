import * as path from "path";
import * as fs from "fs";

export const findGitRootDir = (dir = process.cwd()): string => {
  const gitDir = path.join(dir, ".git");
  if (fs.existsSync(gitDir)) {
    return dir;
  }
  const parentDir = path.dirname(dir);
  if (parentDir === dir) {
    throw new Error("Not Found Git Root Directory");
  }
  return findGitRootDir(parentDir);
};
