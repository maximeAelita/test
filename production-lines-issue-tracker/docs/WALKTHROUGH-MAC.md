# Building it in the browser — click by click

Written for a Mac, in Brave (or Safari/Chrome — all the same). **Nothing here uses a
terminal.** Allow about 25 minutes. You can stop after step 5 and have a working tracker;
steps 6–10 are polish.

Keep `provision/lines.csv` open in another tab or in Numbers — you'll paste from it once.

---

## Before you start

Find your SharePoint address. Go to **office.com** → sign in → the **SharePoint** icon in
the left rail. The address bar will read something like
`https://yourcompany.sharepoint.com/...`. That `yourcompany` part is your tenant name.
You'll stay inside this tab for everything below.

---

## Step 1 — Create the site

1. On the SharePoint start page, click **+ Create site** (top left).
2. Choose **Team site**.
3. Pick the blank/standard template if it offers a gallery → **Use template**.
4. Site name: `Production Lines 1-12`. The address fills in automatically.
5. Description: *Issue and work-request tracking for production lines 1 to 12.*
6. Privacy: **Private**. Language: your own. → **Next**.
7. Skip adding members for now → **Finish**.

You land on the new site's home page. **Copy this URL somewhere** — it's the link you'll
send people.

> **No + Create site button?** Your IT has restricted site creation. Ask them for a Team
> site named as above, then come back and start at step 2.

---

## Step 2 — Create the "Production Lines" list

This is the reference list — one row per line. Doing it first matters, because the ticket
list points at it.

1. On the site home page: **+ New** → **List**.
2. Choose **Blank list**.
3. Name: `Production Lines`. Toggle **Show in site navigation** on. → **Create**.

### Add its columns

You're now looking at an empty list with one column called *Title*. For each row in the
table below: click **+ Add column** (right of the last column header), pick the type, fill
in the name, click **Save**.

| Column name | Type |
|---|---|
| Line Name | Single line of text |
| Line Owner | Person |
| Line State | Choice — see below |

For **Line State**, after picking *Choice*, replace the default options with these four,
one per box (use **Add choice** for more boxes):
`Running`, `Degraded`, `Down`, `Planned Downtime`.
Set **Default value** to `Running`.

### Rename Title → Line Code

Click the **Title** column header → **Column settings** → **Rename** → `Line Code` → **Save**.

### Paste the 12 lines in

1. Click **Edit in grid view** (in the toolbar above the list).
2. Open `provision/lines.csv` — double-clicking opens it in Numbers. Select the 12 data
   rows (not the header), **⌘C**.
3. Click the first empty cell under *Line Code* in SharePoint, **⌘V**.
4. Click **Exit grid view**.

You should have 12 rows: Line Code `L01`–`L12`, Line Name `Line 1`–`Line 12`. Set each
**Line State** to `Running` if the paste left them blank.

The codes are padded (`L01`, not `L1`) on purpose — SharePoint sorts text alphabetically,
so unpadded numbers would order 1, 10, 11, 12, 2, 3. If your lines ever get real names,
type them into **Line Name** and leave the codes alone.

---

## Step 3 — Create the "Line Issues" list

This is the ticket queue — both issues and requests.

1. Site home → **+ New** → **List** → **Blank list**.
2. Name: `Line Issues`. Show in site navigation: on. → **Create**.
3. Rename **Title** to `Summary` (column header → *Column settings* → *Rename*).

---

## Step 4 — Add the ticket columns

Same **+ Add column** routine. There are 13; it goes quicker than it looks. Do **Line**
first.

**Line** — type **Lookup**.
- *Select a list as a source*: `Production Lines`
- *Select a column from the list*: `Line Code`
- Turn **Require that this column contains information** on. → **Save**

**Ticket Type** — Choice. Options: `Issue`, `Request`. Default `Issue`. Required on.

**Category** — Choice. Options: `Mechanical`, `Electrical`, `Controls / PLC`,
`Quality defect`, `Safety`, `Material supply`, `Utilities`, `Changeover`,
`Housekeeping`, `Other`. Default `Mechanical`. Required on.

**Severity** — Choice. Options exactly as written, the spacing matters for step 6:
`S1 - Line Down`, `S2 - Major`, `S3 - Minor`, `S4 - Cosmetic`.
Default `S2 - Major`. Required on.

**Status** — Choice. Options: `New`, `Triaged`, `In Progress`, `Waiting on Parts`,
`Resolved`, `Closed`. Default `New`. Required on.

**Shift** — Choice. Options: `A - Days`, `B - Afters`, `C - Nights`. Not required.

| Then these six | Type |
|---|---|
| Details | Multiple lines of text |
| Downtime Minutes | Number |
| Target Date | Date and time (date only) |
| Resolution | Multiple lines of text |
| Reported By | Person |
| Assigned To | Person |

**Age (days)** — type **Calculated**.
- Formula: `=ROUND(TODAY()-[Created],0)`
- Data type returned: **Number**, 0 decimal places. → **Save**

### Turn on attachments

**Settings gear (top right) → List settings → Advanced settings** →
*Attachments to list items*: **Enabled** → **OK**. Photos of the fault are the single most
useful thing on a ticket.

**Your tracker works from here.** Everything below makes it faster to read and safer to
share.

---

## Step 5 — Try it

Click **+ New**. Fill in a test ticket against L01 and save it. If the form shows all your
columns and the Line dropdown lists L01–L12, the two lists are wired together correctly.
Delete the test ticket afterwards (click the row → **⋯** → *Delete*).

---

## Step 6 — Make severity and status colour-coded

1. Click the **Severity** column header → **Column settings** → **Format this column**.
2. In the panel that opens, click **Advanced mode** at the bottom.
3. Delete whatever is in the box.
4. Open `provision/formatting/severity-column.json`, select all (**⌘A**), copy (**⌘C**),
   paste into the box. → **Save**.
5. Repeat for the **Status** column with `provision/formatting/status-column.json`.

Severity now shows as red/amber/blue/grey pills, status as green when resolved. Each pill
carries an icon and its text, so it still reads correctly in greyscale or for colour-blind
viewers.

---

## Step 7 — Add the views

Views are saved filters. **Settings gear → List settings → scroll to Views → Create view →
Standard view.** Make at least the first one.

**Open Tickets** *(tick "Make this the default view")*
- Filter: `Status` **is not equal to** `Resolved`, and — click *Show more columns* —
  `Status` **is not equal to** `Closed`
- Sort: by `Severity`, then by `Created`

**Line Down (S1)**
- Filter: `Severity` **is equal to** `S1 - Line Down`

**By Line**
- Filter: `Status` is not equal to `Closed`
- Under *Group By*: first group by `Line`

**My Tickets**
- Filter: `Created By` **is equal to** `[Me]` — type it with the brackets

---

## Step 8 — Stop people editing each other's tickets

**Settings gear → List settings → Advanced settings** → *Item-level Permissions*:
- Read access: **All items**
- Create and Edit access: **Items that were created by the user**
→ **OK**

Now anyone can raise a ticket and see the whole queue, but only edit their own. Site
Owners can still edit everything. If you'd rather everyone could edit everything, leave
both on *All items*.

---

## Step 9 — Build the home page

Site home → **Edit** (top right).

1. Click the **+** in a section → **Text**. Type a heading and one line of guidance, e.g.
   *S1 means the line is stopped — raise it here and call the shift lead, don't wait for
   the ticket.*
2. **+** → **Quick links** → add two links:
   - **Report an issue** — the URL is your Line Issues list address with
     `/NewForm.aspx` on the end. Easiest way to get it: open the list, click **+ New**,
     and copy the address bar.
   - **All open tickets** — the list's normal address.
3. **+** → **List** → pick `Line Issues`, and set the view to **Open Tickets**.
4. Add another **List** web part for `Production Lines` beside it if you want line state
   visible.
5. **Republish** (top right).

---

## Step 10 — Give people access

**Settings gear → Site permissions → Add members.**

| Who | Add to | What they get |
|---|---|---|
| Operators, line crew | **Members** | Raise tickets, read all, edit their own |
| Maintenance / Ops leads | **Owners** | Triage, assign, close anything |
| Management | **Visitors** | Read only |

Send them the site URL from step 1.

---

## If something looks different

SharePoint's UI shifts between tenants and Microsoft moves things regularly. If a button
isn't where I've said:

- **+ Add column** may sit at the far right of the column headers, or behind a **+** icon.
- **List settings** may be **Settings gear → List settings** or **⋯ → Settings**.
- The **Format this column** panel always has **Advanced mode** at the very bottom — scroll.

Tell me which step and what you're seeing on screen and I'll work out the current path.

---

## About PowerShell on a Mac

You don't need it, but for completeness: the two-minute scripted route needs PowerShell 7
installed first (`brew install --cask powershell`, then run `pwsh`), plus the PnP module.
That's a ~10-minute setup to save ~20 minutes of clicking — not worth it for a one-off.

One genuine Mac limitation: **the site-design route (Option 3 in `IMPORT-OPTIONS.md`) does
not work on macOS at all.** It needs `Connect-SPOService` from the
`Microsoft.Online.SharePoint.PowerShell` module, which is Windows-only. The PnP template
route (Option 1) *does* work on a Mac.
