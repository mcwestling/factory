# Factory

Factory turns ideas into finished software changes, with coding agents doing the building and a person making the decisions.

## What it does

Factory is a set of workflow skills for coding agents. Together they cover the path from a rough idea to a merged change:

- **Capture:** turn photos of handwritten sticky notes, or dictated thoughts, into tickets in Linear.
- **Triage:** review new tickets with you and route each one: build it, plan it further, or drop it.
- **Refine:** turn a big goal into a map of the decisions still open, settle them with you one at a time, then slice the settled work into small, clearly written tickets.
- **Implement:** hand a ticket to an agent, which builds it, checks its own work and opens a pull request for you to review.

Your project's settings, such as team names, labels and each product's repo, live in one short file, so the same skills work in any project.

## Who it's for

People who plan their work in Linear and want coding agents to do more of the building without giving up control. You decide what gets built and review every change; the agents do the legwork in between.

## Learn more

- [Install the skills](#install)
- [Adopt Factory in your own project](#adopting)
- [McWestling's settings file, a worked example](docs/issue-tracker.md)
- [License](LICENSE)

---

## Layout

```text
.
├── AGENTS.md              # Rules for agents working in this repo
├── docs/
│   └── issue-tracker.md   # McWestling's tracker values; the worked example
└── skills/
    └── <name>/            # One folder per skill: SKILL.md, agents/openai.yaml
```

## Skills

`do-` is the factory's verb prefix: each skill is something the factory does.

| Skill              | What it does                                                             |
| ------------------ | ------------------------------------------------------------------------ |
| `do-post-its`      | Turns photos of Post-its, or dictated notes, into Triage issues          |
| `do-triage`        | Works the Triage queue with you and routes each item                     |
| `do-refine`        | Charts maps, resolves decision tickets, and slices implementation issues |
| `do-implement`     | Takes one implementation issue to a verified draft PR                    |
| `do-factory-setup` | Writes a repo's tracker doc from Linear plus a short interview           |

## Install

```sh
npx skills add mcwestling/factory --skill '*' -g
```

The skills link to each other, so install all of them.

## Adopting

Each repo that uses the skills keeps its workspace values in `docs/issue-tracker.md`. Run `do-factory-setup` in your repo to write it, or copy [`docs/issue-tracker.md`](docs/issue-tracker.md) and replace the values.

## Contributing

Contributions are accepted under this repo's [MIT license](LICENSE) (inbound=outbound).
