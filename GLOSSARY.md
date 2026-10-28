# Factory

The workflow skills, contracts and configs that every factory repo shares.

## Verify

**Verify contract**:
A repo's `.factory/verify.toml`: the one file that declares every check the repo runs.
_Avoid_: verification policy, CI config

**Check**:
A named command that passes or fails, plus the trigger paths that select it. Its name is also its status-check name.
_Avoid_: step, job, gate

**Trigger paths**:
The globs, relative to the repo root, whose change selects a check. They may point into any app in the repo.
_Avoid_: path filters, watch paths
