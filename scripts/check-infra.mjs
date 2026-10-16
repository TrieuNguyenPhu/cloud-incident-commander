import assert from "node:assert/strict";
import { mkdirSync, readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { spawnSync } from "node:child_process";

const root = resolve(import.meta.dirname, "..");
const roots = [
  "infra/bootstrap",
  "infra/modules/cloudfront_static",
  "infra/modules/state_backend",
  "infra/modules/environment_guardrails",
  ...readdirSync(resolve(root, "infra/environments"), { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .flatMap((env) =>
      readdirSync(resolve(root, "infra/environments", env.name), {
        withFileTypes: true,
      })
        .filter((entry) => entry.isDirectory())
        .map((entry) => `infra/environments/${env.name}/${entry.name}`),
    ),
];

const keys = roots
  .filter((path) => path.startsWith("infra/environments/"))
  .map((path) => {
    const backend = readFileSync(
      resolve(root, path, "backend.hcl.example"),
      "utf8",
    );
    const key = backend.match(/^key\s*=\s*"([^"]+)"/m)?.[1];
    assert.equal(key, `cic/${path.replace("infra/environments/", "")}.tfstate`);
    assert.match(backend, /encrypt\s*=\s*true/);
    assert.match(backend, /use_lockfile\s*=\s*true/);
    assert.match(backend, /^region\s*=\s*"us-east-1"/m);
    assert.match(
      readFileSync(resolve(root, path, "main.tf"), "utf8"),
      /default\s*=\s*"us-east-1"/,
    );
    return key;
  });
assert.equal(
  new Set(keys).size,
  6,
  "Core and all lab state keys must be isolated",
);

const cache = resolve(root, ".tools/terraform-provider-cache");
assert.match(
  readFileSync(resolve(root, "infra/bootstrap/variables.tf"), "utf8"),
  /default\s*=\s*"us-east-1"/,
);
mkdirSync(cache, { recursive: true });

function run(args) {
  const result = spawnSync("terraform", args, {
    cwd: root,
    stdio: "inherit",
    env: {
      ...process.env,
      TF_IN_AUTOMATION: "true",
      TF_PLUGIN_CACHE_DIR: cache,
    },
  });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

run(["fmt", "-check", "-recursive", "infra"]);
for (const path of roots) {
  run([
    `-chdir=${path}`,
    "init",
    "-backend=false",
    "-input=false",
    "-lockfile=readonly",
  ]);
  run([`-chdir=${path}`, "validate", "-no-color"]);
  run([`-chdir=${path}`, "test", "-no-color"]);
}
console.log(
  `Validated ${roots.length} Terraform roots with isolated, mocked plans.`,
);
