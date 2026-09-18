[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [Alias('Name')]
    [ValidateNotNullOrEmpty()]
    [string]$SkillName,

    [switch]$DryRun,

    [ValidateNotNullOrEmpty()]
    [string]$InstalledSkillsPath = (Join-Path -Path $env:USERPROFILE -ChildPath '.codex\skills')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ProjectSkillsPath = Join-Path -Path $ProjectRoot -ChildPath 'skills'

function Get-FullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::GetFullPath($Path)
}

function Get-RelativeChildPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $rootFull = (Get-FullPath -Path $Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $pathFull = Get-FullPath -Path $Path

    if ($pathFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return ''
    }

    $prefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    if (-not $pathFull.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path '$Path' is not under root '$Root'."
    }

    return $pathFull.Substring($prefix.Length)
}

function Assert-SafeSkillName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($Name -match '[\\/]' -or $Name -eq '.' -or $Name -eq '..' -or $Name -match '^\s*$') {
        throw "SkillName must be a skill directory name, not a path: '$Name'."
    }
}

function Test-FileContentMatch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        return $false
    }

    $sourceItem = Get-Item -LiteralPath $Source
    $destinationItem = Get-Item -LiteralPath $Destination

    if ($sourceItem.Length -ne $destinationItem.Length) {
        return $false
    }

    $sourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
    $destinationHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash

    return $sourceHash -eq $destinationHash
}

function Get-ProjectSkillDirectories {
    if (-not (Test-Path -LiteralPath $ProjectSkillsPath -PathType Container)) {
        throw "Project skills directory does not exist: $ProjectSkillsPath"
    }

    if ($SkillName) {
        Assert-SafeSkillName -Name $SkillName
        $skillPath = Join-Path -Path $ProjectSkillsPath -ChildPath $SkillName

        if (-not (Test-Path -LiteralPath $skillPath -PathType Container)) {
            throw "Requested project skill '$SkillName' does not exist at: $skillPath"
        }

        return @(Get-Item -LiteralPath $skillPath)
    }

    return @(Get-ChildItem -LiteralPath $ProjectSkillsPath -Directory | Sort-Object -Property Name)
}

function Sync-ProjectSkill {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$SourceDirectory
    )

    $skillManifest = Join-Path -Path $SourceDirectory.FullName -ChildPath 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillManifest -PathType Leaf)) {
        throw "Project skill '$($SourceDirectory.Name)' is missing SKILL.md at: $skillManifest"
    }

    $destinationDirectory = Join-Path -Path $InstalledSkillsPath -ChildPath $SourceDirectory.Name
    $actions = New-Object System.Collections.Generic.List[object]

    Write-Host "Skill: $($SourceDirectory.Name)"
    Write-Host "Source: $($SourceDirectory.FullName)"
    Write-Host "Destination: $destinationDirectory"

    if (-not (Test-Path -LiteralPath $InstalledSkillsPath -PathType Container)) {
        $actions.Add([pscustomobject]@{ Action = 'CreateDirectory'; Path = $InstalledSkillsPath })
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $InstalledSkillsPath | Out-Null
        }
    }

    if (-not (Test-Path -LiteralPath $destinationDirectory -PathType Container)) {
        $actions.Add([pscustomobject]@{ Action = 'CreateDirectory'; Path = $destinationDirectory })
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null
        }
    }

    $sourceDirectories = @(Get-ChildItem -LiteralPath $SourceDirectory.FullName -Directory -Recurse -Force | Sort-Object -Property FullName)
    foreach ($sourceChildDirectory in $sourceDirectories) {
        $relativePath = Get-RelativeChildPath -Root $SourceDirectory.FullName -Path $sourceChildDirectory.FullName
        $targetDirectory = Join-Path -Path $destinationDirectory -ChildPath $relativePath

        if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
            $actions.Add([pscustomobject]@{ Action = 'CreateDirectory'; Path = $targetDirectory })
            if (-not $DryRun) {
                New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null
            }
        }
    }

    $sourceFiles = @(Get-ChildItem -LiteralPath $SourceDirectory.FullName -File -Recurse -Force | Sort-Object -Property FullName)
    foreach ($sourceFile in $sourceFiles) {
        $relativePath = Get-RelativeChildPath -Root $SourceDirectory.FullName -Path $sourceFile.FullName
        $targetFile = Join-Path -Path $destinationDirectory -ChildPath $relativePath
        $targetParent = Split-Path -Parent $targetFile

        if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
            $actions.Add([pscustomobject]@{ Action = 'CreateDirectory'; Path = $targetParent })
            if (-not $DryRun) {
                New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
            }
        }

        if (Test-FileContentMatch -Source $sourceFile.FullName -Destination $targetFile) {
            $actions.Add([pscustomobject]@{ Action = 'Unchanged'; Path = $targetFile })
            continue
        }

        $copyAction = if (Test-Path -LiteralPath $targetFile -PathType Leaf) { 'UpdateFile' } else { 'CreateFile' }
        $actions.Add([pscustomobject]@{ Action = $copyAction; Path = $targetFile })

        if (-not $DryRun) {
            Copy-Item -LiteralPath $sourceFile.FullName -Destination $targetFile -Force
        }
    }

    if (Test-Path -LiteralPath $destinationDirectory -PathType Container) {
        $destinationItems = @(Get-ChildItem -LiteralPath $destinationDirectory -Recurse -Force | Sort-Object -Property FullName -Descending)
        foreach ($destinationItem in $destinationItems) {
            $relativePath = Get-RelativeChildPath -Root $destinationDirectory -Path $destinationItem.FullName
            $sourceEquivalent = Join-Path -Path $SourceDirectory.FullName -ChildPath $relativePath

            if (Test-Path -LiteralPath $sourceEquivalent) {
                continue
            }

            $actions.Add([pscustomobject]@{ Action = 'RemoveStale'; Path = $destinationItem.FullName })

            if (-not $DryRun) {
                Remove-Item -LiteralPath $destinationItem.FullName -Recurse -Force
            }
        }
    }

    $changeActions = @($actions | Where-Object { $_.Action -ne 'Unchanged' })
    if ($changeActions.Count -eq 0) {
        $label = if ($DryRun) { 'Plan' } else { 'Changes' }
        Write-Host "${label}: no changes"
    }
    else {
        $label = if ($DryRun) { 'Plan' } else { 'Changes' }
        Write-Host "${label}:"
        foreach ($action in $changeActions) {
            Write-Host "  $($action.Action): $($action.Path)"
        }
    }

    $created = @($actions | Where-Object { $_.Action -in @('CreateDirectory', 'CreateFile') }).Count
    $updated = @($actions | Where-Object { $_.Action -eq 'UpdateFile' }).Count
    $removed = @($actions | Where-Object { $_.Action -eq 'RemoveStale' }).Count
    $unchanged = @($actions | Where-Object { $_.Action -eq 'Unchanged' }).Count
    $mode = if ($DryRun) { 'dry run' } else { 'synchronized' }

    Write-Host "Result: $mode; created=$created; updated=$updated; removed=$removed; unchanged=$unchanged"
    Write-Host ''
}

$skillDirectories = @(Get-ProjectSkillDirectories)

if ($skillDirectories.Count -eq 0) {
    Write-Host "No project skills found in: $ProjectSkillsPath"
    exit 0
}

foreach ($skillDirectory in $skillDirectories) {
    Sync-ProjectSkill -SourceDirectory $skillDirectory
}
