# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI for all operations. When triage-state labels are needed, canonical role names below resolve through `docs/agents/triage-labels.md`.

Native parent and dependency flags require GitHub CLI 2.94 or newer. Run `gh --version` and upgrade before publishing when the installed version is older.

## Spec–ticket publication contract

A spec is a planning issue labelled `spec`; it carries no triage-state label. Create the label when absent:

```sh
gh label create spec --description "Planning parent; not executable work" --color 5319E7
```

An implementation ticket:

- is a native sub-issue of exactly one spec;
- references that spec under `## Parent spec` in its body;
- uses native issue dependencies for blocking edges; and
- receives the configured `ready-for-agent` role only after its relationships and the managed index are complete.

Native relationships are canonical. The spec's implementation-ticket index is their managed projection.

Every ticket body includes:

```markdown
## Parent spec

#100
```

### Managed ticket index

Every spec contains this managed block:

```markdown
<!-- implementation-tickets:start -->
## Implementation tickets
<!-- implementation-tickets:end -->
```

Ticket publication replaces only the content between the existing markers with a task list of child issue links. Preserve the markers and every part of the spec outside that region.

### Publishing tickets

Before publishing, resolve the configured `ready-for-agent` role through `docs/agents/triage-labels.md` and verify that label exists in GitHub; create it when absent.

A legacy spec may predate this contract and still carry a triage-state label instead of `spec`. When the referenced issue's body and history establish that it is the intended planning spec, append the empty managed block when its markers are absent, add `spec`, clear every configured triage-state label, and re-read it before resolving the parent.

Publish blockers first. Create tickets without a triage-state label, attach their parent and dependency relationships, and update the managed index. Re-read the parent and every ticket while the tickets are still unlabelled. Apply the configured `ready-for-agent` label only after that read confirms every parent, dependency, and index entry.

Create a new child with `--parent`; when it has blockers, pass their numbers to `--blocked-by`. Existing issues can be attached afterward:

```sh
# New child with no blockers
gh issue create --title "..." --body "..." --parent <spec-number>

# New child blocked by #101 and #102
gh issue create --title "..." --body "..." --parent <spec-number> --blocked-by 101,102

# Attach or repair relationships after creation
gh issue edit <spec-number> --add-sub-issue <ticket-number>
gh issue edit <ticket-number> --add-blocked-by <blocker-number>
gh issue view <number> --json body,labels,parent,subIssues,blockedBy
```

After applying the ticket labels, read the parent and every ticket once more. Publication is complete when every ticket has the intended parent, every blocking edge exists, the managed index matches the native sub-issues, the spec has `spec` with no configured triage-state label, and every ticket has exactly the configured `ready-for-agent` state.

Here `ready-for-agent` means fully specified, not necessarily unblocked. Any runner consuming that label must also exclude tickets whose native `blockedBy` relationship contains an open issue and dispatch only the frontier.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filtering comments by `jq` and also fetching labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repo from `git remote -v` — `gh` does this automatically when run inside a clone.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage` reads this flag.)_

When set to `yes`, PRs run through the same labels and states as issues, using the `gh pr` equivalents:

- **Read a PR**: `gh pr view <number> --comments` and `gh pr diff <number>` for the diff.
- **List external PRs for triage**: `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments` then keep only `authorAssociation` of `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, or `NONE` (drop `OWNER`/`MEMBER`/`COLLABORATOR`).
- **Comment / label / close**: `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, `gh pr close`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be either — resolve with `gh pr view 42` and fall back to `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: a single issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body. `gh issue create --label wayfinder:map`.
- **Child ticket**: an issue linked to the map as a GitHub sub-issue (`gh api` on the sub-issues endpoint). Where sub-issues aren't enabled, add the child to a task list in the map body and put `Part of #<map>` at the top of the child body. Labels: `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: GitHub's **native issue dependencies** — the canonical, UI-visible representation. Add an edge with `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where `<blocker-db-id>` is the blocker's numeric **database id** (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`, _not_ the `#number` or `node_id`). GitHub reports `issue_dependencies_summary.blocked_by` (open blockers only — the live gate). Where dependencies aren't available, fall back to a `Blocked by: #<n>, #<n>` line at the top of the child body. A ticket is unblocked when every blocker is closed.
- **Frontier query**: list the map's open children (`gh issue list --state open`, scoped to the map's sub-issues / task list), drop any with an open blocker (`issue_dependencies_summary.blocked_by > 0`, or an open issue in the `Blocked by` line) or an assignee; first in map order wins.
- **Claim**: `gh issue edit <n> --add-assignee @me` — the session's first write.
- **Resolve**: `gh issue comment <n> --body "<answer>"`, then `gh issue close <n>`, then append a context pointer (gist + link) to the map's Decisions-so-far.
