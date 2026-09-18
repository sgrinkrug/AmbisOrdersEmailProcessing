---
name: ambis-keep-alive
description: Refresh the most recently active already-open AMBIS tab in Chrome once to keep the AMBIS session alive.
---

# AMBIS Keep Alive

Use when an AMBIS workflow needs a one-time session keepalive refresh.

This skill performs one refresh only. The calling AMBIS workflow owns any schedule, such as calling this skill about every 15 minutes during long-running work.

This skill has no attachment flow. If the calling workflow separately needs to choose a local file for an AMBIS upload, it must invoke `$ambis-find-attachment-on-disk`; attachment selection and upload are outside this keepalive refresh.

## Required Behavior

1. Use Chrome only. Do not use the built-in Codex in-app browser for this skill.
2. Find already-open Chrome tabs whose title or URL indicates AMBIS, including `AMBIS`, `AMBIS5`, or `ambis.niaid.nih.gov`.
3. If exactly one AMBIS tab is found, use it.
4. If multiple AMBIS tabs are found, choose the most recently active or opened tab. Prefer a tab with the newest `lastOpened` value; if the browser API already returns user tabs in recency order and timestamps are unavailable or tied, use the first matching AMBIS tab from that list.
5. Refresh the selected AMBIS tab once.
6. Return a concise success or failure result.

## Boundaries

- Do not ask the user which AMBIS tab to use.
- Do not open a new AMBIS tab.
- Do not use browser history to discover AMBIS pages.
- Do not submit forms, click workflow buttons, upload files, edit requests, save changes, or otherwise change AMBIS data.
- Do not open attachment controls or select local files. Any separately authorized AMBIS attachment workflow must delegate local file selection to `$ambis-find-attachment-on-disk`.
- Do not capture or report timer values during normal production keepalive runs.

## Result Format

Report success with the refreshed tab title or URL when available.

Report failure if no already-open Chrome AMBIS tab is found, Chrome is unavailable, the AMBIS tab cannot be claimed, or the refresh fails.
