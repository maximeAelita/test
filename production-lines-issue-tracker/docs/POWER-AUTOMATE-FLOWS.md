# Notifications and escalation (Power Automate)

Optional, but the tracker is much more useful with at least flow 1. Build these from the
**Line Issues** list → **Automate → Power Automate → Create a flow**, or start from a blank
*Automated cloud flow*.

None of this is required for the site to work — skip it and the list still functions as a
manual queue.

---

## 1. Line down → tell Ops immediately

The one worth building first.

**Trigger:** *When an item is created or modified* (SharePoint) — site, list `Line Issues`.

**Condition:** `Severity Value` **is equal to** `S1 - Line Down`
**and** `Status Value` **is not equal to** `Closed`.

**If yes:**
1. **Get item** on `Production Lines` where `Line Code` = the ticket's Line, so you have
   the *Line Owner*.
2. **Post message in a chat or channel** (Teams) → your Ops channel:

   > 🔴 **LINE DOWN — @{Line} · @{Title}**
   > Severity S1 · raised by @{Created By DisplayName} · @{Category}
   > @{Details}
   > [Open ticket](@{Link to item})

3. **Send an email (V2)** to the Line Owner with the same content.

**Gotcha:** *created or modified* re-fires on every edit. Add a
**Condition → `Status Value` is equal to `New`** on the first branch, or use a
*Trigger condition* so you don't spam the channel each time someone touches the ticket.

---

## 2. Daily open-ticket digest

**Trigger:** *Recurrence* — daily at 06:00, timezone set to the plant's.

1. **Get items** on `Line Issues`, filter query:
   `TicketStatus ne 'Closed' and TicketStatus ne 'Resolved'`
   Order by: `Severity asc`
2. **Create HTML table** from the results — columns: Line, Summary, Severity, Status, Age (days).
3. **Send an email (V2)** to the shift leads distribution list, subject
   `Open line issues — @{formatDateTime(utcNow(),'dd MMM')}`.

Add a **Condition** around step 3 on `length(body('Get_items')?['value']) is greater than 0`
so nobody gets an empty email on a good morning.

---

## 3. Stale ticket escalation

**Trigger:** *Recurrence* — daily at 07:00.

**Get items** filter query, per severity band:

| Band | Filter |
|---|---|
| S1 open over 4 hours | `Severity eq 'S1 - Line Down' and TicketStatus ne 'Closed' and TicketStatus ne 'Resolved'` then filter on Age in the flow |
| S2 open over 3 days | `Severity eq 'S2 - Major' and TicketStatus ne 'Closed' and TicketStatus ne 'Resolved'` |
| anything open over 14 days | `TicketStatus ne 'Closed' and TicketStatus ne 'Resolved'` |

**Apply to each** → **Send an email** to the plant manager listing what has aged past its
band. Keep it one email per run, not one per ticket — build a variable and send after the
loop.

---

## 4. Acknowledge the reporter

Small, and it's the thing that keeps people using the tracker instead of shouting across
the floor.

**Trigger:** *When an item is created* on `Line Issues`.
**Action:** *Send an email (V2)* to `Created By Email`:

> Ticket #@{ID} logged against @{Line}. Current status: New.
> You'll get another mail when it's assigned or closed. [View ticket](@{Link to item})

Add a second flow on *when an item is modified* with a trigger condition on
`Status` changing to `Resolved`, telling the reporter what was done — populate it from
the **Resolution** field.

---

## Connection notes

- Flows run as **whoever created them**. Create these from a service account if you don't
  want them breaking when someone leaves.
- The Teams action needs the **Microsoft Teams** connector authorised once.
- Test with a throwaway ticket on `L01` before turning the flows on for everyone —
  set them **Off** while building.
