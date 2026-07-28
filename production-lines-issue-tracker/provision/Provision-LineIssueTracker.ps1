<#
.SYNOPSIS
    Provisions the "Production Lines 1-12 Issue Tracker" SharePoint Online site.

.DESCRIPTION
    Creates (or configures an existing) Team site with:
      * "Production Lines"  - reference list, one item per line, L01..L12
      * "Line Issues"       - the ticket queue (issues AND work requests)
      * Views for the queue: Open, By Line, Line Down, Recently Closed, My Tickets
      * Permission setup so anyone with access can raise a ticket but only
        edit their own, while the Ops team can edit everything

    Everything created here is editable afterwards in the browser -
    Settings > List settings. The script is safe to re-run: it skips
    anything that already exists.

.PREREQUISITES
    Install-Module PnP.PowerShell -Scope CurrentUser
    You need Site Collection Admin on the target site (or tenant admin to create one).
    First run in a tenant may need an admin to consent:  Register-PnPEntraIDAppForInteractiveLogin

.EXAMPLE
    # Against a site you already created in the browser:
    .\Provision-LineIssueTracker.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/ProductionLines"

.EXAMPLE
    # Create the site first, then provision:
    .\Provision-LineIssueTracker.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/ProductionLines" -CreateSite -Owner "you@contoso.com"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $SiteUrl,

    [switch] $CreateSite,

    [string] $Owner,

    [string] $SiteTitle = "Production Lines 1-12",

    # Path to lines.csv - lets you rename lines without touching this script.
    [string] $LinesCsv = (Join-Path $PSScriptRoot "lines.csv"),

    # Optionally load the demo tickets so the views have something in them.
    [switch] $IncludeSampleIssues
)

$ErrorActionPreference = "Stop"
$LINES_LIST  = "Production Lines"
$ISSUES_LIST = "Line Issues"

function Write-Step($msg) { Write-Host "`n== $msg" -ForegroundColor Cyan }
function Write-Skip($msg) { Write-Host "   - $msg (already exists, skipped)" -ForegroundColor DarkGray }
function Write-Made($msg) { Write-Host "   + $msg" -ForegroundColor Green }

# ---------------------------------------------------------------- site --------
if ($CreateSite) {
    if (-not $Owner) { throw "-Owner is required with -CreateSite." }
    Write-Step "Creating site $SiteUrl"
    $tenantAdmin = ($SiteUrl -replace "\.sharepoint\.com.*", "-admin.sharepoint.com")
    Connect-PnPOnline -Url $tenantAdmin -Interactive
    New-PnPSite -Type TeamSite `
                -Title $SiteTitle `
                -Alias ($SiteUrl.Split("/")[-1]) `
                -Owner $Owner `
                -Description "Issue and work-request tracking for production lines 1 to 12." | Out-Null
    Write-Made "Site created"
    Start-Sleep -Seconds 20   # give provisioning a moment to settle
}

Write-Step "Connecting to $SiteUrl"
Connect-PnPOnline -Url $SiteUrl -Interactive
Write-Made "Connected as $((Get-PnPProperty -ClientObject (Get-PnPWeb) -Property CurrentUser).Email)"

# ------------------------------------------------------- reference list -------
Write-Step "List: $LINES_LIST"
$linesList = Get-PnPList -Identity $LINES_LIST -ErrorAction SilentlyContinue
if (-not $linesList) {
    $linesList = New-PnPList -Title $LINES_LIST -Template GenericList -OnQuickLaunch
    Set-PnPList -Identity $LINES_LIST -Description "One item per production line. Edit here to rename lines or change owners."
    Write-Made "Created"
} else { Write-Skip $LINES_LIST }

# Title column is reused as the line code (L01 .. L12).
Set-PnPField -List $LINES_LIST -Identity "Title" -Values @{ Title = "Line Code" }

$lineFields = @(
    @{ Name = "LineName"; Display = "Line Name"; Type = "Text" }
)
foreach ($f in $lineFields) {
    if (-not (Get-PnPField -List $LINES_LIST -Identity $f.Name -ErrorAction SilentlyContinue)) {
        Add-PnPField -List $LINES_LIST -DisplayName $f.Display -InternalName $f.Name -Type $f.Type -AddToDefaultView | Out-Null
        Write-Made $f.Display
    } else { Write-Skip $f.Display }
}
if (-not (Get-PnPField -List $LINES_LIST -Identity "LineOwner" -ErrorAction SilentlyContinue)) {
    Add-PnPField -List $LINES_LIST -DisplayName "Line Owner" -InternalName "LineOwner" -Type User -AddToDefaultView | Out-Null
    Write-Made "Line Owner"
} else { Write-Skip "Line Owner" }

if (-not (Get-PnPField -List $LINES_LIST -Identity "LineState" -ErrorAction SilentlyContinue)) {
    Add-PnPFieldFromXml -List $LINES_LIST -FieldXml @"
<Field Type="Choice" DisplayName="Line State" Name="LineState" StaticName="LineState" Format="Dropdown" Required="TRUE">
  <Default>Running</Default>
  <CHOICES>
    <CHOICE>Running</CHOICE><CHOICE>Degraded</CHOICE><CHOICE>Down</CHOICE><CHOICE>Planned Downtime</CHOICE>
  </CHOICES>
</Field>
"@ | Out-Null
    Write-Made "Line State"
} else { Write-Skip "Line State" }

# Seed the 12 lines from CSV.
Write-Step "Seeding lines from $LinesCsv"
if (-not (Test-Path $LinesCsv)) { throw "lines.csv not found at $LinesCsv" }
$existing = (Get-PnPListItem -List $LINES_LIST -PageSize 100).FieldValues.Title
foreach ($row in Import-Csv $LinesCsv) {
    if ($existing -contains $row.LineCode) { Write-Skip $row.LineCode; continue }
    Add-PnPListItem -List $LINES_LIST -Values @{
        Title     = $row.LineCode
        LineName  = $row.LineName
        LineState = "Running"
    } | Out-Null
    Write-Made "$($row.LineCode) - $($row.LineName)"
}

# ----------------------------------------------------------- issues list ------
Write-Step "List: $ISSUES_LIST"
if (-not (Get-PnPList -Identity $ISSUES_LIST -ErrorAction SilentlyContinue)) {
    New-PnPList -Title $ISSUES_LIST -Template GenericList -OnQuickLaunch | Out-Null
    Set-PnPList -Identity $ISSUES_LIST `
        -Description "Report an issue or raise a work request against any production line." `
        -EnableAttachments $true -EnableVersioning $true
    Write-Made "Created"
} else { Write-Skip $ISSUES_LIST }

Set-PnPField -List $ISSUES_LIST -Identity "Title" -Values @{ Title = "Summary" }

# Lookup to the lines list - this is what ties a ticket to a line.
if (-not (Get-PnPField -List $ISSUES_LIST -Identity "LineRef" -ErrorAction SilentlyContinue)) {
    Add-PnPField -List $ISSUES_LIST -DisplayName "Line" -InternalName "LineRef" -Type Lookup `
        -AddToDefaultView -Required | Out-Null
    Set-PnPField -List $ISSUES_LIST -Identity "LineRef" -Values @{
        LookupList  = $linesList.Id.ToString("B")
        LookupField = "Title"
    }
    Write-Made "Line (lookup)"
} else { Write-Skip "Line (lookup)" }

$choiceFields = @(
@{ Name="RequestType"; Xml=@"
<Field Type="Choice" DisplayName="Ticket Type" Name="RequestType" StaticName="RequestType" Format="RadioButtons" Required="TRUE">
  <Default>Issue</Default>
  <CHOICES><CHOICE>Issue</CHOICE><CHOICE>Request</CHOICE></CHOICES>
</Field>
"@ },
@{ Name="Severity"; Xml=@"
<Field Type="Choice" DisplayName="Severity" Name="Severity" StaticName="Severity" Format="Dropdown" Required="TRUE">
  <Default>S2 - Major</Default>
  <CHOICES>
    <CHOICE>S1 - Line Down</CHOICE><CHOICE>S2 - Major</CHOICE>
    <CHOICE>S3 - Minor</CHOICE><CHOICE>S4 - Cosmetic</CHOICE>
  </CHOICES>
</Field>
"@ },
@{ Name="TicketStatus"; Xml=@"
<Field Type="Choice" DisplayName="Status" Name="TicketStatus" StaticName="TicketStatus" Format="Dropdown" Required="TRUE">
  <Default>New</Default>
  <CHOICES>
    <CHOICE>New</CHOICE><CHOICE>Triaged</CHOICE><CHOICE>In Progress</CHOICE>
    <CHOICE>Waiting on Parts</CHOICE><CHOICE>Resolved</CHOICE><CHOICE>Closed</CHOICE>
  </CHOICES>
</Field>
"@ },
@{ Name="Category"; Xml=@"
<Field Type="Choice" DisplayName="Category" Name="Category" StaticName="Category" Format="Dropdown" Required="TRUE">
  <Default>Mechanical</Default>
  <CHOICES>
    <CHOICE>Mechanical</CHOICE><CHOICE>Electrical</CHOICE><CHOICE>Controls / PLC</CHOICE>
    <CHOICE>Quality defect</CHOICE><CHOICE>Safety</CHOICE><CHOICE>Material supply</CHOICE>
    <CHOICE>Utilities</CHOICE><CHOICE>Changeover</CHOICE><CHOICE>Housekeeping</CHOICE><CHOICE>Other</CHOICE>
  </CHOICES>
</Field>
"@ },
@{ Name="Shift"; Xml=@"
<Field Type="Choice" DisplayName="Shift" Name="Shift" StaticName="Shift" Format="Dropdown">
  <CHOICES><CHOICE>A - Days</CHOICE><CHOICE>B - Afters</CHOICE><CHOICE>C - Nights</CHOICE></CHOICES>
</Field>
"@ })

foreach ($f in $choiceFields) {
    if (-not (Get-PnPField -List $ISSUES_LIST -Identity $f.Name -ErrorAction SilentlyContinue)) {
        Add-PnPFieldFromXml -List $ISSUES_LIST -FieldXml $f.Xml | Out-Null
        Write-Made $f.Name
    } else { Write-Skip $f.Name }
}

$simpleFields = @(
    @{ Display="Details";           Name="Details";         Type="Note" },
    @{ Display="Downtime Minutes";  Name="DowntimeMinutes"; Type="Number" },
    @{ Display="Reported On";       Name="ReportedOn";      Type="DateTime" },
    @{ Display="Target Date";       Name="TargetDate";      Type="DateTime" },
    @{ Display="Resolution";        Name="Resolution";      Type="Note" },
    @{ Display="Reported By";       Name="ReportedByUser";  Type="User" },
    @{ Display="Assigned To";       Name="AssignedTo";      Type="User" }
)
foreach ($f in $simpleFields) {
    if (-not (Get-PnPField -List $ISSUES_LIST -Identity $f.Name -ErrorAction SilentlyContinue)) {
        Add-PnPField -List $ISSUES_LIST -DisplayName $f.Display -InternalName $f.Name -Type $f.Type -AddToDefaultView | Out-Null
        Write-Made $f.Display
    } else { Write-Skip $f.Display }
}

# Age in days - calculated, so the queue can be sorted by how stale a ticket is.
if (-not (Get-PnPField -List $ISSUES_LIST -Identity "AgeDays" -ErrorAction SilentlyContinue)) {
    Add-PnPFieldFromXml -List $ISSUES_LIST -FieldXml @"
<Field Type="Calculated" DisplayName="Age (days)" Name="AgeDays" StaticName="AgeDays" ResultType="Number" Decimals="0">
  <Formula>=ROUND(TODAY()-[Created],0)</Formula>
  <FieldRefs><FieldRef Name="Created" /></FieldRefs>
</Field>
"@ | Out-Null
    Write-Made "Age (days)"
} else { Write-Skip "Age (days)" }

# ------------------------------------------------------------------ views -----
Write-Step "Views on $ISSUES_LIST"
$viewCols = "ID","RequestType","LineRef","Title","Category","Severity","TicketStatus","ReportedByUser","AssignedTo","AgeDays"
$openQuery = "<Where><Neq><FieldRef Name='TicketStatus'/><Value Type='Choice'>Closed</Value></Neq></Where>"

$views = @(
  @{ Title="Open Tickets";     Query="<Where><And>$($openQuery -replace '</?Where>','')<Neq><FieldRef Name='TicketStatus'/><Value Type='Choice'>Resolved</Value></Neq></And></Where><OrderBy><FieldRef Name='Severity'/><FieldRef Name='Created' Ascending='TRUE'/></OrderBy>"; Default=$true },
  @{ Title="Line Down (S1)";   Query="<Where><Eq><FieldRef Name='Severity'/><Value Type='Choice'>S1 - Line Down</Value></Eq></Where><OrderBy><FieldRef Name='Created' Ascending='TRUE'/></OrderBy>"; Default=$false },
  @{ Title="By Line";          Query="$openQuery<OrderBy><FieldRef Name='LineRef'/></OrderBy>"; Default=$false },
  @{ Title="My Tickets";       Query="<Where><Eq><FieldRef Name='Author'/><Value Type='Integer'><UserID Type='Integer'/></Value></Eq></Where><OrderBy><FieldRef Name='Created' Ascending='FALSE'/></OrderBy>"; Default=$false },
  @{ Title="Recently Closed";  Query="<Where><And><Eq><FieldRef Name='TicketStatus'/><Value Type='Choice'>Closed</Value></Eq><Geq><FieldRef Name='Modified'/><Value Type='DateTime'><Today OffsetDays='-30'/></Value></Geq></And></Where><OrderBy><FieldRef Name='Modified' Ascending='FALSE'/></OrderBy>"; Default=$false }
)
foreach ($v in $views) {
    if (-not (Get-PnPView -List $ISSUES_LIST -Identity $v.Title -ErrorAction SilentlyContinue)) {
        Add-PnPView -List $ISSUES_LIST -Title $v.Title -Fields $viewCols -Query $v.Query -SetAsDefault:$v.Default -RowLimit 50 | Out-Null
        Write-Made "View: $($v.Title)"
    } else { Write-Skip "View: $($v.Title)" }
}

# ------------------------------------------------- column formatting ----------
Write-Step "Column formatting"
foreach ($pair in @(@("Severity","severity-column.json"), @("TicketStatus","status-column.json"))) {
    $path = Join-Path $PSScriptRoot "formatting\$($pair[1])"
    if (Test-Path $path) {
        Set-PnPField -List $ISSUES_LIST -Identity $pair[0] -Values @{ CustomFormatter = (Get-Content $path -Raw) }
        Write-Made "$($pair[0]) <- $($pair[1])"
    } else {
        Write-Host "   ! $path not found, skipping" -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------ permissions -----
Write-Step "Permissions on $ISSUES_LIST"
# Everyone with site access can add a ticket and see all tickets, but only edit
# their own. Ops (site Owners/Members you nominate) keep full edit.
Set-PnPList -Identity $ISSUES_LIST -BreakRoleInheritance -CopyRoleAssignments
$l = Get-PnPList -Identity $ISSUES_LIST
$l.WriteSecurity = 2      # 2 = users can only edit items they created
$l.ReadSecurity  = 1      # 1 = users can read all items
$l.Update()
Invoke-PnPQuery
Write-Made "Read all / edit own enforced (change under List settings > Advanced settings)"

# --------------------------------------------------------- sample tickets -----
if ($IncludeSampleIssues) {
    Write-Step "Loading sample tickets"
    $csv = Join-Path $PSScriptRoot "sample-issues.csv"
    if (Test-Path $csv) {
        $lookup = @{}
        Get-PnPListItem -List $LINES_LIST -PageSize 100 | ForEach-Object { $lookup[$_.FieldValues.Title] = $_.Id }
        foreach ($row in Import-Csv $csv) {
            Add-PnPListItem -List $ISSUES_LIST -Values @{
                Title           = $row.Title
                LineRef         = $lookup[$row.LineCode]
                RequestType     = $row.RequestType
                Category        = $row.Category
                Severity        = $row.Severity
                TicketStatus    = $row.Status
                Details         = $row.Details
                Shift           = $row.Shift
                DowntimeMinutes = $row.DowntimeMinutes
            } | Out-Null
            Write-Made $row.Title
        }
    } else { Write-Host "   ! sample-issues.csv not found" -ForegroundColor Yellow }
}

Write-Host "`nDone. Open $SiteUrl and see docs/SHAREPOINT-SETUP.md for the home page layout." -ForegroundColor Cyan
