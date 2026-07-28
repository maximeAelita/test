# Production Lines 1–12 — Issue Tracker

Everything needed to stand up a SharePoint site that tracks issues and work requests
across production lines 1 to 12, plus a working dashboard prototype you can click
through before you build anything.

Anyone with access to the site can raise a ticket against a line — either **an issue**
(something is wrong now) or **a request** (work needed later) — and the queue shows
every open ticket, its severity, and how long it has been sitting there.

## What's in here

```
production-lines-issue-tracker/
├── dashboard/
│   └── index.html                     working prototype — open it in a browser
├── docs/
│   ├── SHAREPOINT-SETUP.md            build it: script path + click-by-click path
│   └── POWER-AUTOMATE-FLOWS.md        notifications, digests, escalation
└── provision/
    ├── Provision-LineIssueTracker.ps1 PnP PowerShell — creates the whole site
    ├── lines.csv                      the 12 lines; edit before first run
    ├── sample-issues.csv              demo tickets, optional
    └── formatting/
        ├── severity-column.json       S1 red / S2 amber / S3 blue / S4 grey pills
        └── status-column.json         status pills
```

## Start here

**To see it working right now** — open `dashboard/index.html` in any browser. No install,
no server, no account. Raise a few tickets, click a line tile to filter, change a status.
Data is stored in that browser only; **Reset to sample data** in the footer puts it back.

**To build the real thing** — read `docs/SHAREPOINT-SETUP.md`. Two paths, same result:

- **Path A (10 min):** edit `provision/lines.csv` with your real line names, then run
  `provision/Provision-LineIssueTracker.ps1`. Safe to re-run.
- **Path B:** click-by-click instructions for building it in the browser, if you don't
  have PowerShell or the rights to run it.

Then add notifications from `docs/POWER-AUTOMATE-FLOWS.md` — flow 1 (line down → Teams
alert) is the one worth doing on day one.

## The data model

Two lists. **Production Lines** is reference data — one row per line, so renaming a line
or changing its owner happens in one place. **Line Issues** is the queue, with a lookup
to the line.

Key columns on a ticket: Ticket Type (Issue / Request), Line, Category, Severity,
Status, Details, Shift, Downtime Minutes, Assigned To, Target Date, Resolution, and a
calculated Age (days).

Severity drives everything else:

| | Meaning | Response |
|---|---|---|
| **S1** | Line is stopped | Immediate — Teams alert to Ops, escalates after 4 hours |
| **S2** | Running degraded, quality or rate at risk | Same shift, escalates after 3 days |
| **S3** | Minor, line running normally | Planned into maintenance |
| **S4** | Cosmetic, improvement, backlog | Reviewed at the weekly meeting |

## Permissions

Members can raise a ticket and read every ticket, but can only edit their own. Ops
(Owners) can edit and close anything. Management can be Visitors for read-only. That's
one setting — *List settings → Advanced settings → Item-level permissions* — and the
setup guide covers changing it if you'd rather everyone could edit everything.

## Prototype ↔ SharePoint

The dashboard's **Export CSV** produces the same column names as the SharePoint list, so
anything captured in the prototype imports into the real list via **Edit in grid view →
paste**. Use it to trial the workflow with a couple of shifts before committing the site.

The prototype is a design and workflow reference, not a SharePoint deployment — modern
SharePoint pages won't run custom JavaScript. Recreating that look inside SharePoint is
done with the list webparts and the column formatting JSON in `provision/formatting/`,
which is why those files exist.

## Editing it later

All of it is standard SharePoint lists, so changes are made in the browser and no code
is touched:

- **New or renamed line** → edit the *Production Lines* list; the lookup follows.
- **New category, status or severity** → edit the choice column; existing tickets keep
  their values.
- **New field** → add the column, then add it to the views you want it on.
- **Different colours or thresholds** → edit the JSON in `provision/formatting/` and
  paste it back into *Format this column*.

Re-running the provisioning script never overwrites those edits — it only adds what's
missing.
