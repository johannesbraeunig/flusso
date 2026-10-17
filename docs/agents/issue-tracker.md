# Issue tracker: beans

Issues and specs for this repo live as beans in `.beans/`, managed with the [beans](https://github.com/hmans/beans) CLI. IDs are prefixed `flusso-`. Always pass `--json` and parse the output. Never hand-edit bean files or write issues anywhere else.

## Conventions

- **Create an issue**: `beans create --json "Title" -t <type> -d "..." -s todo`. Types are `milestone`, `epic`, `feature`, `task` and `bug`. Use `-d -` with a heredoc for multi-line bodies.
- **Read an issue**: `beans show --json <id>`
- **List issues**: `beans list --json` with filters: `-s <status>`, `-t <type>`, `--tag <tag>`, `--parent <id>`, `-S "<search>"`, `--ready`
- **Spec + tickets**: the spec is a parent bean (`epic` or `feature`). Each implementation ticket is its own child bean (`--parent <spec-id>`). Never combine tickets into one bean.
- **Comment on an issue**: `beans update --json <id> --body-append "## Comments\n\n..."` (append under a `## Comments` heading)
- **Apply / remove labels**: `beans update --json <id> --tag "..."` / `--remove-tag "..."`
- **Close**: `beans update --json <id> -s completed` after appending a `## Summary of Changes` section. To decline, use `-s scrapped` after appending `## Reasons for Scrapping`.

## When a skill says "publish to the issue tracker"

Create a bean as in **Create an issue** above.

## When a skill says "fetch the relevant ticket"

Read it as in **Read an issue** above. The user normally passes the bean ID.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a parent bean with one **child** bean per ticket.

- **Map**: an `epic` bean tagged `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body.
- **Child ticket**: a `task` bean with `--parent <map-id>`, tagged `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`), with the question in the body.
- **Blocking**: `beans update <child> --blocked-by <blocker-id>`. A ticket is unblocked when every blocker is `completed`.
- **Frontier**: `beans list --json --parent <map-id> --ready`. The first result in ID/creation order wins.
- **Claim**: `beans update <id> -s in-progress` before any work.
- **Resolve**: append the answer under `## Answer`, set `-s completed`, then append a context pointer (gist + bean ID) to the map's Decisions-so-far.
