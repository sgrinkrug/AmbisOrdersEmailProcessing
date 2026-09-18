---
name: ambis-find-attachment-on-disk
description: Locate and validate a local attachment for AMBIS, then select it through a browser file-chooser API without opening or using the Windows Open dialog. Use whenever an AMBIS workflow needs to choose a local file for upload.
---

# AmbisFindAttachmentOnDisk

## Scope

Use this skill only to locate, validate, and select a local file in an AMBIS upload control. It does not authorize an upload and must not click `ADD TO REQUEST`. The calling AMBIS skill remains responsible for authorization, duplicate checks, submitting the upload, and verifying the resulting AMBIS record.

Required input from the calling skill:

- The expected filename or absolute file path
- The AMBIS sequence number and document purpose
- The current AMBIS browser tab, positioned before file selection

Return the resolved absolute path, selected filename, and one of these outcomes: `selected`, `not found`, `ambiguous`, `validation failed`, or `selection blocked - direct browser file chooser unavailable`.

## Never Use The Native File Dialog

- Never use, open, or interact with the Windows `Open` file dialog.
- Never click `Choose Files` through coordinate-based computer control, accessibility clicks, or ordinary browser clicks unless a supported browser `filechooser` event is already armed to intercept that click.
- Never type or paste a path into a native file dialog.
- Never try to set the value of an `input[type=file]`; browsers prohibit that operation.
- Never ask the user to select the file manually as the normal fallback.
- If the current browser-control surface cannot wait for a file chooser and call `setFiles`, do not click `Choose Files`. Switch to a browser-control surface attached to the same authenticated browser session that supports the direct file-chooser API. If none is available, return `selection blocked - direct browser file chooser unavailable` and leave AMBIS unchanged.

## Locate And Validate

1. If the caller supplies an absolute path, resolve it and verify that it identifies a regular file.
2. Otherwise, search for the exact expected filename in the caller's working directory and known task-specific `tmp`, `output`, and download locations. Prefer `rg --files`; on Windows, a targeted `Get-ChildItem -LiteralPath ... -Filter ... -File` search is acceptable.
3. Do not use a broad recursive search of the entire user profile when targeted locations are sufficient.
4. Require exactly one valid match. If multiple matches remain, return `ambiguous` with their paths instead of guessing.
5. Verify the filename, extension, nonzero size, and expected document type. When the caller already rendered or validated a generated PDF, preserve that exact file rather than regenerating it.
6. Return `not found` or `validation failed` without opening the AMBIS file-selection control when these checks fail.

## Select Through The Browser

1. Open the AMBIS `UPLOAD FILES` modal if it is not already open, but stop before activating `Choose Files`.
2. Use a browser automation surface that exposes both:
   - `tab.playwright.waitForEvent("filechooser")`
   - `PlaywrightFileChooser.setFiles(...)`
3. Build a unique locator for the visible `Choose Files` button from a fresh DOM snapshot and confirm that it resolves to exactly one element.
4. Arm the chooser event before clicking the button, then assign the validated absolute path directly:

```javascript
const chooserPromise = tab.playwright.waitForEvent("filechooser", { timeoutMs: 10000 });
await chooseFilesButton.click();
const chooser = await chooserPromise;
await chooser.setFiles(absolutePath, { timeoutMs: 10000 });
```

5. After selection, take a fresh DOM snapshot and verify that the expected filename is displayed in the AMBIS modal and that `ADD TO REQUEST` is enabled.
6. Return `selected` with the resolved absolute path and displayed filename. Do not click `ADD TO REQUEST`.

For a multi-file AMBIS upload, validate every path first and pass the complete array to `setFiles` only when the chooser reports that multiple selection is supported. Otherwise select and upload files one at a time through the calling skill.

## Failure Handling

- If no `filechooser` event arrives, the chooser cannot call `setFiles`, the selected filename is not displayed, or `ADD TO REQUEST` remains disabled, close or cancel only the AMBIS upload modal when safe and report the specific failure.
- Do not retry by opening the native file dialog.
- Do not continue to upload, add a note, or claim that the attachment was selected.
