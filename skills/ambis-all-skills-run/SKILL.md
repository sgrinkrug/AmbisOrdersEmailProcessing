---
name: ambis-all-skills-run
description: Dry-run all AMBIS purchase-card support skills and the SAFE-MI follow-up workflow in a fixed order, ending with separate purchase-card and SAFE-MI summary tables without changing AMBIS, SAFE, Outlook, or vendor systems.
metadata:
  short-description: Dry-run AMBIS and SAFE-MI workflows
---

# AMBIS All Skills Run

## Purpose

Use this skill when the user asks for an AMBIS all-skills run, combined AMBIS skill run, full AMBIS dry run, or similar request that should review AMBIS purchase-card work and SAFE-MI follow-up work across the existing AMBIS workflows.

This wrapper coordinates existing AMBIS skills. It does not replace their evidence rules, eligibility rules, duplicate checks, source scopes, file-naming rules, or note formats. Before starting each stage, load the referenced skill if it is not already loaded, then follow that skill's current instructions except where this wrapper explicitly requires dry-run-only behavior and combined final tables.

## Stage Order

Run the stages in this exact order. Complete each stage for all in-scope orders before starting the next stage.

1. `$ambis-citi-transactions`
2. `$ambis-update-order-confirmation`
3. `$ambis-update-invoice-info`
4. `$ambis-update-tracking-info`
5. `$ambis-update-receiving`
6. `$ambis-receiving-drafts`
7. `$ambis-safe-mi`

## Dry-Run Boundary

This combined skill is always dry-run only. It never authorizes production changes, even if one of the child skills normally supports production mode.

- Do not upload AMBIS attachments.
- Do not add AMBIS notes.
- Do not append, remove, replace, or otherwise change AMBIS tags, including `USER_RECEIVED`.
- Do not mark line items received.
- Do not change AMBIS order status.
- Do not send emails.
- Do not create, refresh, update, or send Outlook drafts.
- Do not change SAFE folder status, SAFE Document Type values, SAFE folder-level checkboxes, or other SAFE metadata.
- Do not save persistent files solely for upload. Planned filenames are preview strings derived from the child skill's naming rules and the discovered evidence.
- Use AMBIS, SAFE-MI, Outlook, vendor pages, and any order-status pages read-only, except for login/navigation and permitted non-mutating session keepalive.

If the user wants production updates after reviewing the dry-run result, ask for explicit authorization for the specific workflow, order, attachment, note, draft, or tag action before making any change.

## Shared Scope

Use the user's explicit sequence numbers, saved search, current AMBIS worklist, or other stated scope when provided. Pass that scope to every child stage where it fits that skill's rules. If no scope is provided, use each child skill's default AMBIS source list and eligibility rules.

Keep the child skills' status, payment type, source-folder, date-window, and evidence requirements. Do not broaden a child skill's scope just because this wrapper is running multiple workflows.

Work one AMBIS order at a time within each child stage and show `Working on Seq # <sequence number> ...` before beginning an order when the child skill requires it.

During long runs, follow the child skills' AMBIS session keepalive guidance. `$ambis-keep-alive` may only refresh an already-open AMBIS tab and must not submit forms, save data, add notes, upload files, create drafts, append tags, or otherwise mutate AMBIS or Outlook.

## Stage Output Capture

For every order, source item, shipment, attachment, receiving email, or receiving-draft candidate reviewed, capture the normalized dry-run facts needed for the combined final table:

- Stage name.
- Sequence number.
- Vendor.
- Evidence or source identity, such as email sender/date/subject, existing AMBIS attachment, vendor page, or reason no evidence was found.
- Filename that would be added, using the child skill's exact naming convention when a file would be uploadable in production.
- Note that would be added, using the child skill's exact AMBIS note format when a note would be addable or review-only in production.
- Whether a file would be uploaded in production after explicit authorization.
- Whether a note would be added in production after explicit authorization.
- Dry-run result, duplicate status, review-only status, or reason no action would be taken.

Stage-specific normalization:

- Citi transactions: this is a note-only workflow. Use `None - Citi transaction note only` for `Filename that would be added`.
- Order confirmations: use the planned order-confirmation filename when a non-duplicate attachment source exists. If only a note would be added, explain the attachment outcome in the note per the child skill.
- Invoice information: use the planned invoice or invoice-equivalent filename when a non-duplicate attachment source exists. Preserve invoice, receipt, order, partial, unavailable, duplicate, and review-only distinctions from the child skill.
- Tracking information: create one combined-summary row per unique shipment notification or tracking number. Use the planned shipment-confirmation filename when an uploadable source exists.
- Receiving updates: use the planned receiving-confirmation email PDF and any additional attachment filenames. If multiple files would be added for the same source email, separate filenames with semicolons. Include the planned `USER_RECEIVED` outcome in the dry-run result, not in the filename or note columns.
- Receiving drafts: treat this stage as preview-only, even though the child skill normally creates Outlook drafts and adds the AMBIS packing-slip-instructions note. Use `None - receiving-instruction Outlook draft only` for `Filename that would be added`; capture the draft subject and intended recipients in `Evidence / Source`; use the standard AMBIS note text as the note that would be added only when the draft would be due.
- SAFE-MI: do not include SAFE-MI rows in the purchase-card combined table. Capture SAFE-MI results for the separate SAFE-MI final table described below. Treat the SAFE-MI workflow as read-only preview: identify what folder status updates, Document Type updates, and In-Process checkbox settings would be made if separately authorized, but do not save or change SAFE.

## Combined Final Summary

At the end, display two Markdown summary tables:

1. A purchase-card combined table for stages 1 through 6.
2. A separate SAFE-MI summary table for stage 7.

Do not use the child skills' separate final tables as the final output unless the user specifically asks for them.

The purchase-card combined table must include these columns in this order:

```text
Stage | Sequence # | Vendor | Evidence / Source | Filename that would be added | Note that would be added | Would add file in PROD? | Would add note in PROD? | Dry-run result / reason
```

Fill the table this way:

- `Filename that would be added` must contain the exact planned filename, multiple planned filenames separated by semicolons, or a clear `None - <reason>` value.
- `Note that would be added` must contain the exact single-line AMBIS note that would be added or reviewed in production, or `None - <reason>` when no note would be added.
- `Would add file in PROD?` is `Yes` only when a non-duplicate uploadable file would be added after explicit production authorization.
- `Would add note in PROD?` is `Yes` only when a supported non-duplicate note would be added after explicit production authorization.
- Use `No` for duplicates, missing evidence, unavailable sources, review-only items without order-specific approval, note-only stages with no file, and anything outside the child skill's eligibility rules.
- Include skipped or blocked orders when they explain why no action would be taken.

The separate SAFE-MI summary table must appear after the purchase-card table and must include these columns in this order:

```text
Pass | Order / SAFE folder | Current status | Folder status change that would be made | Document Type changes that would be made | Checkbox changes that would be made | Skipped / exception reason | Dry-run result / issue
```

Fill the SAFE-MI table this way:

- Include Pass 1 Completed 6 Months staging rows and Pass 2 In-Process checkbox review rows when they are in scope.
- `Order / SAFE folder` should include the AMBIS sequence number and SAFE folder name or id when available.
- `Folder status change that would be made` should show the exact previewed status action, such as `New -> In Process`, `None - already In Process`, or `None - skipped`.
- `Document Type changes that would be made` should list each file whose Document Type would be changed, using `filename: old value -> new value`; use `None` when no Document Type change would be made.
- `Checkbox changes that would be made` should list each SAFE checkbox value that would be set or cleared in Pass 2, such as `Missing Invoice: checked`; use `None` for Pass 1-only rows or when no checkbox change would be made.
- `Skipped / exception reason` should include approved-status skips, missing controls, ambiguous document types, ambiguous checkbox basis, system/login issues, or other reasons a SAFE action would not be previewed as ready.
- `Dry-run result / issue` should clearly state that no SAFE changes were saved, plus any validation issue that would need review before production.

After both tables, state plainly that this was a dry run and that no AMBIS attachments, notes, tags, receiving actions, status changes, Outlook drafts, emails, SAFE folder statuses, SAFE Document Type values, or SAFE checkbox values were created or changed.

## Conflict Handling

The child skill wins for domain-specific rules: matching, evidence hierarchy, duplicate detection, status/payment eligibility, Outlook folders, date windows, file naming, note wording, SAFE folder selection, SAFE document classification, and SAFE checkbox interpretation.

This wrapper wins for orchestration rules: stage order, dry-run-only behavior, no Outlook draft creation, no AMBIS or SAFE mutation, the purchase-card combined final summary table, and the separate SAFE-MI final summary table.
