---
name: ambis-update-tracking-info
description: Retrieve shipment confirmations and tracking information for AMBIS Pending Receiving purchase requests from Outlook and vendor order pages, then dry-run or update AMBIS with shipment-confirmation email PDF attachments and single-line AI-generated tracking notes. Use when Codex needs to process AMBIS tracking or shipment confirmation evidence, handle multiple or partial shipments, detect duplicate tracking or shipment attachments, warn on item mismatches, or produce a tracking update summary for AMBIS orders.
---

# AMBIS Update Tracking Info

## Overview

Use this skill to work through AMBIS Pending Receiving orders, find shipment or tracking confirmations in Outlook and vendor order pages, attach the shipment-confirmation source email as a PDF where possible, and either show a dry-run summary or add shipment attachments and notes to AMBIS after the user explicitly approves updates.

Default to dry-run mode unless the user clearly asks to update AMBIS. In dry-run mode, do not upload attachments or edit AMBIS; display the proposed attachment filename, whether the attachment would be uploaded, the proposed note, and whether each order would be updated.

## Hard Rules

- Work one AMBIS order at a time and output `Working on Seq # <sequence number> ...` before beginning each order.
- Ask the user to log in when AMBIS, Outlook, Microsoft, CAC/PIV, or vendor pages require authentication.
- Do not mark items received.
- Do not change order status.
- Do not read or change AMBIS tags.
- Do not send emails.
- Treat the workflow as attachment-first, note-second: when updates are authorized, handle shipment-confirmation email PDF attachments before adding AMBIS notes.
- Only upload AMBIS attachments or add AMBIS notes when the user explicitly authorizes updates.
- Do not upload duplicate shipment-confirmation attachments.
- Before any AMBIS note update, check existing notes and do not duplicate tracking numbers or shipment confirmations already present.
- If a match is uncertain, show the evidence and ask the user before treating it as updateable.
- If the user asks to display messages or notes first, show the proposed note text and wait for approval before updating.

## AMBIS Workflow

1. Open AMBIS at `https://ambis.niaid.nih.gov` and wait for the user to log in if needed.
2. Open the saved search named `Pending Receiving`.
3. For each listed order, open the order summary and collect:
   - Sequence number
   - Vendor name
   - Order total
   - Item details
   - Vendor order numbers
   - Purchase/order IDs
   - Quote numbers
   - Existing notes
   - Existing active attachments and attachment history where visible
4. Use existing AMBIS notes to detect already-recorded tracking numbers or shipment confirmations before proposing new notes.
5. Use existing AMBIS attachments to detect already-uploaded shipment-confirmation evidence before proposing an upload.
6. When direct navigation is helpful, AMBIS order summaries commonly use `https://ambis.niaid.nih.gov/order/<sequence>/summary`.

## Outlook Search

Search Outlook read-only. Include the Inbox, the Card confirmations folder, and any order-specific folders, especially under `Inbox\Aquisitions\Pcard\PCard Assignments` when present.

Search using combinations of:

- AMBIS sequence number
- Vendor name
- Vendor order number
- Purchase/order ID
- Quote number
- Item names and descriptions
- Catalog numbers
- Tracking-related words such as `tracking`, `shipped`, `shipment`, `delivery`, `delivered`, `order status`, `UPS`, `FedEx`, and `USPS`

Prefer strong shipment, delivery, or order-status evidence over generic vendor mentions. Record the source email sender, date, subject, folder, and message identity as evidence for every proposed shipment attachment or note, but do not include that source detail in the AMBIS note unless the user requests it.

## Vendor Pages

If an email contains a vendor order-status or tracking link and the carrier tracking number is not visible in the email, open the vendor page read-only. Ask the user to log in if needed.

If the vendor page confirms shipment but does not reveal a carrier tracking number, still record the shipment confirmation. Use the source shipment/order-status email as the default attachment source, and state in the summary or evidence display that the carrier tracking number was not visible, but keep the AMBIS note concise.

## Shipment Extraction

Extract all unique shipment or tracking information:

- Sequence number
- Vendor name
- Order total
- Carrier, if known
- Tracking number, if visible
- Vendor order number, if known
- Ship date, if known
- Delivery date, if known
- Item or quantity shipped, if known
- Whether the evidence appears to cover all AMBIS items
- Source email subject, date, sender, folder, and message identity
- Planned shipment-confirmation attachment filename and source

Treat each unique tracking number as a separate shipment row. If one order has multiple shipments, display multiple rows. Partial shipments are a normal case; do not treat partial coverage as an error when the source clearly identifies the shipped items, quantities, vendor order, shipment, or tracking number.

Do not combine AMBIS notes when one order has multiple shipment notifications, delivery notices, shipment confirmations, or tracking numbers. Each shipment notification and/or unique tracking number gets its own proposed note and, when approved, its own AMBIS note.

Use tracking-number normalization when checking duplicates. For example:

- UPS tracking usually starts with `1Z` followed by 16 alphanumeric characters.
- FedEx numbers are often 12 or more digits and may be spaced in emails.
- Normalize spaced numeric tracking numbers before comparison.
- Do not confuse AMBIS sequence numbers, purchase IDs, vendor order IDs, or quote numbers with carrier tracking numbers.

If the shipment email item description does not match the AMBIS item description, still include the tracking number or shipment confirmation, but add an item mismatch warning in the proposed AMBIS note.

## Attachable Evidence And Duplicate Checks

For each accepted shipment or tracking match, convert or export the source shipment-confirmation email to PDF where technically possible and use that PDF as the AMBIS attachment source. This includes vendor shipment emails, delivery emails, order-status emails that contain a tracking link, and emails that lead to a vendor page where shipment is confirmed.

If the email cannot be exported to PDF, mark the attachment source as unavailable or review-only in the summary. Do not invent a PDF from remembered details. If a vendor-provided shipment, delivery, or packing document is attached to the source email and is more complete than the email body, it may be uploaded in addition to the exported email PDF after duplicate checks, but the shipment-confirmation email PDF remains the default evidence file.

Whenever this workflow needs to choose a local shipment-confirmation file in AMBIS, invoke `$ambis-find-attachment-on-disk` with the expected filename or absolute path, sequence number, document purpose, and current AMBIS tab. Use the helper to locate, validate, and select the file through the browser file-chooser API. Never use the Windows Open dialog or duplicate the helper's file-selection procedure here. The helper does not authorize or submit the upload; this skill remains responsible for authorization, duplicate checks, choosing the attachment type, clicking `ADD TO REQUEST`, verifying the resulting attachment, and cleanup.

Before marking a shipment-confirmation attachment uploadable:

- Recheck the AMBIS attachments area.
- Treat an existing AMBIS attachment as the same shipment-confirmation evidence only when it matches the same source email, vendor order number, tracking number, shipment date, shipment notification, filename, or other strong shipment identity.
- A shipment-confirmation attachment for a different tracking number, different shipment date, different vendor order number, different partial shipment, replacement, exchange, or return is not a duplicate and may be added as a separate attachment.
- If an existing shipment-confirmation attachment probably matches but the evidence is not certain, mark the attachment review-only and ask the user before upload.
- Existing AMBIS notes control whether a new note can be added; existing AMBIS attachments control whether a shipment-confirmation PDF can be uploaded.
- If the same tracking note already exists but no matching shipment-confirmation attachment exists, the attachment may still be uploadable after explicit authorization, but do not add a duplicate note.
- If a matching shipment-confirmation attachment already exists but the tracking note is missing, the note may still be addable after explicit authorization.

In dry-run mode, identify the source and planned filename but do not upload files, save persistent evidence files solely for upload, or alter AMBIS.

## File Naming

Rename every uploaded shipment-confirmation email PDF so the filename clearly identifies it as shipment evidence. Use filesystem-safe ASCII filenames only.

Use this convention for exported shipment-confirmation emails:

```text
AMBIS_<SequenceNumber>_ShipmentConfirmation_<VendorName>_<OrderOrTrackingOrEmailShipment>_<SourceDate>.pdf
```

Examples:

```text
AMBIS_2301010_ShipmentConfirmation_BHPhoto_Order919203658_TrackingD10017648742228_2026-08-24.pdf
AMBIS_2298895_ShipmentConfirmation_DellTechnologies_Order1036547846_2026-08-13.pdf
AMBIS_123456_ShipmentConfirmation_FisherScientific_EmailShipment_2026-08-19.pdf
```

Filename rules:

- Use filesystem-safe ASCII only.
- Remove special characters, slashes, quotes, and extra spaces.
- Collapse repeated spaces and separators.
- Use `YYYY-MM-DD` for the source email date.
- Use `Order<vendor order number>` when a vendor order number is visible.
- Use `Tracking<tracking number>` when a carrier tracking number is visible.
- If both order number and tracking number are visible, include both in the reference component, such as `Order919203658_TrackingD10017648742228`.
- Use `EmailShipment` when no order number or tracking number is visible.
- If multiple shipment-confirmation PDFs would otherwise have the same filename, append `_01`, `_02`, etc. before the extension.
- Partial shipments, multiple tracking numbers, replacements, exchanges, and returns should each receive their own filename and attachment when supported by distinct source evidence.

## Note Format

AMBIS notes must be plain text only. AMBIS trims extra spaces and line breaks, so each note must be readable as one single line. Trim extra spaces and avoid unnecessary source-email detail in the AMBIS note itself; keep source email sender/date/subject in the final summary or evidence display when useful.

Every AI-generated note must end with:

```text
This note was generated by AI
```

For a shipment confirmation with visible carrier tracking, use:

```text
Shipment/tracking confirmation: <vendor order number if known> - <item/qty shipped, or "shipped with all items" if all AMBIS items appear to have shipped> - shipped <date if known>. Tracking # <tracking number>. | This note was generated by AI
```

If no carrier tracking number is visible, omit the tracking sentence:

```text
Shipment/tracking confirmation: <vendor order number if known> - <item/qty shipped, or "shipped with all items" if all AMBIS items appear to have shipped> - shipped <date if known>. | This note was generated by AI
```

If all AMBIS items appear to have shipped, prefer a concise all-items note:

```text
Shipment/tracking confirmation: <vendor order number if known> shipped with all items <date if known>. Tracking # <tracking number if visible>. | This note was generated by AI
```

If there is an item mismatch, add a concise warning before the AI statement:

```text
Shipment/tracking confirmation: <vendor order number if known> - <item/qty shipped> - shipped <date if known>. Tracking # <tracking number if visible>. Warning: email item says <email item description>; AMBIS item says <AMBIS item description>. Verify before receiving. | This note was generated by AI
```

Keep note wording concise. Do not add `Source:` sections, email subjects, or "Carrier tracking number was not visible" to the AMBIS note unless the user specifically asks for that detail in the note.

## Updating AMBIS

Only update AMBIS when the user explicitly authorizes updates. For each authorized shipment or tracking row:

1. Reopen or refresh the AMBIS order summary.
2. Recheck existing notes for duplicate tracking numbers or shipment confirmations.
3. Recheck existing attachments for duplicate shipment-confirmation PDFs.
4. If the attachment is uploadable, export or convert the source shipment-confirmation email to PDF with the required filename.
5. Open the AMBIS attachments area and invoke `$ambis-find-attachment-on-disk` to locate, validate, and select the saved file. If the helper does not return `selected`, do not submit the upload.
6. After a successful selection, choose the shipment, shipping, order-status, or general attachment type/category where AMBIS supports one, click `ADD TO REQUEST`, and verify the attachment appears in AMBIS.
7. Add only new, non-duplicate notes.
8. Verify that each note appears in AMBIS after adding it.
9. Do not make any other AMBIS changes.

Use the AMBIS note controls available on the order summary page. A common path is to open `Notes`, choose `NEW NOTE`, enter the note in the note text area, and click `ADD NOTE`.

Delete temporary local files created solely for upload after verifying AMBIS accepted the attachment, unless keeping them is necessary for troubleshooting or the user asks to keep them.

## Final Summary

At the end, display a summary table with these columns:

```text
Sequence # | Vendor | Order total | Tracking number | Carrier | Ship date | Item/qty | Attachment name | Will upload file in PROD | Attachment uploaded? | Existing attachment? | AMBIS note updated? | Will update Note in PROD | Note to Add
```

In dry-run mode:

- `Attachment name` must show the planned shipment-confirmation PDF filename, an existing matching attachment filename, or a short reason when no attachment source is available.
- `Will upload file in PROD` must be `Yes` only when a non-duplicate, uploadable shipment-confirmation email PDF is available and would be uploaded after explicit production authorization. Use `No` when no attachable source exists, a matching AMBIS attachment already exists, the evidence is duplicate, the source is unavailable, or the item is review-only without order-specific approval.
- `Attachment uploaded?` must be `No`.
- `Existing attachment?` should be `Yes` only when a matching AMBIS shipment-confirmation attachment already exists.
- `AMBIS note updated?` must be `No`.
- `Will update Note in PROD` should be `Yes` only when a new, non-duplicate, sufficiently supported note would be added after approval.
- `Will update Note in PROD` should be `No` for duplicates, uncertain matches, or orders without new shipment information.
- `Note to Add` must contain the exact single-line plain-text note that would be added, or a short reason when no note would be added.
- State whether the attachment source was an exported email PDF, vendor attachment, already-existing AMBIS attachment, unavailable source, duplicate, or review-only.

In update mode:

- `Will upload file in PROD` and `Will update Note in PROD` should show the eligible production action intended for the row immediately before performing it. If the action later fails or is skipped after a duplicate recheck, explain the final outcome in `Attachment uploaded?`, `AMBIS note updated?`, and `Note to Add`.
- `Attachment uploaded?` should be `Yes` only when the shipment-confirmation PDF was uploaded and verified in AMBIS.
- `Existing attachment?` should be `Yes` when a matching AMBIS shipment-confirmation attachment already existed.
- `AMBIS note updated?` should be `Yes` only when the note was added and verified in AMBIS.
- `Note to Add` must state the final note added or why no attachment or note was added.
