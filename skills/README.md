# AMBIS Codex Skills

This project stores the authoritative copies of AMBIS Codex skills.

- Authoritative project skills: `C:\Users\sgrinkrug\OneDrive - National Institutes of Health\Projects\AMBIS_Codex\skills`
- Installed Codex skills: `C:\Users\sgrinkrug\.codex\skills`

The normal synchronization direction is project to `.codex`: edit and validate the project copy first, then sync it to the installed Codex skills directory. Do not copy from `.codex` back into this project unless an import is explicitly requested.

## Sync All Skills

From the project root:

```powershell
.\scripts\Sync-CodexSkills.ps1
```

## Sync One Skill

From the project root:

```powershell
.\scripts\Sync-CodexSkills.ps1 -SkillName ambis-update-receiving
```

`SkillName` may also be supplied as the first positional argument:

```powershell
.\scripts\Sync-CodexSkills.ps1 ambis-update-receiving
```

## Dry Run

Preview all skill synchronization changes without writing anything:

```powershell
.\scripts\Sync-CodexSkills.ps1 -DryRun
```

Preview one skill:

```powershell
.\scripts\Sync-CodexSkills.ps1 -SkillName ambis-update-receiving -DryRun
```
