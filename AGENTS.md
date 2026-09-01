<!-- BEGIN TL WORKFLOW -->
## tl workflow

This repository uses `tl` cli for local task coordination between humans and agents. Treat the task ledger as the source of truth for non-trivial work: planning, claiming, progress notes, blockers, handoffs, and completion.

Use an explicit actor on mutating commands so claims, notes, and handoffs are attributed clearly:

```sh
tl claim <task-id> --actor agent-name
tl note <task-id> -m "..." --actor agent-name
tl close <task-id> --actor agent-name
```

Recommended workflow:

1. Start from the task ledger.
   - Run `tl ready --json` to find unclaimed work, or `tl ready --tag <role> --json` to filter by role-ish tags.
   - If the human hands you a task, run `tl show <task-id>` and `tl history <task-id>` before editing.
   - For non-trivial implementation work, prefer a matching tl task. If none exists, create one or ask whether to create one before editing.
2. Preserve and follow context.
   - Treat `References:` from `tl show` as context pointers; inspect referenced files, docs, URLs, tickets, or feature specs before editing.
   - If no suitable task exists, create one with `tl create "<title>" -d "<description>" --ref <path-or-url>`.
   - If your work uncovers a separable follow-up, create it with `tl create` and add useful `--ref` values instead of silently expanding scope.
3. Claim before editing.
   - Run `tl claim <task-id> --actor agent-name` before making code, doc, config, or test changes.
   - Do **not** work on a task claimed by another active actor unless explicitly told.
4. Re-check context after claiming.
   - Run `tl show <task-id>` to confirm scope, dependencies, references, and notes.
   - Run `tl history <task-id>` to read prior events, stale claims, decisions, and handoff context.
5. Record progress while working.
   - Re-run `tl claim <task-id> --actor agent-name` periodically on long work — it extends the lease (heartbeat pattern).
   - Use `tl note <task-id> -m "..." --actor agent-name` for meaningful progress, decisions, failed approaches, blockers, test results, and handoff context.
6. Use dependencies and stalled-work commands when needed.
   - `tl dep add <task-id> --on <task-id>` - make one task wait for another.
   - `tl dep remove <task-id> --on <task-id>` - remove a dependency.
   - `tl stale` — list expired claims that may need cleanup or handoff.
   - If unsure whether a command exists in this version, run `tl <cmd> --help`.
7. End every session with an explicit task ledger state.
   - `tl close <task-id> --actor agent-name` - work is done and verified.
   - `tl cancel <task-id> -m "<reason>" --actor agent-name` - work won't be done.
   - `tl block <task-id> -m "<blocker>" --actor agent-name` - external blocker; claim is released.
   - `tl unblock <task-id> --actor agent-name` - external blocker is resolved.
   - `tl pending <task-id> --question "..." --actor agent-name` - you need a human decision; claim is released.
   - `tl resolve <task-id> --answer "..." --actor agent-name` - record the human answer and reopen the task.
   - `tl release <task-id> --actor agent-name` - you're stepping away cleanly; leave a comprehensive note first.

Rules:

- Prefer tasks from `tl ready`; blocked, pending, done, cancelled, or actively claimed tasks are not ready.
- Use `--json` for automation and parsing (`tl ready --json`, `tl show <task-id> --json`, `tl history <task-id> --json`).
- Leave notes for partial progress, failed approaches, decisions, test results, blockers, and handoffs.
- Attach references with `--ref` when they help the next human or agent recover context quickly.
- Do **not** edit `.tl/events.jsonl` manually.
- If `.tl/` is missing, ask the human whether to run `tl init`.
<!-- END TL WORKFLOW -->
