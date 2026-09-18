---
name: ambis-update-invoice-info
description: Search Outlook for vendor-originating invoice, invoice-equivalent receipt, or price-containing order email evidence for eligible AMBIS purchase-card orders, attach new non-duplicate invoice documents where possible, then dry-run or explicitly update AMBIS with a concise attachment-outcome note. Use when Codex needs an attachment-first invoice workflow for AMBIS Pending Receiving or recent NBS-forwarded orders.
---

# AMBIS Update Invoice Info

## Overview

Use this skill to review eligible AMBIS purchase-card orders, search Outlook read-only for invoice or invoice-equivalent receipt evidence, attach any new non-duplicate invoice document to AMBIS where possible, and then add a concise AMBIS note only after the attachment outcome is known.

Default to dry-run mode unless the user explicitly authorizes production updates. In dry-run mode, do not upload attachments, add notes, read or change tags, mark received, change status, send emails, or otherwise mutate AMBIS or Outlook. Show what would be attached and what note would be added after approval.

## Hard Rules

- Default source lists are the AMBIS saved searches `Pending Receiving` and `NBS 30 days`.
- Process only AMBIS orders where current Status is `Pending receiving`, `Buyer as PA`, or `Archive Requester`.
- Process only AMBIS orders where Payment Type is `Purchase Card (non-OA)`.
- Work one AMBIS order at a time and output `Working on Seq # <sequence number> ...` before beginning each order.
- Ask the user to log in when AMBIS, Outlook, Microsoft, CAC/PIV, or vendor pages require authentication.
- During runs that last more than 15 minutes, call `$ambis-keep-alive` about every 15 minutes while the workflow is not actively operating the AMBIS screen, such as during Outlook searching, file export, evidence analysis, or summary preparation.
- Treat the workflow as attachment-first, note-second: decide and complete the attachment action before adding or previewing the final note outcome.
- Check existing AMBIS attachments before searching Outlook.
- Existing AMBIS invoice attachments prevent duplicate uploads, but they do not block uploading a later or otherwise different vendor invoice. After the AMBIS attachment precheck, perform a targeted Outlook search for order-specific invoice candidates even when AMBIS already has an invoice or invoice-equivalent attachment. If Outlook reveals a new invoice document that is materially different from the existing attachment, treat it as uploadable after normal authorization and production rechecks.
- Do not treat quotes, packing slips, shipping-only confirmations, delivery-only confirmations, RMAs, tax exemption certificates, or documents that say they are not invoices as invoices.
- If no clearer invoice or paid receipt exists, treat a vendor order confirmation or order acknowledgement as invoice-equivalent only when the same vendor-originating document or email is strongly matched to the AMBIS order and itself contains a visible price, order total, amount charged, or amount paid.
- Require an order-specific anchor before accepting a document or number: AMBIS sequence number, vendor order number, purchase/order ID, quote number, matching total shown in the vendor evidence, or another strong control reference shown in the vendor evidence.
- Do not combine evidence across sources to satisfy invoice acceptance. The vendor-originating document or email must itself provide the vendor/source, order-specific anchor, and at least one visible price or amount. AMBIS notes, internal emails, purchaser emails, saved-search fields, card confirmations, or remembered order details can corroborate a match, but they cannot supply the missing vendor origin, price, amount, or transaction details.
- Do not upload duplicate invoice documents.
- Do not add duplicate AMBIS notes.
- Only upload AMBIS attachments or add AMBIS notes when the user explicitly authorizes production updates.
- Even in production mode, do not read or change tags, mark received, change status, or send emails unless the user separately asks for that exact action. This invoice workflow only handles Invoice attachments and invoice notes.
- If a match is uncertain, show the evidence and ask the user before treating it as addable or uploadable.

## AMBIS Session Keepalive

For long-running work, track when AMBIS was last actively used or refreshed. If about 15 minutes have passed and the current work is outside AMBIS, invoke `$ambis-keep-alive` once before continuing non-AMBIS work.

Use keepalive only as session protection. Do not invoke it while actively editing, uploading, saving, adding a note, or otherwise operating an AMBIS screen. If an AMBIS operation is underway when the 15-minute point arrives, finish the current AMBIS operation first; that active AMBIS use resets the keepalive timer.

If `$ambis-keep-alive` reports no already-open AMBIS tab, Chrome is unavailable, or the refresh fails, record the failure in the working notes or final summary and continue when possible. Ask the user to log in again only if AMBIS actually requires reauthentication.

## AMBIS Precheck

Open AMBIS at `https://ambis.niaid.nih.gov` and use both the `Pending Receiving` and `NBS 30 days` saved searches unless the user requested a different source list. Combine the results into one de-duplicated worklist by AMBIS sequence number.

For each order, open the order summary and collect:

- Sequence number
- Source saved search or searches
- Vendor name
- Order total
- Payment type
- Current status
- Existing notes
- Existing attachments
- Item details
- Vendor order numbers
- Purchase/order IDs
- Quote numbers
- Known control references

Skip orders that are no longer eligible by status or payment type. When direct navigation is helpful, AMBIS order summaries commonly use `https://ambis.niaid.nih.gov/order/<sequence>/summary`.

Before searching Outlook, inspect existing AMBIS attachments. Treat an existing attachment as a clear invoice attachment when its document type, filename, visible title, vendor, invoice number, receipt number, order number, source email subject/date, or content preview shows it is already a matching invoice or invoice-equivalent receipt for that order.

If a clear invoice attachment already exists, use it as the baseline for duplicate checking rather than as an automatic stop. Perform a targeted, date-restricted Outlook search against the order anchors, invoice words, sender, subject, and attachment names to determine whether a newer, clearer, or materially different invoice exists. If a clear AMBIS invoice already exists and the targeted search finds no new invoice candidate, broad body scans are optional unless the user specifically asks for note repair or audit. Existing AMBIS notes control whether a new note can be added; existing AMBIS attachments control whether a document is duplicate or a distinct upload candidate.

When an existing AMBIS attachment is only an invoice-equivalent receipt, payment receipt, order-confirmation fallback, or exported email body, and Outlook contains a vendor invoice PDF or document for the same order, treat the vendor invoice as a clearer distinct document unless it is visibly the same document or same invoice/receipt/order evidence already attached.

## Outlook Search

Search Outlook read-only for the last 45 days from the run date. As of August 20, 2026, that date window is July 6, 2026 through August 20, 2026.

Include:

- Inbox
- Card confirmations
- Order-specific folders under `Inbox\Aquisitions\Pcard\PCard Assignments`

Prefer targeted folders and date-restricted searches. Search subject, sender, attachment names, and order-specific references before doing broad body scans.

Search using combinations of:

- AMBIS sequence number
- Vendor name
- Vendor order number
- Purchase/order ID
- Quote number
- Invoice number, if already known
- Item names, descriptions, and catalog numbers
- Invoice-related words such as `invoice`, `receipt`, `paid`, `charged`, `payment`, `statement`, `tax invoice`, `sales receipt`, and `billing`

Be careful with short vendor aliases such as `CTI`; match them as exact vendor terms, not inside ordinary words.

Record source details for the dry-run or final summary: source folder, sender, date, subject, matched references, attachment filenames, and whether the evidence came from a vendor attachment or email body. Do not include those source details in the AMBIS note itself.

## Invoice Evidence Rules

Use this evidence hierarchy:

1. Prefer a vendor invoice PDF or document attached to the email.
2. If no invoice attachment exists, accept a vendor receipt when it is invoice-equivalent final transaction evidence showing vendor, date, amount charged or paid, and an order, receipt, or invoice number if available.
3. If no clearer invoice or paid receipt exists, accept a vendor email body as the invoice-equivalent source only when the body itself is from the vendor or an identifiable vendor fulfillment, billing, or payment partner, is strongly matched to the AMBIS order, and contains a visible price, order total, amount charged, or amount paid.

This hierarchy also applies when AMBIS already has an invoice-equivalent attachment. A true vendor invoice PDF or document found later is a stronger source than an existing receipt, order-confirmation fallback, or exported email body and may be uploaded as an additional invoice when it is not a duplicate.

A price-containing vendor order email can count even when the subject or body calls it an order confirmation, order acknowledgement, or order received notice. It must still show enough transaction detail to support the AMBIS order: vendor or vendor partner, date, order number or other strong order control reference if available, and a visible price, order total, amount charged, or amount paid in the vendor-originating evidence. A visible `Amount Charged`, `Amount Paid`, or payment card section makes the match stronger, but the minimum requirement is that the vendor evidence itself shows at least one price or amount.

Do not accept an email body when the apparent match requires taking the vendor sender or subject from one source and the price, amount, order number, or transaction details from AMBIS notes, internal messages, purchaser-sent messages, card confirmation records, or other non-vendor sources. When a vendor or vendor-partner email discusses an order but does not itself show a price or amount, mark it review-only or no invoice found with the reason `vendor email lacks visible price/amount`.

If no attachment exists but the email body itself is the invoice or invoice-equivalent receipt, export or print the email to PDF where technically possible. If an email body cannot be exported, record the invoice evidence as found but the attachment source as unavailable.

Do not accept a document solely because it mentions an order. A vendor document or email must be tied to the AMBIS order by a strong anchor shown in that same vendor evidence, such as sequence number, vendor order number, purchase/order ID, quote number, matching order total, or another control reference.

Do not treat these as invoice evidence unless they independently satisfy the hierarchy above:

- Quotes
- Packing slips
- Shipping-only confirmations
- Delivery-only confirmations
- RMAs
- Tax exemption certificates
- Documents that state they are not invoices

Partial shipments are allowed. If the best available invoice-equivalent evidence covers only part of the AMBIS order, record it as partial in the dry-run/final summary. A partial-shipment email must be tied to a vendor order number, shipment/order line, item set, shipment amount, or other strong control reference. Do not use a partial-shipment document as proof of the full order total unless it also shows the full AMBIS order total or final charged/paid amount. If multiple partial invoice-equivalent files are needed, attach or preview each separately and append `_01`, `_02`, etc. to the filenames.

## Attachment Selection And Duplicate Checks

Whenever this workflow needs to choose a local invoice file in AMBIS, invoke `$ambis-find-attachment-on-disk` with the expected filename or absolute path, sequence number, document purpose, and current AMBIS tab. Use the helper to locate, validate, and select the file through the browser file-chooser API. Never use the Windows Open dialog or duplicate the helper's file-selection procedure here. The helper does not authorize or submit the upload; this skill remains responsible for authorization, duplicate checks, clicking `ADD TO REQUEST`, verifying the resulting attachment, and cleanup.

For each supported invoice match, identify the attachable source:

- Prefer the vendor invoice PDF or document attached to the source email.
- If no vendor attachment exists, use an exported or printed PDF of the invoice/receipt email body.
- If no clearer invoice or paid receipt exists, use an exported or printed PDF of the matched price-containing vendor order email body.
- If there is no usable attachment and the email body cannot be exported, mark the file as unavailable.

Before marking an attachment uploadable:

- Recheck existing AMBIS attachments.
- Avoid duplicates by checking document type, vendor, invoice number, receipt number, order number, source email subject/date, and filename.
- Treat a new invoice candidate as different from an existing AMBIS invoice attachment when it has a different invoice, receipt, order, quote, or transaction number; a different source attachment filename or source email date; a different visible document title; a different amount, paid amount, item set, or shipment scope; or when it is a true vendor invoice PDF/document and the existing attachment is only an invoice-equivalent receipt, order-confirmation fallback, payment receipt, or exported email body.
- Treat a new invoice candidate as duplicate when it appears to be the same document or same transaction evidence already attached, even if the filename was reformatted, exported again, or attached from a later email in the same thread.
- Do not remove, replace, or rename the old AMBIS attachment. Add the different new invoice as an additional Invoice attachment.
- If an existing AMBIS attachment probably matches but is not certain, mark the result review-only and ask before upload.
- If the same invoice note already exists but no matching invoice attachment exists, the attachment may still be uploadable after explicit authorization, but do not add a duplicate note.

In dry-run mode, identify the source and planned filename but do not upload files or alter AMBIS.

## File Naming

Rename every uploaded invoice file so the filename clearly identifies it as an invoice. Use filesystem-safe ASCII filenames only.

Use the same convention for vendor attachments and email-exported PDFs:

```text
AMBIS_<SequenceNumber>_Invoice_<VendorName>_<EvidenceLabelOrEmailToken>[_<Identifier>]_<SourceDate>.pdf
```

Examples:

```text
AMBIS_123456_Invoice_DellTechnologies_Invoice_123456789_2026-08-17.pdf
AMBIS_123456_Invoice_Staplesadvantage_Receipt_7685476268_2026-08-18.pdf
AMBIS_123456_Invoice_CDWGovernment_Order_1CKT8V3_2026-08-07_01.pdf
AMBIS_123456_Invoice_CTI_EmailReceipt_2026-08-20.pdf
```

Filename rules:

- Use filesystem-safe ASCII only.
- Remove special characters, slashes, quotes, and extra spaces.
- Collapse repeated spaces and separators.
- Use `YYYY-MM-DD` for the source date.
- When an invoice, receipt, or order identifier has a visible label and number, keep the label and number in separate underscore-delimited segments, with an underscore before and after the number; for example `Invoice_123456789_`, `Receipt_7685476268_`, or `Order_1CKT8V3_`. Do not concatenate the label and number, such as `Invoice123456789`, `Receipt7685476268`, or `Order1CKT8V3`.
- Use `EmailReceipt` when the source is an exported email receipt and no invoice or receipt number is visible.
- Use `EmailOrderTotal` when the source is a fallback order-matched email body that contains the AMBIS order total but no invoice or receipt number.
- If multiple invoice files are needed for the same order, append `_01`, `_02`, etc. before the extension.

## Note Eligibility

Before marking a note addable:

- Recheck existing AMBIS notes.
- If the same invoice or receipt is already recorded, mark the note result as duplicate and do not add a new note.
- If no strong invoice, paid receipt, or price-containing vendor invoice-equivalent order email is found, do not generate a note.
- Build the note only after the attachment outcome is known: `was added`, `already existed`, `would be added`, or `was unavailable`.

## Note Format

AMBIS notes must be plain text, one line, concise, and readable without line breaks. Do not include long item lists or source email details in the AMBIS note; keep source details in the dry-run or final summary.

Every AI-generated note must end with:

```text
This note was generated by AI
```

If an invoice, receipt, or accepted fallback order number is visible, use:

```text
Invoice from vendor <vendor name>, order total: <total>, invoice/receipt/order # <number> was found. File <filename> <was added / already existed / would be added / was unavailable>. This note was generated by AI
```

If no invoice, receipt, or accepted fallback order number is visible, use:

```text
Invoice or invoice-equivalent receipt from vendor <vendor name>, order total: <total>, was found. File <filename> <was added / already existed / would be added / was unavailable>. This note was generated by AI
```

In dry-run mode, use `would be added` for an uploadable file so the preview does not imply AMBIS was changed. If a matching AMBIS invoice attachment already exists, use `already existed`. If the invoice evidence was found but no attachable file can be used or exported, use `was unavailable`.

## Production Updates

Only update AMBIS when the user explicitly authorizes production updates. For each authorized order:

1. Reopen or refresh the AMBIS order summary.
2. Confirm the order is still Status `Pending receiving`, `Buyer as PA`, or `Archive Requester`.
3. Confirm Payment Type is still `Purchase Card (non-OA)`.
4. Recheck existing attachments for duplicate invoices or invoice-equivalent receipts, and distinguish duplicates from materially different invoice documents that should be added.
5. Recheck existing notes for duplicate invoice notes.
6. If the order is review-only, stop before uploading or adding a note unless the user gave order-specific approval.
7. If an attachment is uploadable, save or export the source document locally with the required filename.
8. Invoke `$ambis-find-attachment-on-disk` to locate, validate, and select the saved file in the AMBIS upload control. If the helper does not return `selected`, do not submit the upload.
9. After a successful selection, choose the Invoice attachment type/category where AMBIS supports one, click `ADD TO REQUEST`, and verify the attachment appears in AMBIS.
10. Determine the final attachment outcome.
11. Add the note only if it is still non-duplicate and the attachment outcome is known.
12. Verify the note appears in AMBIS.
13. Do not make any other AMBIS changes.

Delete temporary local files created solely for the upload after verifying AMBIS accepted the attachment, unless keeping them is necessary for troubleshooting or the user asks to keep them.

## Final Summary

At the end, display a summary table with these columns:

```text
Sequence # | Vendor | Order total | Invoice Found? | Invoice/Receipt # | Attachment Found? | Will upload file in PROD | Will update Note in PROD | Attachment Uploaded? | Existing Attachment? | AMBIS note updated? | Note / Reason
```

In dry-run mode:

- `Will upload file in PROD` must be `Yes` only when a non-duplicate, uploadable invoice or invoice-equivalent source is available and would be uploaded after explicit production authorization. Use `No` when no attachable source exists, a matching AMBIS attachment for the same document or same transaction evidence already exists, the evidence is duplicate, the source is unavailable, or the item is review-only without order-specific approval.
- `Will update Note in PROD` must be `Yes` only when a non-duplicate invoice or invoice-equivalent note would be added after explicit production authorization and after the attachment outcome is known. Use `No` when no eligible note exists, a matching note already exists, evidence is missing, or the item is review-only without order-specific approval.
- `Attachment Uploaded?` must be `No`.
- `AMBIS note updated?` must be `No`.
- `Attachment Found?` should be `Yes` only when a vendor attachment, exported email PDF, or already-existing AMBIS invoice attachment is available.
- `Existing Attachment?` should be `Yes` only when a matching AMBIS invoice attachment already existed.
- `Existing Attachment?` may be `Yes` while `Will upload file in PROD` is also `Yes` when AMBIS already has an invoice or invoice-equivalent attachment but Outlook contains a materially different non-duplicate invoice document that should be added.
- `Note / Reason` must contain the exact single-line plain-text note that would be added or reviewed, or a short reason when no note would be added.
- State in the surrounding summary whether the attachment source was a vendor attachment, exported email PDF, already-existing AMBIS attachment, unavailable source, duplicate, or review-only.

In production mode:

- `Will upload file in PROD` and `Will update Note in PROD` should show the eligible production action intended for the row immediately before performing it. If the action later fails or is skipped after a duplicate recheck, explain the final outcome in `Attachment Uploaded?`, `AMBIS note updated?`, and `Note / Reason`.
- `Attachment Uploaded?` should be `Yes` only when the invoice document was uploaded and verified in AMBIS.
- `Existing Attachment?` should be `Yes` when a matching AMBIS invoice attachment already existed.
- `Existing Attachment?` may be `Yes` while `Attachment Uploaded?` is also `Yes` when a materially different new invoice was added in addition to the prior attachment.
- `AMBIS note updated?` should be `Yes` only when the note was added and verified in AMBIS.
- `Note / Reason` must state the final action taken or why no attachment or note was added.
