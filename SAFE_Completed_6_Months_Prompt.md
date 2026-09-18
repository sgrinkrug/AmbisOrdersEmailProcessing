# SAFE Completed 6 Months and In-Process Review Prompt

Initial conditions:
Use Chrome.

Before starting SAFE work, call the `ambis-keep-alive` skill once to refresh the most recently active already-open AMBIS tab. If the run lasts more than about 15 minutes, call `ambis-keep-alive` again about every 15 minutes during the run.

Ensure SAFE is open in Chrome at:
https://edrms.niaid.nih.gov/livelink/llisapi.dll/open/SAFEMI

If a SAFE tab is already open, open/navigate that tab to the URL above so the correct SAFE-MI landing page is loaded. If no SAFE tab is already open, open the URL above in Chrome.

AMBIS is already open in another tab.

Task:
Run the SAFE follow-up workflow in two separate passes unless the user explicitly scopes the run to only one order or only one pass.

Pass 1 stages orders from the AMBIS "Completed 6 months" saved search by setting SAFE folder status and missing document types.

Pass 2 reviews SAFE folders whose Folder Status is "In-Process" and sets only the folder-level reconciliation checkboxes based on existing Document Type values.

## Pass 1: Completed 6 Months Staging

For each order listed in the AMBIS "Completed 6 months" saved search, update SAFE so the order is correctly staged for follow-up.

Processing algorithm:
1. Inventory pass:
   - Read the visible "Completed 6 months" saved search list once.
   - Capture each order's SEQ #, SAFE folder link/id, current folder status, document names, and current Document Type values.
   - Do not open document files during the inventory pass.
2. Skip/status pass:
   - If the folder status is already "In Process" or "In-Process", do not update the status.
   - If the folder status is "New", set the folder status to "In Process" / "In-Process".
   - If the folder status is "Approved" or SAFE does not expose visible update controls, do not force hidden actions; skip the folder and include the reason in the final summary.
3. Document skip pass:
   - If a document already has a non-empty Document Type other than "None", leave it as-is and move on.
   - Only process documents whose Document Type is empty or "None".
4. Fast classification pass:
   - Determine the correct Document Type using the document name first.
   - Use these common name-based mappings when they are reasonably clear:
     - `*_OrderInfo.html` -> `AMBIS Order Summary`
     - names containing `quote` or vendor quote numbers -> `Quotes`
     - names containing `invoice` or `receipt` -> `Invoice`
     - names containing `packing` or `packing slip` -> `Packing Slip`
     - names containing `receiving` -> `RECEIVING`
     - names or files that clearly indicate an order confirmation/order number -> `Order Confirmation`
     - names containing `justification` -> `Justification`
5. Exception/content pass:
   - Open/read document content only when the document name is not enough to determine the type with reasonable confidence.
   - Use AMBIS only as supporting reference when SAFE document name/content is insufficient.
   - Do not guess silently. If a document type cannot be determined with reasonable confidence, leave it unchanged and include it in the final exceptions list.
6. Save pass:
   - Apply all needed Document Type updates for the current folder.
   - Avoid re-saving documents whose Document Type was already set.
   - Reload/refresh once after all updates for the folder are applied.
7. Validation pass:
   - Validate only folders changed during this run and folders listed as skipped/exceptions.
   - Confirm changed folders are "In Process" / "In-Process".
   - Confirm each changed document has the expected non-empty Document Type unless listed as an exception.
8. Repeat until every order in the "Completed 6 months" saved search has been processed, skipped, or listed as an exception.

Pass 1 validation:
1. Use targeted validation, not a full re-audit of already-complete documents.
2. Before moving to the next changed order, confirm the SAFE folder status is "In Process" / "In-Process".
3. Confirm changed documents have non-empty, appropriate Document Type values unless listed as exceptions.
4. Confirm skipped folders/documents are included in the final summary with the reason they were skipped.

## Pass 2: In-Process Checkbox Review

Open SAFE at:
https://edrms.niaid.nih.gov/livelink/llisapi.dll/open/SAFEMI

Go to the Folder Status controls and filter/review every order whose Folder Status is set to "In-Process" / "In Process".

For each In-Process order:
1. Open the order.
2. Review the full attachments/file list.
3. Look specifically at the value in the "Document Type" field for each attachment.
4. Set the folder-level checkboxes based only on the Document Type values.

Checkbox rules:
- Missing Invoice:
  - Check this box if there is no attachment with Document Type "Invoice".
  - Uncheck it if at least one attachment has Document Type "Invoice".
- Missing Receiving:
  - Check this box if there is no attachment with a Document Type indicating receiving documentation.
  - Treat "Receiving", "RECEIVING", "Receiving Confirmation", "Packing Slip", or equivalent receiving/proof-of-delivery document types as receiving documentation.
  - Uncheck it if receiving documentation is present.
- Disputed Charge:
  - Check this box if any attachment has a Document Type indicating a disputed charge, charge dispute, or dispute support.
  - Uncheck it if no dispute-related Document Type is present.
- Credit Pending:
  - Check this box if any attachment has a Document Type indicating credit pending, credit memo pending, refund pending, or similar credit-related status.
  - Uncheck it if no credit-pending Document Type is present.

After setting checkbox values for an In-Process order:
1. Click "Save Changes".
2. Verify the changes were saved to the folder.
3. Click "Close Window".
4. Return to the In-Process order list and continue with the next order.

Pass 2 boundaries:
- Do not change folder status.
- Do not send any order for review.
- Do not edit attachments.
- Do not edit Document Type values.
- Do not infer checkbox values from attachment filenames unless the Document Type field is blank or clearly unavailable.
- If a Document Type is ambiguous, leave the affected checkbox unchanged and note the ambiguity in the log.

Pass 2 log:
Keep a concise log of every In-Process order reviewed, including:
- Order identifier
- Document Type values found
- Checkbox values set
- Whether "Save Changes" was clicked
- Whether the window was closed
- Any ambiguity or order skipped

Final response:
Provide a concise processing summary with:
1. Total orders reviewed.
2. Total orders updated.
3. Orders skipped, if any, with reason.
4. Documents whose type could not be confidently determined.
5. Number of documents skipped because Document Type was already set.
6. In-Process checkbox review log, including checkbox values set and any ambiguity.
7. Any errors or system issues encountered.

Test-run option:
To run only one order as a test, add:

```text
Run as a test for order [AMBIS order number] only.
```

To run only one pass, add:

```text
Run Pass 1 only.
```

or:

```text
Run Pass 2 only.
```
