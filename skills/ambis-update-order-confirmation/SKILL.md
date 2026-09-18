---
name: ambis-update-order-confirmation
description: Find placed-order or vendor order-confirmation evidence for eligible AMBIS purchase-card orders, attach the source order-confirmation document where possible, then dry-run or explicitly update AMBIS with single-line order-confirmation notes. Use when Codex needs to search recent Outlook email for AMBIS order confirmations, avoid duplicate AMBIS attachments or notes, and produce an AMBIS order-confirmation attachment and note summary.
---

# AMBIS Update Order Confirmation

## Overview

Use this skill to review eligible AMBIS purchase-card orders, search recent Outlook email read-only for placed-order confirmations, attach the order-confirmation source document where possible, and then add a single-line AMBIS note after the user explicitly authorizes updates.

Default to dry-run mode unless the user clearly asks to update AMBIS. In dry-run mode, do not upload attachments or add AMBIS notes; display the proposed attachment action, note text, and whether each order would be updated.

## Hard Rules

- Process only AMBIS orders where current AMBIS Status is `Pending receiving` or `Buyer as PA`.
- Process only AMBIS orders where Payment Type is `Purchase Card (non-OA)`.
- Ignore all other orders.
- Work one AMBIS order at a time and output `Working on Seq # <sequence number> ...` before beginning each order.
- Ask the user to log in when AMBIS, Outlook, Microsoft, CAC/PIV, or vendor pages require authentication.
- Search Outlook read-only for the last 30 days only.
- Treat the workflow as attachment-first, note-second: when updates are authorized, handle the order-confirmation attachment before adding the AMBIS note.
- Do not include item lists in AMBIS order-confirmation notes.
- Do not mark items received.
- Do not change order status.
- Do not read or change AMBIS tags.
- Do not send emails.
- Only upload AMBIS attachments or add AMBIS notes when the user explicitly authorizes an update.
- If a match is uncertain, show the evidence and ask the user before treating it as addable or uploadable.

## AMBIS Session Keepalive

During long executions, keep the AMBIS session alive without changing AMBIS data. If this skill has been running for 15 minutes or more since the last active AMBIS interaction or keepalive, and the current work is not actively operating the AMBIS screen, invoke `$ambis-keep-alive` once before continuing.

Use this keepalive while doing non-AMBIS work such as Outlook searches, local file preparation, PDF export/conversion, evidence review, or final summary preparation. Do not interrupt an in-progress AMBIS upload, note add, form submission, or verification step; finish the current AMBIS action first, then refresh the 15-minute timer from that AMBIS interaction.

`$ambis-keep-alive` may only refresh an already-open AMBIS tab in Chrome. It does not authorize uploads, notes, status changes, tag reads or changes, receiving actions, emails, or any other AMBIS data mutation.

## AMBIS Workflow

1. Open AMBIS at `https://ambis.niaid.nih.gov` and wait for the user to log in if needed.
2. Use the current AMBIS worklist, saved search, or relevant order list the user has requested.
3. For each listed order, open the order summary and collect:
   - Sequence number
   - Vendor name
   - Order total
   - Existing notes
   - Existing attachments
   - Current AMBIS status
   - Payment type
4. Skip orders whose current status is not `Pending receiving` or `Buyer as PA`.
5. Skip orders whose payment type is not `Purchase Card (non-OA)`.
6. Use existing AMBIS notes to detect duplicate order-confirmation notes. Existing shipping confirmation or tracking confirmation notes do not block adding a new order-confirmation note.
7. Use existing AMBIS attachments to detect duplicate order-confirmation documents before searching Outlook or proposing any upload.
8. When an existing AMBIS order-confirmation note or attachment has a visible vendor order/confirmation number, treat it as a duplicate only for that same vendor order/confirmation number. A different visible order/confirmation number is a distinct order confirmation and may be addable, especially for exchanges, replacements, returns, or reordered items.
9. Do not skip Outlook solely because an older order-confirmation attachment exists. Skip Outlook only when the existing AMBIS evidence clearly covers the same current vendor order/confirmation number, or when no order/confirmation number is known and the existing evidence matches the same document by filename, source email subject/date, or other strong source identity.
10. If AMBIS notes, attachments, item text, or other visible non-tag order context mention an exchange, replacement, return, reorder, or wrong-item correction, search Outlook for a later/new confirmation even if an older order-confirmation file or note already exists.
11. If a clear same-number order-confirmation attachment already exists in AMBIS and no exchange/replacement context suggests a later order, skip Outlook search for that order unless the AMBIS order-confirmation note is missing and the user specifically asked to add or review notes. Mark `Confirmation Found?` as `Yes (existing AMBIS attachment)`, `Attachment Found?` as `Yes`, `Will upload file in PROD` as `No`, `Attachment Uploaded?` as `No`, `Existing Attachment?` as `Yes`, and explain that Outlook search was skipped because the same order-confirmation file already exists.
12. When direct navigation is helpful, AMBIS order summaries commonly use `https://ambis.niaid.nih.gov/order/<sequence>/summary`.

## Outlook Search

Search Outlook read-only for order confirmation emails from the last 30 days only. Include Inbox, Card confirmations, and order-specific folders under `Inbox\Aquisitions\Pcard\PCard Assignments`.

Before searching Outlook for an eligible order, check AMBIS attachments and notes first. If AMBIS already has a clear order-confirmation attachment or note for the same visible vendor order/confirmation number, skip the Outlook search for that number unless the user specifically requested missing-note review or note repair.

Do not skip the Outlook search when the order may have a later distinct confirmation, such as exchange, replacement, return, reorder, or wrong-item correction context. In those cases, search for newer vendor order/confirmation numbers and compare them against the existing AMBIS order/confirmation numbers.

Search using combinations of:

- AMBIS sequence number
- Vendor name
- Vendor order number, if already known
- Existing AMBIS order/confirmation numbers, to distinguish duplicates from newer distinct confirmations
- Purchase/order ID, if already known
- Quote number, if already known
- Exchange, replacement, return, reorder, and wrong-item terms when AMBIS context suggests a later vendor order may exist
- Confirmation-related words such as `confirmed`, `confirmation`, `order placed`, `order received`, `accepted`, `charged`, `receipt`, and `thank you for your order`

Find strong evidence that the vendor order was placed, confirmed, received, accepted, or charged. Shipping-only, delivery-only, tracking-only, or delay-only messages are not placed-order confirmations for this skill.

Record the source email sender email address, email date, and subject for every proposed order-confirmation attachment or note.

## Attachable Source Selection

When a matching placed-order confirmation is found, identify whether there is an attachable order-confirmation source:

- Prefer a vendor-provided confirmation PDF or document attached to the source email.
- If no vendor-provided attachment exists, use the confirmation email itself as the source document where technically possible, such as saving, printing, or exporting the email to PDF.
- If the source email has neither a usable vendor attachment nor an exportable email body, record that no attachable order-confirmation document was available.
- Do not use invoice-only, shipping-only, delivery-only, tracking-only, or delay-only documents unless they also clearly show placed-order/order-confirmation evidence.
- If the source file is not a PDF, preserve the original extension only if AMBIS accepts it for order-confirmation attachments. Otherwise convert or export to PDF and use the `.pdf` extension.

In dry-run mode, identify the source and planned filename but do not upload, save persistent files, or alter AMBIS.

## Attachment Duplicate Checks

Whenever this workflow needs to choose a local order-confirmation file in AMBIS, invoke `$ambis-find-attachment-on-disk` with the expected filename or absolute path, sequence number, document purpose, and current AMBIS tab. Use the helper to locate, validate, and select the file through the browser file-chooser API. Never use the Windows Open dialog or duplicate the helper's file-selection procedure here. The helper does not authorize or submit the upload; this skill remains responsible for authorization, duplicate checks, choosing the attachment type, clicking `ADD TO REQUEST`, verifying the resulting attachment, and cleanup.

Before marking an attachment uploadable:

- Recheck the AMBIS attachments area.
- Treat an existing AMBIS attachment as a duplicate if it appears to be the same order-confirmation document by document type, vendor, same order/confirmation number, source email subject/date, or filename.
- When both the existing AMBIS evidence and the new source have visible order/confirmation numbers, duplicate status is controlled by the order/confirmation number: same number means duplicate; different number means a distinct confirmation unless other evidence proves it is the same vendor order.
- Do not upload duplicate order-confirmation documents.
- If the existing attachment probably matches but the evidence is not certain, mark the attachment as review-only and ask the user before upload.
- Existing AMBIS notes control whether a new note can be added; existing AMBIS attachments control whether a document can be uploaded.
- If the same confirmation note already exists but no matching order-confirmation attachment exists, the attachment may still be uploadable after explicit authorization, but do not add a duplicate note.

## File Naming

Rename every uploaded file so the filename clearly identifies it as an order confirmation. Do not upload vendor files using vague original names such as `invoice.pdf`, `document.pdf`, `receipt.pdf`, or `attachment.pdf`.

Use the same naming convention whether the source is a vendor attachment or an email printed/exported to PDF:

```text
AMBIS_<SequenceNumber>_OrderConfirmation_<VendorName>_<ConfirmationOrOrderNumberOrEmail>_<SourceDate>.pdf
```

Examples:

```text
AMBIS_123456_OrderConfirmation_FisherScientific_PO987654_2026-08-19.pdf
AMBIS_123456_OrderConfirmation_AmazonBusiness_Order112-1234567-1234567_2026-08-19.pdf
AMBIS_123456_OrderConfirmation_Staples_EmailConfirmation_2026-08-19.pdf
```

Filename rules:

- Use filesystem-safe ASCII only.
- Do not use special characters, slashes, quotes, or extra spaces.
- Collapse repeated spaces and separators.
- Use `YYYY-MM-DD` for the source date.
- Use `EmailConfirmation` when no order/confirmation number is visible.
- If multiple confirmation files are needed for the same order, append `_01`, `_02`, etc. before the extension.

## Note Eligibility

Before marking a note addable:

- Recheck existing AMBIS notes.
- If the same order confirmation is already recorded, mark the note result as duplicate and do not add a new note.
- When a new source has a visible order/confirmation number, compare it to visible order/confirmation numbers already recorded in AMBIS notes. Same number means duplicate; different number means a distinct order confirmation note may be addable.
- If no strong placed-order confirmation is found, do not generate a note.
- If an order/confirmation number is not visible in the source evidence, omit the order/confirmation section entirely from the note.

## Note Format

AMBIS notes must be plain text only, concise, and readable as one single line. Use short plain-English sentences instead of `|` separators. Do not include source email sender, date, or subject in the AMBIS note itself; keep source details in the dry-run or final summary for review.

Normalize note whitespace before adding or displaying a note: use ordinary ASCII spaces only, collapse repeated spaces, and ensure there is exactly one space before `was found` in phrases such as `confirmation # <number> was found.`

Every AI-generated note must include the attachment outcome and end with:

```text
This note was generated by AI
```

Use one of these attachment outcome sentences:

- `File <filename> was added.`
- `File <filename or description> already existed in AMBIS.`
- `No order-confirmation file was available.`
- `Order-confirmation file <filename or description> was review-only.`

In dry-run mode, proposed notes may describe the note that would be added after an authorized update completes. The final summary must still make clear that no attachment was uploaded and no note was added during the dry run. When showing an explicitly dry-run-only preview, use `would be added` rather than `was added` to avoid implying AMBIS was changed.

If an order/confirmation number is visible, use:

```text
Order confirmation from vendor <vendor name>, order total: <total>, confirmation # <number> was found. <Attachment outcome sentence> This note was generated by AI
```

If an order/confirmation number is not visible, omit that section entirely:

```text
Order confirmation from vendor <vendor name>, order total: <total>. <Attachment outcome sentence> This note was generated by AI
```

## Updating AMBIS

Only update AMBIS when the user explicitly authorizes updates. For each authorized order:

1. Reopen or refresh the AMBIS order summary.
2. Confirm the order is still Status `Pending receiving` or `Buyer as PA`.
3. Confirm the Payment Type is still `Purchase Card (non-OA)`.
4. Recheck existing notes for duplicate order confirmations. Existing shipping confirmation or tracking confirmation notes do not block adding a new order-confirmation note.
5. Recheck existing attachments for duplicate order-confirmation documents.
6. If the order is review-only, stop before uploading or adding a note unless the user gave order-specific approval.
7. If an attachment is uploadable, save or export the source document locally with the required filename.
8. Open the AMBIS attachments area and invoke `$ambis-find-attachment-on-disk` to locate, validate, and select the saved file. If the helper does not return `selected`, do not submit the upload.
9. After a successful selection, choose the Order Confirmation attachment type/category where AMBIS supports one, click `ADD TO REQUEST`, and verify the attachment appears in AMBIS.
10. After the attachment action is complete or determined unavailable/already existing, add only notes still marked addable by this workflow.
11. Open Notes.
12. Click New Note.
13. Paste the exact addable single-line note with the final attachment outcome.
14. Click Add Note.
15. Verify the note appears in AMBIS.
16. Do not make any other changes.

Delete temporary local files created solely for the upload after verifying AMBIS accepted the attachment, unless keeping them is necessary for troubleshooting or the user asks to keep them.

## Final Summary

At the end, display a summary table with these columns:

```text
Sequence # | Vendor | Confirmation Found? | Attachment Found? | Will upload file in PROD | Will update Note in PROD | Attachment Uploaded? | Existing Attachment? | AMBIS note updated? | Note / Reason
```

In dry-run mode:

- `Will upload file in PROD` must be `Yes` only when a non-duplicate, uploadable order-confirmation source is available and would be uploaded after explicit production authorization. Use `No` when no attachable source exists, a matching AMBIS attachment already exists, the evidence is duplicate, the source is unavailable, or the item is review-only without order-specific approval.
- `Will update Note in PROD` must be `Yes` only when a non-duplicate order-confirmation note would be added after explicit production authorization and after the attachment outcome is known. Use `No` when no eligible note exists, a matching note already exists, evidence is missing, or the item is review-only without order-specific approval.
- `Attachment Uploaded?` must be `No`.
- `AMBIS note updated?` must be `No`.
- `Note / Reason` must contain the exact single-line plain-text note that would be added or reviewed, or a short reason when no note would be added.
- State whether the attachment source was a vendor attachment, exported email PDF, already-existing AMBIS attachment, unavailable source, duplicate, or review-only.

In update mode:

- `Will upload file in PROD` and `Will update Note in PROD` should show the eligible production action intended for the row immediately before performing it. If the action later fails or is skipped after a duplicate recheck, explain the final outcome in `Attachment Uploaded?`, `AMBIS note updated?`, and `Note / Reason`.
- `Attachment Uploaded?` should be `Yes` only when the order-confirmation document was uploaded and verified in AMBIS.
- `Existing Attachment?` should be `Yes` when a matching AMBIS order-confirmation attachment already existed.
- `AMBIS note updated?` should be `Yes` only when the note was added and verified in AMBIS.
- `Note / Reason` must state the final action taken or why no attachment or note was added.
