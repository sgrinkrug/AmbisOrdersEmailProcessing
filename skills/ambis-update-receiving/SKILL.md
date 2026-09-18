---
name: ambis-update-receiving
description: Find person-originating receiving-confirmation emails for AMBIS Pending Receiving purchase-card orders, save end-user confirmation emails and relevant attachments, then dry-run or explicitly update AMBIS with receiving notes, attachments, and an append-only USER_RECEIVED tag when end-user evidence supports full receipt.
---

# AMBIS Update Receiving

## Overview

Use this skill to review AMBIS orders in status `Pending receiving`, search Outlook for receiving-confirmation emails, identify which physical line items and quantities were confirmed received, preserve missing non-duplicate receiving evidence in AMBIS, and either show a dry-run summary or update AMBIS after the user explicitly authorizes production mode.

The `USER_RECEIVED` tag is a manual-review cue for Sergey: it means end-user-provided evidence is present showing that all physical items were received, so he can open the order and perform the AMBIS receiving action manually. It does not mean AMBIS line-item receiving has already been completed.

Default to dry-run mode unless the user clearly asks for production, live, or AMBIS updates. In dry-run mode, do not upload files, add notes, append `USER_RECEIVED`, or make any other AMBIS changes.

## Dry-Run Approval and Production Handoff

A dry-run summary is the production approval package. It must show the exact orders, proposed note text, planned attachment filenames, and `USER_RECEIVED` actions.

When the user responds to that summary with `proceed`, `run production`, `PROD`, `update AMBIS`, or equivalent approval:

- Treat that response as explicit, action-time authorization for every unchanged action displayed in the dry-run summary.
- Proceed directly with production updates.
- Do not request another bulk, per-order, note-publication, upload, or tag confirmation.
- This rule applies equally to single-order and multi-order runs.
- Continue performing all required live duplicate, eligibility, attachment, note, receiving-log, and tag checks. These are verification steps and do not require renewed user approval.

Request new approval only for an affected order when production discovers a material change from the approved dry run, such as:

- Different or additional note text
- A new order or source email
- A new attachment not shown in the dry run
- Changed item or quantity mapping
- Ambiguous or conflicting evidence
- An additional AMBIS action not included in the approved summary

Routine rechecks, updated record counts, upload timestamps, or finding an approved action already completed are not material changes and do not require another confirmation.

## Hard Rules

- Process only AMBIS orders in status `Pending receiving` unless the user explicitly provides a different order-specific scope.
- Work one AMBIS order at a time and output `Working on Seq # <sequence number> ...` before beginning each order.
- If the user specifies one or more sequence numbers, process only those sequence numbers.
- Ask the user to log in when AMBIS, Outlook, Microsoft, CAC/PIV, or vendor pages require authentication.
- Do not send emails.
- Do not mark line items received.
- Do not change order status.
- Do not use AMBIS tags as evidence, scope filters, or skip criteria.
- The only permitted tag write in this skill set is append-only `USER_RECEIVED`, and only when the end-user evidence rules below are satisfied. Do not remove or replace existing tags.
- Treat AMBIS item `RCVD` values, `Pending receiving` status, blank Receiving Log rows, and Receiving Log reversal/unreceive entries as current AMBIS receiving-state signals, not as blockers for preserving receiving evidence or appending `USER_RECEIVED` when end-user-provided evidence shows all physical items were received.
- Receiving-confirmation emails used for notes or attachments must come from a person-originating confirmation. Do not infer receipt from vendor shipping notices, vendor delivery notices, tracking pages, invoices, or order confirmations.
- The confirmation email must contain the AMBIS sequence number in the subject or body.
- Confirmation must come from a person who has some role on the order, such as requester, creator, owner, accountable user, end user, ship-to contact, receiver, or another person present in AMBIS routing/history/notes for that order.
- For `USER_RECEIVED`, require end-user-provided evidence: notes by the end user, emails from the end user, packing slips or receiving forms provided or signed by the end user, or other active AMBIS evidence that is clearly attributable to the end user. If the evidence provider is not clearly the end user, do not append `USER_RECEIVED` unless the user explicitly approves it.
- Vendor delivery confirmations, carrier delivery statuses, package photos, vendor shipping notices, invoices, and order confirmations are not receiving evidence for `USER_RECEIVED`; they do not establish what was actually in the box.
- If the sender's relationship to the order is uncertain, show the evidence and treat the item as review-only until the user approves it.
- Exclude shipping, handling, tax, freight, delivery, postage, credit-card fees, service fees, and other non-item charges from receiving completeness.
- Before any AMBIS update, recheck active notes, active attachments, Attachment History, and Receiving Log to avoid duplicate notes, duplicate active attachments, or stale conclusions.
- For every local file selected for AMBIS upload, invoke `$ambis-find-attachment-on-disk`. Never use or interact with the Windows `Open` file dialog.

## AMBIS Session Keepalive

During long executions, keep the AMBIS session alive without changing AMBIS data. If this skill has been running for 15 minutes or more since the last active AMBIS interaction or keepalive, and the current work is not actively operating the AMBIS screen, invoke `$ambis-keep-alive` once before continuing.

Do not interrupt an in-progress AMBIS upload, note add, `USER_RECEIVED` append, form submission, or verification step; finish the current AMBIS action first.

## AMBIS Workflow

1. Open AMBIS at `https://ambis.niaid.nih.gov` and wait for login if needed.
2. Use the current AMBIS worklist, the saved search named `Pending Receiving`, or the exact sequence number scope requested by the user.
3. For each order, collect:
   - Sequence number
   - Vendor name
   - Order total
   - Current status
   - Payment type
   - Physical item lines, including AMBIS line number, description, ordered quantity, and unit
   - Existing notes
   - Existing active attachments and attachment history
   - Receiving Log
   - Routing/history/notes people who can establish sender role
   - End user, accountable user, ship-to contact, requester, creator, and owner where visible
4. Exclude line items whose descriptions include or equal `S/H`, `shipping`, `handling`, `tax`, `delivery`, `freight`, `postage`, `fee`, `fees`, `credit card fee`, `service fee`, or `contract fee`.
5. Direct navigation to `https://ambis.niaid.nih.gov/order/<SEQ>/summary`, `/notes`, `/attachments`, or `/receiving-log` is acceptable after the order has been opened from the AMBIS list. If direct navigation renders an incomplete page, return to the AMBIS list, open the order from the list, and use the visible tab controls.

## Outlook Search

Search Outlook read-only. Include the Inbox, the `Card confirmations` folder, and order-specific folders under `Inbox\Aquisitions\Pcard\PCard Assignments` when present. Also search any folder that the current mailbox organization makes clearly relevant to AMBIS, P-card, receiving, or the specific sequence number.

Search using combinations of:

- AMBIS sequence number
- Vendor name
- End user, requester, ship-to contact, owner, and other role-holder names
- Item names and descriptions
- Vendor order number, tracking number, or purchase/order ID from AMBIS notes or attachments
- Receiving words such as `received`, `arrived`, `delivered`, `all items`, `partial`, `partially received`, `got`, `package`, `packing slip`, and `delivery confirmation`

For every candidate email, record:

- Sender name and email
- Sender role on the order
- Received date/time
- Subject
- Whether the sequence number appears in the subject or body
- Confirmation text from the sender
- Attachments and attachment types

## Receiving Extraction

Treat an email as receiving-confirmation evidence only when the sender explicitly confirms receipt of some or all physical items. Examples include `I received all items`, `I have received all three posters`, or `only line item 2 was delivered`.

Map the confirmed receipt to AMBIS physical item lines:

- Match by explicit line number when present.
- Otherwise match by item description, quantity, role context, and order scope.
- If the sender says all items were received and the order has one physical item line, apply the statement to that physical item line.
- If the sender says all items were received and the order has multiple physical item lines, apply it to all physical item lines only when the message clearly refers to the full order.
- If quantity is not stated but the sender clearly says all items were received, use the full ordered quantity for the covered physical lines.
- If the item or quantity is ambiguous, mark the row review-only and do not update AMBIS without user approval.

When multiple items are confirmed in one email, group them in one AMBIS note.

## Evidence Versus Current Receiving State

Keep these decisions separate:

1. Preserve receiving evidence. If a qualified person-originating email contains the AMBIS sequence number and explicitly confirms receipt of some or all physical items, upload missing active receiving evidence and add one non-duplicate receiving note for that source when production mode is authorized. Do this even when the current item `RCVD` values are `0`, the order is still `Pending receiving`, or the Receiving Log shows later negative/unreceive rows. Those AMBIS states mean the order is not currently recorded as received; they do not erase the historical source evidence that the user confirmed receipt.
2. Add receiving notes. Receiving notes may say that a named sender confirmed receipt because that is source evidence. Do not write notes as though Codex performed AMBIS receiving or changed AMBIS line-item state.
3. Add the manual-review cue. Append `USER_RECEIVED` only when end-user-provided, non-tag evidence supports that every physical item line was received in full. Current item `RCVD` values, `Pending receiving` status, blank Receiving Log rows, or later negative/unreceive Receiving Log rows do not block this tag; they are the reason Sergey needs the cue to manually perform receiving.

Do not use vendor delivery confirmations, carrier delivery statuses, package photos, vendor shipping notices, invoices, order confirmations, or AMBIS tags as evidence for `USER_RECEIVED`.

## Attachable Evidence

For each qualifying receiving-confirmation email:

- If the email is from the end user and explicitly confirms receipt of some or all physical items, save/export the email itself as a PDF and upload that PDF to the relevant AMBIS order in production mode.
- Keep relevant email attachments as additional evidence. Upload each relevant end-user-provided receiving confirmation, packing slip, signed receipt, receiving form, or similar receipt-supporting attachment in production mode after duplicate checks.
- Do not treat package photos as receiving evidence, and do not upload package photos for this workflow unless the user explicitly asks.
- Do not treat vendor or carrier delivery confirmations as receiving evidence for this workflow, even when they are already present on the order from another workflow.
- If an attachment is PowerPoint or slides, including `.ppt` or `.pptx`, convert it to PDF before trying to upload it to AMBIS.
- If an attachment has another AMBIS-unsupported file type, convert it to PDF when technically feasible and the converted file preserves the evidence.
- Render or otherwise visually verify generated PDFs before upload when feasible, especially for email-to-PDF exports and PowerPoint-to-PDF conversions.

Do not upload duplicate active attachments. Attachment History entries are evidence that a file existed before, but they do not by themselves mean the file is currently active. If a needed receiving evidence file appears only in Attachment History as deleted, treat it as missing and upload it again in production mode.

## File Naming

Use filesystem-safe ASCII filenames and the underscore form of this pattern:

```text
AMBIS_<SEQ>_<Vendor>_<DocumentType>_<OrderOrTrackingNumber>_<SenderName>.<ext>
```

Document type examples:

- `ReceivingConfirmationEmail` for the saved email PDF.
- `ReceivingConfirmation` for a receiving evidence attachment.
- `PackingSlip` for a signed packing slip.

Filename rules:

- Remove spaces and punctuation from vendor and sender components where practical, or replace them with underscores.
- Do not use asterisks, slashes, quotes, or other characters that Windows or AMBIS may reject.
- Use a vendor order number, tracking number, or other strong reference number when visible.
- Use `NoReference` only when no order, tracking, or confirmation number is available.
- Use `.pdf` for exported emails and converted PowerPoint attachments.
- If multiple files would otherwise have the same name, append `_01`, `_02`, etc. before the extension.

## Attachment Upload

Only upload AMBIS attachments when production mode is explicitly authorized. For each authorized upload:

1. Reopen or refresh the AMBIS order.
2. Recheck active attachments for duplicates.
3. Open AMBIS at `https://ambis.niaid.nih.gov/order/<SEQ>/attachments`.
4. If direct navigation renders oddly or incompletely, open the order from the AMBIS list first, then click the Attachments tab.
5. Use the normal AMBIS UI to open `Attachments` -> `UPLOAD FILES`, stopping before `Choose Files`.
6. Invoke `$ambis-find-attachment-on-disk` with the exact expected filename or absolute path. Require it to locate, validate, and select the file through the browser's direct `filechooser` and `setFiles` APIs without opening or using the Windows file dialog.
7. Continue only when the invoked skill returns `selected`, the expected filename is displayed, and `ADD TO REQUEST` is enabled. If direct browser selection is unavailable or fails, leave the upload unsubmitted and report the specific blocker; never fall back to the native file dialog.
8. Click `ADD TO REQUEST` from the AMBIS page.
9. Verify the active attachment table shows the expected filename and that `Records` increased or otherwise reflects the new active file count.

## Note Eligibility

Before adding a receiving note:

- Recheck active notes.
- Do not add a duplicate note for the same source email and same confirmed lines/quantities.
- If a same-source receiving note already exists, do not add another note. The attachment action and append-only `USER_RECEIVED` action may still proceed if they are missing, authorized, and safe to perform.
- If the source is uncertain, the sender role is uncertain, or item/quantity mapping is uncertain, show the proposed note as review-only and ask for approval before production update.

## Note Format

AMBIS notes must be plain text, single-line, and readable after AMBIS trims whitespace. Use `|` as visible section separators. Do not include a `Remaining not confirmed` section in the note.

When a single qualifying email clearly confirms that all physical items on the order were received, do not enumerate every item. Use this compact full-receipt format:

```text
Receiving confirmation | <Sender Name> confirmed all items received | This note was generated by AI
```

When the email confirms specific line items, specific quantities, or only part of the order, use the itemized format:

```text
Receiving confirmation | <Sender Name> confirmed received: line <line #> <item description>, qty <received qty> of <ordered qty>; line <line #> <item description>, qty <received qty> of <ordered qty>. | This note was generated by AI
```

For a partial receipt, say `confirmed partial receipt` only when the email or item coverage is partial:

```text
Receiving confirmation | <Sender Name> confirmed partial receipt: line <line #> <item description>, qty <received qty> of <ordered qty>. | This note was generated by AI
```

Normalize whitespace before adding or displaying the note. Use the sender's natural display name, without parenthetical role labels, in the note body. Do not include the email date, time, subject, or a `Source` section in the AMBIS note. Keep sender role, email date/time, and email subject in the summary table.

Do not collect or rely on the AMBIS `Tags` column or tag widget while determining whether receipt is complete.

## USER_RECEIVED Tag

After note and attachment analysis, examine the combination of end-user-provided, non-tag evidence:

- Active AMBIS notes authored by the end user or explicitly recording end-user confirmation
- Newly found or existing emails from the end user that contain the AMBIS sequence number in the subject or body
- Generated PDFs of qualifying end-user confirmation emails
- Active attachments that the end user provided or signed, such as packing slips, signed receipts, receiving forms, or similar receipt-supporting documents
- Existing active receiving-confirmation evidence that is clearly attributable to the end user

Append the tag `USER_RECEIVED` when there is sufficient end-user-provided evidence that every physical item line on the order has been received in full. This is a cue for manual AMBIS receiving, not a statement that AMBIS receiving has already been performed. Do this even if no new note is added, as long as the existing non-tag end-user evidence is sufficient.

If one qualifying end-user email, note, packing slip, receiving form, or similar document clearly states that all items were received and clearly refers to the full order, treat it as covering all physical item lines even when it does not enumerate them.

Do not append `USER_RECEIVED` when any physical item line or quantity remains unconfirmed, when the evidence provider is not clearly the end user, when receipt evidence is ambiguous, or when the only available support is vendor delivery confirmation, carrier status, package photo, vendor shipping notice, invoice, order confirmation, AMBIS tag, or another non-user source.

For this append-only action, inspect existing visible tag chips only as needed to avoid duplicate `USER_RECEIVED` and to preserve other tags. Do not treat those tags as receipt evidence. If `USER_RECEIVED` is already visibly present, leave it unchanged and report `already present`. If another tag is present, append `USER_RECEIVED` without removing the existing tag when AMBIS supports multiple tags. If the UI appears likely to replace, clear, or hide existing tags, skip the tag append and report `not set - unsafe to append`. If the tag UI requires saving, click `SAVE CHANGES` and verify. If the chip appears and `SAVE CHANGES` remains disabled, treat it as saved automatically only after verifying from the order or list view after a refresh or route change.

## Production Update Order

When production follows an approved dry run and the planned actions remain materially unchanged, execute the numbered steps without requesting additional user confirmation.

In production mode, for each authorized order:

1. Reopen the order and confirm it is still in scope.
2. Recheck existing notes, active attachments, Attachment History, and Receiving Log.
3. Prepare required source files locally with the required filenames.
4. Convert PowerPoint/slides and other unsupported evidence files to PDF as needed.
5. Visually verify generated PDFs when feasible.
6. Upload missing active evidence attachments first.
7. Add one non-duplicate receiving note per source email when eligible.
8. Evaluate full physical-item receipt from end-user-provided notes, qualifying end-user emails, generated email PDFs, active end-user-provided attachments, and other active evidence clearly attributable to the end user. Do not use AMBIS tags, vendor delivery confirmations, carrier statuses, package photos, invoices, or order confirmations as receipt evidence.
9. Append `USER_RECEIVED` only when end-user-provided evidence sufficiently supports full physical receipt and the append can be done without removing other tags. Current AMBIS `RCVD` values, `Pending receiving` status, blank Receiving Log rows, or Receiving Log reversal/unreceive rows do not block the append.
10. Verify every AMBIS change made: attachment filename and record count, note text, and any attempted `USER_RECEIVED` append.

Delete temporary local files created solely for the upload after verification unless keeping them is useful for troubleshooting or the user asks to keep them.

## Final Summary

At the end, display a summary table with these columns:

```text
SEQ | Vendor | Sender | Sender role | Email date/time | Email subject | Confirmed item lines and quantities | Note added? | Email PDF | Additional attachment(s) | USER_RECEIVED tag action | Reason / verification
```

In dry-run mode:

- `Note added?` must be `No`.
- `Email PDF` and `Additional attachment(s)` should show planned filenames and whether conversion is needed.
- `USER_RECEIVED tag action` should be `would append`, `already present`, `not set`, or `not set - unsafe to append`.
- `Reason / verification` must explain why files, notes, or the append-only `USER_RECEIVED` tag would or would not be updated in production.

In production mode:

- State whether each file was uploaded and verified, already active, skipped as duplicate, or review-only.
- State whether each note was added and verified, already existed, skipped as duplicate, or review-only.
- State whether `USER_RECEIVED` was set, already present, or not set, with the reason.
- Explicitly say that emails were not sent, line items were not marked received, and order status was not changed.
