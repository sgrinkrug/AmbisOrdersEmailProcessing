---
name: ambis-citi-transactions
description: Find CitiManager commercial-card transaction notification emails for eligible AMBIS purchase-card orders, then dry-run or explicitly add concise non-duplicate bank-transaction notes to AMBIS.
---

# AMBIS Citi Transactions

## Overview

Use this skill to review eligible AMBIS purchase-card orders, search recent Outlook email read-only for CitiManager transaction notifications, extract the posted bank transaction details, and add a single-line AMBIS note after explicit authorization.

This is a note-only workflow. Do not save, print, export, generate, attach, or upload Citi notification PDFs or any other Citi transaction files. Do not inspect or modify AMBIS attachments unless the user separately asks for an attachment workflow.

This skill has no attachment flow. If the user separately requests an AMBIS attachment action, use `$ambis-find-attachment-on-disk` to locate, validate, and select each local file. That shared skill does not authorize or submit an upload; the calling attachment workflow remains responsible for authorization, duplicate checks, clicking `ADD TO REQUEST`, and verifying the resulting AMBIS record.

Default to dry-run mode unless the user clearly asks to update AMBIS. In dry-run mode, do not add AMBIS notes; display the extracted transaction details, proposed note text, duplicate-note status, and whether each order would be updated.

## Hard Rules

- Process only AMBIS orders where current AMBIS Status is `Pending receiving` or `Buyer as PA`.
- Process only AMBIS orders where Payment Type is `Purchase Card (non-OA)`.
- Ignore all other orders.
- Work one AMBIS order at a time and output `Working on Seq # <sequence number> ...` before beginning each order.
- Ask the user to log in when AMBIS, Outlook, Microsoft, or CAC/PIV pages require authentication.
- Search Outlook read-only for the last 30 days only.
- Do not save, print, export, generate, attach, or upload Citi transaction PDFs or files.
- Do not mark items received.
- Do not change order status.
- Do not read or change AMBIS tags.
- Do not send emails.
- Only add AMBIS notes when the user explicitly authorizes an update.
- Never add a duplicate Citi bank-transaction note.
- If a transaction match or duplicate-note check is uncertain, show the evidence and ask the user before treating the note as addable.

## AMBIS Session Keepalive

During long executions, keep the AMBIS session alive without changing AMBIS data. If this skill has been running for 15 minutes or more since the last active AMBIS interaction or keepalive, and the current work is not actively operating the AMBIS screen, invoke `$ambis-keep-alive` once before continuing.

Use this keepalive while doing non-AMBIS work such as Outlook searches, evidence review, or final summary preparation. Do not interrupt an in-progress AMBIS note add, form submission, or verification step; finish the current AMBIS action first, then refresh the 15-minute timer from that AMBIS interaction.

`$ambis-keep-alive` may only refresh an already-open AMBIS tab in Chrome. It does not authorize notes, status changes, tag reads or changes, receiving actions, emails, uploads, or any other AMBIS data mutation.

## AMBIS Workflow

1. Open AMBIS at `https://ambis.niaid.nih.gov` and wait for the user to log in if needed.
2. Use the current AMBIS worklist, saved search, or relevant order list the user has requested.
3. For each listed order, open the order summary and collect:
   - Sequence number
   - Vendor name
   - Order total
   - Existing notes
   - Current AMBIS status
   - Payment type
4. Skip orders whose current status is not `Pending receiving` or `Buyer as PA`.
5. Skip orders whose payment type is not `Purchase Card (non-OA)`.
6. Check existing AMBIS notes before searching Outlook. If a matching Citi bank-transaction note already exists, skip the order and do not add another note.
7. Existing order-confirmation, shipping-confirmation, tracking, invoice, receiving, packing-slip, or general vendor notes do not block adding a Citi transaction note unless they clearly record the same bank transaction amount, transaction date, and Citi merchant/vendor.
8. When direct navigation is helpful, AMBIS order summaries commonly use `https://ambis.niaid.nih.gov/order/<sequence>/summary`.

## Outlook Search

Search Outlook read-only for Citi transaction notification emails from the last 30 days only. Search only these exact Outlook folders:

- `\\SGrinkrug@niaid.nih.gov\Inbox`
- `\\SGrinkrug@niaid.nih.gov\Inbox\Aquisitions\Pcard\Card confirmations`
- `\\SGrinkrug@niaid.nih.gov\Inbox\Aquisitions\Pcard\Citibank`

Do not search any subfolders of these folders, including order-specific folders under `Inbox\Aquisitions\Pcard\PCard Assignments`, unless the user explicitly changes this folder scope.

Before searching Outlook for an eligible order, check AMBIS notes first. If AMBIS already has a clear matching Citi transaction note, skip the Outlook search unless the user specifically requested note review or note repair.

Search for messages with these Citi-specific characteristics:

- Sender display/name: `CitiManager - Citi Commercial Cards`
- Sender address: `citicommercialcards.admin@citi.com`
- Subject: `Notification of transaction` or `[EXTERNAL] Notification of transaction`
- Body fields similar to `DATE: <MM/DD/YYYY>`, `ACCOUNT ENDING`, and `A transaction for your account ... was made in the amount of <amount> USD at <merchant>.`

Search using combinations of:

- AMBIS sequence number
- AMBIS vendor name
- Order total as an exact amount
- Citi sender address `citicommercialcards.admin@citi.com`
- Subject phrase `Notification of transaction`
- Merchant/vendor variants from AMBIS notes, order confirmation evidence, or the AMBIS vendor name
- Date terms when the order date, placed date, or expected card transaction date is known

Match Citi notifications by amount first, then vendor/merchant text, then date proximity. A strong match normally has the exact AMBIS order total, a recognizable merchant/vendor relationship, and a transaction date consistent with the AMBIS order timeline. Vendor text can differ from the AMBIS vendor name, such as `SP FORMLABS` for Formlabs, but the relationship must be clear.

If multiple Citi notifications could match the same order, or the amount matches but the vendor relationship is weak, mark the item review-only and ask the user before treating it as addable.

Record the source email sender email address, email sent date, subject, Citi transaction date, transaction amount, and Citi merchant/vendor text for every proposed note. Do not create or save a PDF copy of the email.

## Transaction Detail Extraction

Extract these fields from the matching Citi notification:

- Transaction date: prefer the `DATE: MM/DD/YYYY` line in the email body. If the body date is unavailable, use the email sent date and mark that fallback in the dry-run or final summary.
- Amount: parse the numeric USD amount from the sentence `was made in the amount of <amount> USD`.
- Vendor or merchant: parse the text after `at` in the transaction sentence, stopping before the sentence-ending period.
- Account ending: record if visible for matching/review only, but do not include the account ending in the AMBIS note.

Normalize extracted fields this way:

- Keep the AMBIS note date as `MM/DD/YYYY`.
- Format the note amount as `$<amount>` with two decimal places when cents are present. Do not add commas unless they were already needed for readability in a displayed summary.
- Preserve the Citi merchant/vendor text in uppercase when the email uses uppercase.
- Use ordinary ASCII spaces only and collapse repeated spaces.

## Duplicate Note Checks

Before marking a note addable, and again immediately before adding it to AMBIS:

- Recheck existing AMBIS notes.
- If the same Citi bank transaction is already recorded, do not add a new note.
- Treat a note as duplicate when it clearly has the same transaction amount, transaction date, and Citi merchant/vendor text.
- Treat an exact existing copy of the proposed note as a duplicate even if spacing or nonbreaking spaces differ.
- Treat minor punctuation, capitalization, or comma differences as duplicate when the same amount, date, and merchant are present.
- If an existing note probably refers to the same Citi transaction but the evidence is not certain, mark the note review-only and ask the user before adding anything.
- If no strong Citi transaction notification is found, do not generate a note.
- If any required note field is missing or uncertain, mark the note review-only and ask the user before adding anything.

## Note Format

AMBIS notes must be plain text only, concise, and readable as one single line. Do not include the source email sender, email sent date, email subject, account ending, item list, order number, or any attachment/file name in the AMBIS note itself; keep source details in the dry-run or final summary for review.

Use this exact format:

```text
Bank transaction for the amount <amount> was posted on <transaction date> for the vendor <Citi merchant/vendor>. This note was generated by AI.
```

Example:

```text
Bank transaction for the amount $3558.66 was posted on 08/03/2026 for the vendor SP FORMLABS. This note was generated by AI.
```

Normalize note whitespace before adding or displaying a note: use ordinary ASCII spaces only, collapse repeated spaces, and include the final period after `AI.`

In dry-run mode, proposed notes may describe the note that would be added after an authorized update completes. The final summary must still make clear that no note was added during the dry run.

## Updating AMBIS

Only update AMBIS when the user explicitly authorizes updates. For each authorized order:

1. Reopen or refresh the AMBIS order summary or notes tab.
2. Confirm the order is still Status `Pending receiving` or `Buyer as PA`.
3. Confirm the Payment Type is still `Purchase Card (non-OA)`.
4. Recheck existing notes for duplicate Citi bank-transaction notes.
5. If the order is review-only, stop before adding a note unless the user gave order-specific approval.
6. Open Notes.
7. Click New Note.
8. Paste the exact addable single-line note.
9. Click Add Note.
10. Verify the note appears in AMBIS.
11. Do not make any other changes.

Do not open AMBIS attachment upload controls, file pickers, or local PDF/export workflows as part of this skill. Any separately authorized attachment workflow must delegate local file selection to `$ambis-find-attachment-on-disk`.

## Final Summary

At the end, display a summary table with these columns:

```text
Sequence # | Vendor | Citi Merchant | Amount | Transaction Date | Transaction Found? | Will update Note in PROD | AMBIS note updated? | Note / Reason
```

In dry-run mode:

- `Will update Note in PROD` must be `Yes` only when a non-duplicate Citi bank-transaction note would be added after explicit production authorization.
- Use `No` when no eligible note exists, a matching note already exists, evidence is missing, or the item is review-only without order-specific approval.
- `AMBIS note updated?` must be `No`.
- `Note / Reason` must contain the exact single-line plain-text note that would be added or reviewed, or a short reason when no note would be added.
- State that no AMBIS note was added during the dry run.

In update mode:

- `Will update Note in PROD` should show the eligible production note action intended immediately before performing it. If the action later fails or is skipped after a duplicate recheck, explain the final outcome in `AMBIS note updated?` and `Note / Reason`.
- `AMBIS note updated?` should be `Yes` only when the note was added and verified in AMBIS.
- `Note / Reason` must state the exact note added or why no note was added.
