# SharePoint setup — Production Lines 1–12 Issue Tracker

Two ways to build it. **Path A** is the script (10 minutes, repeatable). **Path B** is
click-by-click in the browser if you'd rather not run PowerShell or don't have the rights.
Both end up with exactly the same site, and everything stays editable afterwards.

---

## What you end up with

| Piece | What it is |
|---|---|
| **Production Lines** list | Reference data — one row per line, `L01` … `L12`. Rename lines here, not in code. |
| **Line Issues** list | The ticket queue. Holds both *issues* (something is wrong now) and *requests* (work needed later), separated by the **Ticket Type** column. |
| **Home page** | Line status at the top, a **Report an issue** button, then the open queue. |
| **Views** | Open Tickets · Line Down (S1) · By Line · My Tickets · Recently Closed |
| **Permissions** | Anyone with site access can raise a ticket and read all of them, but can only edit their own. Ops keeps full edit. |

---

## Path A — run the script

**Prerequisites**

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
```

You need Site Collection Admin on the target site. The first PnP login in a tenant may
need an admin to consent once: `Register-PnPEntraIDAppForInteractiveLogin`.

**If the site does not exist yet**

```powershell
cd provision
./Provision-LineIssueTracker.ps1 `
  -SiteUrl "https://<tenant>.sharepoint.com/sites/ProductionLines" `
  -CreateSite -Owner "you@<tenant>.com" -IncludeSampleIssues
```

**If you already made the site in the browser**

```powershell
./Provision-LineIssueTracker.ps1 -SiteUrl "https://<tenant>.sharepoint.com/sites/ProductionLines"
```

The script is safe to re-run — it skips anything that already exists, so you can add a
column to it later and run it again without duplicating anything.

**To use your real line names:** edit `provision/lines.csv` before running. The script
seeds the Production Lines list from that file. If the lines already exist, edit them
directly in SharePoint instead — the CSV is only used for first load.

Then jump to [Build the home page](#build-the-home-page).

---

## Path B — build it in the browser

### 1. Create the site

SharePoint start page → **Create site** → **Team site** → blank template.
Name: `Production Lines 1-12`. Privacy: Private (add members in step 5).

### 2. Create the "Production Lines" list

**+ New → List → Blank list**, name it `Production Lines`.

Rename the **Title** column to `Line Code`, then add:

| Column | Type | Notes |
|---|---|---|
| Line Name | Single line of text | e.g. *Line 1* |
| Line Owner | Person | who owns the line |
| Line State | Choice | `Running`, `Degraded`, `Down`, `Planned Downtime` — default `Running` |

Add 12 items, `L01` … `L12`. Or use **Edit in grid view** and paste from
`provision/lines.csv`.

### 3. Create the "Line Issues" list

**+ New → List → Blank list**, name it `Line Issues`.

Rename **Title** to `Summary`, then add these columns **in this order**:

| Column | Type | Settings |
|---|---|---|
| Line | **Lookup** | Get info from `Production Lines`, column `Line Code`. **Required.** |
| Ticket Type | Choice | `Issue`, `Request` — default `Issue`, radio buttons. Required. |
| Category | Choice | Mechanical · Electrical · Controls / PLC · Quality defect · Safety · Material supply · Utilities · Changeover · Housekeeping · Other |
| Severity | Choice | `S1 - Line Down`, `S2 - Major`, `S3 - Minor`, `S4 - Cosmetic` — default `S2 - Major`. Required. |
| Status | Choice | `New`, `Triaged`, `In Progress`, `Waiting on Parts`, `Resolved`, `Closed` — default `New`. Required. |
| Details | Multiple lines of text | plain text is fine |
| Shift | Choice | `A - Days`, `B - Afters`, `C - Nights` |
| Downtime Minutes | Number | 0 decimals, default 0 |
| Reported By | Person | leave blank; SharePoint's built-in *Created By* also records this |
| Assigned To | Person | who is fixing it |
| Target Date | Date | when it should be done |
| Resolution | Multiple lines of text | filled in on close |
| Age (days) | Calculated | formula `=ROUND(TODAY()-[Created],0)`, result type **Number**, 0 decimals |

Then **List settings → Advanced settings**:
- Allow attachments: **Yes** (photos of the fault are the single most useful field)
- Item-level permissions → Read: *All items* · Create and Edit: **Items that were created by the user**

Turn on versioning under **Versioning settings** so you get an edit history per ticket.

### 4. Add the views

**List settings → Views → Create view** (Standard), for each:

| View | Filter | Sort |
|---|---|---|
| **Open Tickets** *(make default)* | Status is not `Resolved` **and** Status is not `Closed` | Severity asc, then Created asc |
| **Line Down (S1)** | Severity is `S1 - Line Down` | Created asc |
| **By Line** | Status is not `Closed` | Group by **Line** |
| **My Tickets** | Created By is `[Me]` | Created desc |
| **Recently Closed** | Status is `Closed` and Modified is greater than `[Today]-30` | Modified desc |

### 5. Make the columns readable at a glance

Open the **Severity** column dropdown → **Column settings → Format this column →
Advanced mode**, and paste `provision/formatting/severity-column.json`.
Repeat for **Status** with `provision/formatting/status-column.json`.

You get colour-coded pills: S1 red, S2 amber, S3 blue, S4 grey; resolved/closed green.
Each pill carries an icon and its text label, so it still reads correctly in greyscale
or for colour-blind viewers.

---

## Build the home page

Site home → **Edit**, then lay out three sections top to bottom:

1. **One-column section — Text webpart.**
   Heading: *Production lines 1–12 — issues & requests*.
   One line of guidance: *S1 means the line is stopped. Anything stopping the line, raise it
   here and call the shift lead — don't wait for the ticket.*

2. **One-column section — Quick links webpart**, tile layout, two links:
   - **Report an issue** → paste the list's new-item URL:
     `https://<tenant>.sharepoint.com/sites/ProductionLines/Lists/Line%20Issues/NewForm.aspx`
   - **All open tickets** → the Line Issues list, Open Tickets view.

3. **Two-column section.**
   - Left (wide): **List webpart** → `Line Issues`, view **Open Tickets**.
   - Right: **List webpart** → `Production Lines`, so line state sits beside the queue.

**Republish** when done. Add the site to Teams (**+** in a channel → SharePoint page) if
the crew already lives in Teams.

---

## Giving people access

**Site permissions → Add members.**

| Who | Group | What they can do |
|---|---|---|
| Operators, line crew | **Members** | Raise tickets, see everything, edit their own |
| Maintenance / Ops leads | **Owners** or a dedicated *Ops* group with Edit on the list | Triage, assign, close anything |
| Plant management | **Visitors** | Read-only |

Item-level permission from step 3 is what stops one operator editing another's ticket.
If you'd rather everyone could edit everything, set Item-level permissions back to
*All items* — one dropdown, no other changes needed.

---

## Editing it later

Everything here is normal SharePoint, so:

- **New line, or renamed line** → edit the *Production Lines* list. The lookup on
  Line Issues follows automatically; nothing else to change.
- **New category or status** → *Line Issues* → column dropdown → *Column settings →
  Edit* → add the choice. Existing tickets keep their old value.
- **New field** → add the column, then add it to the views you want it on.
- **Different colours or thresholds** → edit the two JSON files in
  `provision/formatting/` and paste them back into *Format this column*.

Re-running the provisioning script never overwrites your edits — it only adds what's
missing.
