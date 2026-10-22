# Implementation issue brief

Every implementation issue is written to this template, whoever writes it (`do-refine` when slicing, `do-triage` when routing straight to ready). One issue is one PR. Fill the angle brackets from the work. Phrases like "per **Issue statuses**" name headings in the repo's tracker doc.

## Template

```markdown
## What this is

<One plain sentence a newcomer to the project can follow.>

## Status

<Ready for implementation; no open decisions or blockers remain. | Ready for implementation; blocked only by <blocker names>.>

## Next

Implement this ticket in one PR and run the verification below.

**Suggested dispatch:** `<target>` · `<model>` — <one-clause reason>

---

## Agent brief

<The repo tag per **Repo routing**, only when the Product label alone would pick the wrong repo>

### Context

<Repro or evidence, likely paths, links to decision tickets and decision records.>

**Touches:** `<dir or file>`, `<dir or file>`

### Requirements

<What must be true when it's done, and the boundaries of the change.>

**README:** <one line for the product README's non-developer intro. Only when this issue completes a major feature; otherwise leave the line out.>

**Out of scope:** <explicit limits>

### Acceptance criteria

- [ ] <Testable criterion>
- [ ] Verification: `<the repo's check command>`

### Blocked by

<None, or the blocking issues by name>

### Lifecycle

- **Dispatch:** ready → in progress when the implementing agent starts. Decision tickets are never dispatched.
- **While the PR is open:** stay in progress while the PR is a draft. Only the automation named under **Issue statuses** moves it to review; agents never do. Don't set it done or post a completion comment before the merge.
- **Closeout (after merge only):** whoever merges, or the implementing agent, sets it done, links the merged PR, checks off the acceptance criteria, and adds a completion comment with a dateline per **Comment shape**.
```

## Filling it in

- **What this is / Status / Next** form the front door: a reader should understand the issue without knowing the project. When the scope changes, update Status, Next and Suggested dispatch together. History goes in comments, not in new dated sections of the description.
- **Suggested dispatch:** pick one model from **Preferred models**, weighing how hard and risky the work is against cost. Keep the strongest models for cross-cutting or ambiguous work (schema changes, auth, concurrency, architecture calls, hard debugging) and cheaper ones for mechanical or pattern-following changes. Then pick a target from **Dispatch targets** that can run that model: the default target unless the model or the work needs another (a model only one tool runs, a local stack, live input from the user). The reason clause says why the model fits. Pick outside the list only when nothing on it fits, and say why. It's a suggestion: whoever dispatches may override it, and the Dispatch target label records where the work was actually dispatched from.
- **Touches:** the directories and files from your code survey. Dispatch compares these lines to batch issues that don't overlap.
- **README:** most issues have none. See the README rule in `SKILL.md`.
- **Verification:** use the repo's own check command, from its `AGENTS.md` or README.
- **Lifecycle:** use the status names from **Issue statuses**. If the repo has no PR automation (see **Pull requests**), say who marks the PR ready and merges.

Decision tickets don't use this template; see the Tickets section of `SKILL.md`.
