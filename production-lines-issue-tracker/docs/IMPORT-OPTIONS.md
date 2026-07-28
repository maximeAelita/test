# Importing this into SharePoint

Short answer: **the site structure and the data import fine — there are four ways.
The only thing that can't be imported is the JavaScript dashboard**, because modern
SharePoint pages don't execute custom scripts. Options for that are at the bottom.

Pick the row that matches what you have access to:

| You have | Use | Time |
|---|---|---|
| PowerShell + site admin | **Option 1** — PnP template, one command | ~2 min |
| PowerShell + site admin, want to see each step | **Option 2** — the provisioning script | ~10 min |
| Tenant admin, want a reusable "new plant site" button | **Option 3** — site design | ~15 min once, then one click per site |
| No PowerShell at all, just a browser | **Option 4** — Excel / grid paste | ~20 min |

---

## Option 1 — Import the whole site from one file

`provision/pnp-template.xml` is a PnP provisioning template: both lists, every column,
all five views, and the 12 lines as seeded data.

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/ProductionLines" -Interactive
Invoke-PnPSiteTemplate -Path .\provision\pnp-template.xml
```

This also works in reverse, which is the useful part for a second plant or a rebuild:

```powershell
# Export a site you already built and like
Get-PnPSiteTemplate -Out plant-a.xml -Handlers Lists,Fields,Pages,Navigation

# Apply it to a new site
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/PlantB" -Interactive
Invoke-PnPSiteTemplate -Path plant-a.xml
```

**Caveat, stated plainly:** the template file is hand-authored and has not been applied
against a live tenant from here. Apply it to a throwaway site first. If any element is
rejected, Option 2 builds the same result step by step and tells you exactly where it
stopped.

---

## Option 2 — Run the provisioning script

`provision/Provision-LineIssueTracker.ps1`, covered in `SHAREPOINT-SETUP.md`. Slower than
Option 1 but it prints every column and view as it creates them, skips anything already
there, and is safe to re-run. It also sets the read-all/edit-own permission, which the
template and site-design routes can't do.

---

## Option 3 — Register it as a tenant site design

`provision/site-script.json` is a SharePoint **site script**. Registered once by a tenant
admin, it appears in the *Create site* flow, so anyone allowed to make a site gets the
tracker's lists automatically — no PowerShell for the person using it.

```powershell
Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser
Connect-SPOService -Url "https://<tenant>-admin.sharepoint.com"

$content = Get-Content .\provision\site-script.json -Raw
$script  = Add-SPOSiteScript -Title "Production Lines Issue Tracker" -Content $content `
             -Description "Line reference list plus the issue and request queue."

Add-SPOSiteDesign -Title "Production Lines 1-12" -WebTemplate 64 -SiteScripts $script.Id `
  -Description "Issue and work-request tracking for production lines 1 to 12."
```

`-WebTemplate 64` is a Team site; use `68` for a Communication site.

Apply it to a site that already exists:

```powershell
Get-SPOSiteDesign | Format-Table Title, Id
Invoke-SPOSiteDesign -Identity <design-id> -WebUrl "https://<tenant>.sharepoint.com/sites/ProductionLines"
```

The script includes the column formatting, so severity and status arrive already
colour-coded. **It cannot set item-level permissions** — there's no site-script verb for
it. Set that once by hand: *List settings → Advanced settings → Item-level permissions*.

---

## Option 4 — No PowerShell, browser only

This is the route if you can't install modules or don't have admin rights.

**Create each list from the spreadsheet.** SharePoint → **+ New → List → From Excel**
(or *Import spreadsheet*), and upload `provision/lines.csv` / `provision/sample-issues.csv`.
Excel wants a real table, so if the CSV is refused: open it in Excel, select the range,
**Insert → Table**, save as `.xlsx`, and upload that. SharePoint guesses the column types
on import — correct any that come in as text using the type mapping in
`SHAREPOINT-SETUP.md`, then add the choice/lookup/calculated columns by hand.

**Or make the lists empty and paste the rows in.** Often faster and more predictable:
build the columns per `SHAREPOINT-SETUP.md`, then open the list, click **Edit in grid
view**, and paste straight from Excel or the CSV. Grid view accepts a multi-row paste and
matches choice values by text.

**Import the column formatting** the same way regardless of route: column header dropdown
→ *Column settings → Format this column → Advanced mode*, paste
`provision/formatting/severity-column.json`, repeat for status.

**Bring the prototype's tickets across:** the dashboard's **Export CSV** button emits the
same column names as the list, so it pastes into grid view directly. That's the intended
path if you trial the prototype for a couple of shifts first.

---

## The dashboard itself — what's actually possible

The HTML page can't be dropped into a SharePoint page. Custom script is disabled on
modern pages tenant-wide, and the classic Script Editor / Content Editor web parts are
retired. Three real alternatives, worst to best for your case:

**Embed web part — works, with conditions.** Host `dashboard/index.html` somewhere with
HTTPS, then use the **Embed** web part with an `<iframe>` pointing at it. A tenant admin
must first allow the domain: *SharePoint admin centre → Settings → Pages → allow embedding
from these domains* (`Set-SPOTenant -HtmlFieldSecurity`). The page runs in the iframe with
its own storage — it will not read or write the SharePoint list. Fine as a wallboard,
wrong as the system of record.

**SPFx web part — the supported way to get this exact UI.** Rebuild the page as a
SharePoint Framework web part: Node + `@microsoft/generator-sharepoint`, package as
`.sppkg`, upload to the tenant App Catalog, then add it to the page like any other web
part. It can read and write the Line Issues list properly through the SharePoint REST API.
This is a genuine development task — figure a day or two plus an admin to approve the
package — but it's the only route to the dashboard look *with* live list data.

**Power Apps — the no-code middle ground, and what I'd suggest.** From the Line Issues
list → **Integrate → Power Apps → Customize forms** for a nicer ticket form, or **Create an
app** for a full custom UI, then embed it with the **Power Apps** web part. You won't
match the prototype pixel for pixel, but you get live list data, mobile support, and
attachments from a phone camera, with no build pipeline and no admin approval.

**Or skip all three.** The out-of-the-box list web parts plus the column formatting in
`provision/formatting/` already give you colour-coded severity, grouping by line, and the
open queue on the home page. That covers what the dashboard shows, minus the tile board,
and is the version that will still be working in three years with nobody maintaining it.
