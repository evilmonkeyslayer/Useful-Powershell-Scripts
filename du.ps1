<#
.SYNOPSIS
    Reports disk usage for one or more directory trees, like the Linux `du` command.

.DESCRIPTION
    du.ps1 is a self-contained PowerShell equivalent to the Linux `du` (disk usage) utility.
    It walks directory trees with the built-in .NET types System.IO.DirectoryInfo and
    System.IO.FileInfo, sums file sizes using 64-bit integers, prints a cumulative size
    per directory (largest first), and prints a grand total.

    Nothing is loaded into memory beyond one record per directory (and, optionally,
    the N largest files), so large trees are scanned lazily with EnumerateFiles() and
    EnumerateDirectories() instead of materialising every file up front.

    Inaccessible files and directories are reported and skipped; the scan never stops
    early. Directory junctions and symbolic links are NOT followed by default, which
    prevents infinite recursion and double counting.

    Requires only Windows PowerShell 5.1 or PowerShell 7+. No modules, no WSL, no
    external executables.

    Invoked with no switches at all, the script prints a reference listing every
    switch and what it does, and exits. -Help prints the same reference. To measure
    the current directory, pass a path: .\du.ps1 .

    Every switch also has a one-letter form, and no two switches share a letter:
    -p Path, -d Depth (also -MaxDepth), -a All, -s Summary, -h HumanReadable,
    -r Sort, -u Ascending, -n ByName, -b Largest, -t Top, -x Exclude, -v Progress,
    -q NoProgress, -l FollowLinks, -m Stats, -i Help. So .\du.ps1 C:\Users -h is the same as -HumanReadable, and
    .\du.ps1 . -s -h -q is the same as -Summary -HumanReadable -NoProgress. Letters
    are matched case-insensitively, as everywhere in PowerShell: -h and -H are the
    same switch. Note that -h means human-readable (as in du), not help; help is -i.

.PARAMETER Path
    Short form: -p
    One or more directories to analyse. Accepts wildcard patterns.
    Defaults to the current directory when any other switch is given; a run with no
    switches at all prints the switch reference instead. A file path is accepted too
    and reported as a single entry (like `du somefile`).

.PARAMETER Depth
    Short form: -d, also spelled -MaxDepth (like `du --max-depth=N`)
    How many levels below each given path get a row of their own: 0 prints only the
    path itself, 1 prints the path plus its immediate children, and so on. The
    default (-1) prints every directory.
    This only trims which rows are printed. The whole tree is always measured, so a
    directory's size still includes everything below it however deep: with
    -Depth 1 the top row equals the Total, and each child row is that child plus
    its whole subtree. Same as `du --max-depth=1`.

.PARAMETER All
    Short form: -a
    Include hidden and system files. Without it, files carrying the Hidden or
    System attribute are skipped. Directories are always traversed either way.

.PARAMETER Summary
    Short form: -s
    Print only the total size of each given path (like `du -s`), plus the grand
    total. No per-directory rows, so it uses the least memory of any mode.
    -Top still works in this mode.

.PARAMETER HumanReadable
    Short form: -h
    Print sizes with B/KB/MB/GB/TB suffixes (1024-based, like `du -h`).
    Without it, sizes are printed as a byte count (like `du` without -h).

.PARAMETER Sort
    Short form: -r
    Sort directory rows by size. Size order is already the default; the switch is
    accepted so familiar `du`-style invocations work. Use -Ascending to reverse.

.PARAMETER Ascending
    Short form: -u
    Sort directory rows smallest first instead of largest first. With -ByName this
    reverses the alphabetical order to Z-A instead of A-Z.

.PARAMETER ByName
    Short form: -n, also spelled -SortByName (like `du --sort=name`)
    Order the directory rows alphabetically by their full path instead of by size.
    Comparison is case-insensitive, so folders sort together regardless of how they
    are capitalised. Sizes are still the full recursive totals; only the order of
    the rows changes. Combine with -Depth to keep a -Depth 1 listing alphabetical,
    with -Largest to take the N biggest directories and then print them A-Z, and
    with -Ascending to go Z-A.

.PARAMETER Largest
    Short form: -b
    Show only the N largest directories (implies descending size order).

.PARAMETER Progress
    Short form: -v
    Force the progress display on. Progress is on by default while walking trees.

.PARAMETER NoProgress
    Short form: -q
    Disable the progress display. Useful in scripts, CI jobs and log files.

.PARAMETER Top
    Short form: -t
    After the directory table, list the N largest files found in the tree(s).

.PARAMETER Exclude
    Short form: -x
    Wildcard patterns to skip. Matched against a directory or file name; a pattern
    containing \ or / is matched against the full path instead. Matching directories
    are skipped together with everything below them (like `du --exclude`).

.PARAMETER FollowLinks
    Short form: -l
    Follow directory junctions and symbolic links. Cycle protection is enabled when
    following, but linked trees are still counted twice if they are reachable by
    more than one path.

.PARAMETER Stats
    Short form: -m
    Print scan statistics (directories, files, skipped links, skipped hidden files,
    excluded entries, errors) after the table.

.PARAMETER Help
    Short form: -i
    Print the list of switches with a one-line description of each, then exit. A run
    with no parameters at all prints the same reference, so measuring the current
    directory needs an explicit path: .\du.ps1 .

.EXAMPLE
    .\du.ps1
    No parameters: prints the switch reference instead of scanning anything.

.EXAMPLE
    .\du.ps1 -Help
    Same reference, requested explicitly.

.EXAMPLE
    .\du.ps1 C:\Users -h
    One-letter form: identical to -Path C:\Users -HumanReadable.

.EXAMPLE
    .\du.ps1 . -s -h -m -q
    One-letter forms stacked: identical to -Path . -Summary -HumanReadable -Stats -NoProgress.

.EXAMPLE
    .\du.ps1 -Path C:\Users -HumanReadable
    Scan C:\Users and show sizes as KB/MB/GB.

.EXAMPLE
    .\du.ps1 -Path C:\Users -Depth 1
    Equivalent of `du --max-depth=1 C:\Users`: one row for C:\Users and one row per
    folder directly inside it, each holding the size of that folder and everything
    below it. The whole tree is still measured, so nothing is missed.

.EXAMPLE
    .\du.ps1 -Path C:\Users -Depth 2
    Rows for C:\Users plus two levels below it; deeper files are still counted.

.EXAMPLE
    .\du.ps1 -Path C:\Users -All
    Also count hidden and system files.

.EXAMPLE
    .\du.ps1 -Path C:\Users -Summary
    Print only the total size of C:\Users.

.EXAMPLE
    .\du.ps1 -Path C:\Users -Largest 10
    Print only the 10 largest directories.

.EXAMPLE
    .\du.ps1 -Path C:\Users -Top 20
    Print the directory table plus the 20 largest files.

.EXAMPLE
    .\du.ps1 -Path C:\Users -All -Ascending -Largest 15 -Stats
    Hidden and system files included, the 15 biggest directories listed smallest
    first, with scan statistics at the end.

.EXAMPLE
    .\du.ps1 -Path C:\Users -ByName
    Equivalent of `du --sort=name C:\Users`: rows in alphabetical order by path.

.EXAMPLE
    .\du.ps1 -Path C:\Users -Depth 1 -ByName
    Top-level folders only, listed A-Z.

.EXAMPLE
    .\du.ps1 -Path C:\Users,D:\Data -Exclude 'node_modules','*.tmp','*\AppData' -NoProgress
    Two trees at once, noisy folders and paths skipped, no progress display.

.EXAMPLE
    .\du.ps1 -Path 'C:\Users\*\Downloads' -Summary -HumanReadable
    Wildcard paths are expanded before scanning.

.EXAMPLE
    .\du.ps1 -Path C:\Links -FollowLinks -Stats
    Follow junctions/symlinks (cycle-protected) and report how much was skipped.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\du.ps1 -Path C:\Users
    Run the script from cmd or another shell without changing the policy globally.

.NOTES
    One-letter switch forms:
      -p Path          -d Depth          -a All           -s Summary
      -h HumanReadable -r Sort           -u Ascending     -n ByName
      -b Largest       -t Top            -x Exclude       -v Progress
      -q NoProgress    -l FollowLinks    -m Stats         -i Help
    Each letter belongs to exactly one switch; the script checks this at run time
    and refuses to start if two switches ever claim the same letter.
    Because CmdletBinding adds the PowerShell common parameters, -p, -d, -t, -v and
    -i are these switches rather than the usual prefixes of -PipelineVariable,
    -Debug, -Transcript, -Verbose and -InformationVariable; the full names of those
    common parameters still work.

    Known differences from Linux du:
      * Sizes are logical file sizes (FileInfo.Length), not 512/1024-byte block
        counts. Sparse regions and filesystem slack space are therefore not
        reflected, which is usually a large difference on NTFS.
      * du includes dotfiles by default; here hidden/system files need -All.
        Hidden and system directories are always traversed either way.
      * du prints symlink/junction entries with their tiny link size; this script
        skips them entirely (they are counted in -Stats) unless -FollowLinks.
      * du counts hard links once; Windows hard links are counted per name.
      * Human units are 1024-based and labelled KB/MB/GB/TB (du -h prints K/M/G).
      * Output is sorted by size, largest first, not in traversal order. Use
        -Ascending to reverse, or -ByName for alphabetical order by path (the
        equivalent of `du --sort=name`). There is no du equivalent for -Top.
      * -Depth (also spelled -MaxDepth) is the direct equivalent of
        `du --max-depth=N`: the entire tree is measured and every directory row
        includes all of its descendants, but only directories within N levels get
        printed. Nothing is left out of the totals; there is no option to stop the
        walk early.
      * -Summary is the closest thing to `du -s`; there is no `-a` (print every
        file) equivalent, -Top is the practical substitute.
      * Overlapping paths on one command line are summed independently, so a
        nested pair such as C:\Users and C:\Users\Public inflates the grand total
        (du behaves the same way).
      * Paths longer than MAX_PATH may fail under Windows PowerShell 5.1 unless
        long path support is enabled; such failures are reported, not fatal.
      * -FollowLinks de-duplicates by the real junction target on PowerShell 7+.
        Windows PowerShell 5.1 cannot resolve junction targets, so a link chain is
        bounded instead (repeated link names plus a hop limit), and a junction that
        points at an already measured directory can still be counted twice there.
      * Paths longer than the column width are abbreviated in the middle, for
        example C:\Users\markc\Downloads\Slow...5.10bit.HDR-MIXED[rartv].
      * Launched with `powershell -File`, comma-separated values for -Path and
        -Exclude arrive as a single string; the script splits them, so both
        `-Exclude a,b` and `-Exclude 'a','b'` work.
      * Run with ExecutionPolicy Bypass (or Unblock-File) if the file arrived
        from another machine and carries a zone marker.
#>
#Requires -Version 5.0

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [Alias('p')]
    [string[]] $Path,

    [Alias('d', 'MaxDepth')]
    [int] $Depth = -1,

    [Alias('a')]
    [switch] $All,

    [Alias('s')]
    [switch] $Summary,

    [Alias('h')]
    [switch] $HumanReadable,

    [Alias('r')]
    [switch] $Sort,

    [Alias('u')]
    [switch] $Ascending,

    [Alias('n', 'SortByName')]
    [switch] $ByName,

    [Alias('b')]
    [int] $Largest = 0,

    [Alias('v')]
    [switch] $Progress,

    [Alias('q')]
    [switch] $NoProgress,

    [Alias('t')]
    [int] $Top = 0,

    [Alias('x')]
    [string[]] $Exclude,

    [Alias('l')]
    [switch] $FollowLinks,

    [Alias('m')]
    [switch] $Stats,

    [Alias('i')]
    [switch] $Help
)

$ErrorActionPreference = 'Continue'

# Parameter metadata for this script, so the switch listing and the alias
# uniqueness check read the real parameters instead of a hand-written copy.
$script:Command = $MyInvocation.MyCommand

# ---------------------------------------------------------------------------
# Constants and small helpers
# ---------------------------------------------------------------------------

$ReparseFlag      = [System.IO.FileAttributes]::ReparsePoint
$HiddenFlag       = [System.IO.FileAttributes]::Hidden
$SystemFlag       = [System.IO.FileAttributes]::System
$DirWidthMax      = 78     # widest directory column before truncation
$ProgressInterval = 150    # ms between progress repaints
$MaxStoredErrors  = 100    # error details kept in memory; the count is exact
$MaxShownErrors   = 10     # error details printed at the end
$LinkHopLimit     = 8      # reparse hops allowed in a -FollowLinks chain

# .NET Core (PowerShell 7+) can name the real target of a junction or symlink.
# Windows PowerShell 5.1 cannot, so cycle detection there falls back to the hop
# limit above instead of exact target de-duplication.
$CanResolveLinks = $PSVersionTable.PSVersion.Major -ge 6

$Culture = [System.Globalization.CultureInfo]::InvariantCulture

function Get-DuLinkTargetPath {
    <#  Final target of a reparse-point directory, when the runtime can tell us. #>
    param($DirInfo)

    if (-not $CanResolveLinks) { return $null }
    try {
        $target = $DirInfo.ResolveLinkTarget($true)
        if ($target) { return $target.FullName }
    } catch { }
    return $null
}

function Format-DuSize {
    <#  Byte count -> display string. Human mode is 1024-based. #>
    param(
        [Int64] $Bytes,
        [bool] $Human
    )

    if (-not $Human) {
        return $Bytes.ToString('N0', $Culture)
    }

    $units = @('B', 'KB', 'MB', 'GB', 'TB', 'PB')
    $value = [double] $Bytes
    $index = 0
    while ($value -ge 1024 -and $index -lt ($units.Count - 1)) {
        $value = $value / 1024
        $index++
    }

    if ($index -eq 0) { return ('{0} B' -f $Bytes.ToString('N0', $Culture)) }
    if ($value -ge 100) { return ('{0:N0} {1}' -f $value, $units[$index]) }
    return ('{0:N1} {1}' -f $value, $units[$index])
}

function New-DuList {
    param([string] $Type = 'object')
    return New-Object ('System.Collections.Generic.List[' + $Type + ']')
}

function Split-DuList {
    <#  'powershell -File du.ps1 -Exclude a,b' arrives as one string; split it. #>
    param([string[]] $Values)

    $items = New-DuList 'string'
    foreach ($value in $Values) {
        if ([string]::IsNullOrWhiteSpace($value)) { continue }
        if ($value -match ',') {
            foreach ($part in ($value -split ',')) {
                if ($part.Trim().Length -gt 0) { $items.Add($part.Trim()) | Out-Null }
            }
        } else {
            $items.Add($value) | Out-Null
        }
    }
    return ,$items
}

function Get-DuMessage {
    <#  Unwrap PowerShell's method-invocation wrapper so messages read cleanly. #>
    param($ErrorRecord)

    if (-not $ErrorRecord) { return 'Unknown error.' }
    if ($ErrorRecord -is [string]) { return $ErrorRecord }

    $exception = $ErrorRecord.Exception
    while ($exception -and $exception.InnerException -and $exception.Message -like 'Exception calling*') {
        $exception = $exception.InnerException
    }
    if (-not $exception) { return [string] $ErrorRecord }
    return $exception.Message
}

function Add-DuError {
    param($Ctx, [string] $Where, $ErrorRecord, [string] $Prefix)

    # One report per path: a directory that cannot be listed fails both for its
    # files and for its subdirectories, and reporting it twice is noise.
    $key = $Where.ToLowerInvariant()
    if ($Ctx.ErrorPaths.Contains($key)) { return }
    $null = $Ctx.ErrorPaths.Add($key)

    $message = Get-DuMessage $ErrorRecord
    if ($Prefix) { $message = $Prefix + ': ' + $message }

    $Ctx.ErrorsCount++
    if ($Ctx.Errors.Count -lt $MaxStoredErrors) {
        $Ctx.Errors.Add([pscustomobject]@{ Path = $Where; Message = $message })
    }
}

function Test-DuExcluded {
    <#  Pattern match against the leaf name, or the full path for pathy patterns. #>
    param([string] $Name, [string] $FullPath, [string[]] $Patterns)

    if (-not $Patterns -or $Patterns.Count -eq 0) { return $false }

    foreach ($pattern in $Patterns) {
        if ([string]::IsNullOrWhiteSpace($pattern)) { continue }
        if ($pattern -match '[\\/]') {
            if ($FullPath -like $pattern) { return $true }
        }
        elseif ($Name -like $pattern) {
            return $true
        }
    }
    return $false
}

function Write-DuProgress {
    param($Ctx, [string] $Current)

    if (-not $Ctx.Progress) { return }

    $now = Get-Date
    $elapsed = (New-TimeSpan -Start $Ctx.LastProgress -End $now).TotalMilliseconds
    if ($elapsed -lt $ProgressInterval -and ($Ctx.Dirs % 500) -ne 0) { return }
    $Ctx.LastProgress = $now

    try {
        Write-Progress -Activity 'du: measuring disk usage' `
            -Status ('{0} directories, {1} files scanned' -f
                $Ctx.Dirs.ToString('N0', $Culture),
                $Ctx.Files.ToString('N0', $Culture)) `
            -CurrentOperation $Current
    } catch {
        # Odd hosts (some CI agents) reject Write-Progress; degrade quietly.
        $Ctx.Progress = $false
    }
}

function Complete-DuProgress {
    param($Ctx)
    if (-not $Ctx.Progress) { return }
    try { Write-Progress -Activity 'du: measuring disk usage - Completed' -Completed } catch { }
}

function Add-DuTopFile {
    <#  Keep a bounded, size-descending list of the N largest files. #>
    param($Ctx, [Int64] $Length, [string] $FullPath)

    if ($Ctx.Top -le 0) { return }

    $list = $Ctx.TopFiles
    if ($list.Count -ge $Ctx.Top) {
        if ($Length -le $list[$list.Count - 1].Bytes) { return }
        $list.RemoveAt($list.Count - 1)
    }

    $index = 0
    while ($index -lt $list.Count -and $list[$index].Bytes -ge $Length) { $index++ }
    $list.Insert($index, [pscustomobject]@{ Path = $FullPath; Bytes = $Length })
}

function Resolve-DuRoots {
    <#  Expand -Path (wildcards allowed) into existing absolute paths. #>
    param([string[]] $Requested)

    $roots = New-DuList 'string'

    foreach ($raw in $Requested) {
        if ([string]::IsNullOrWhiteSpace($raw)) { continue }

        # 'powershell -File du.ps1 -Path a,b' hands over "a,b" as one string, so
        # split comma-joined lists unless the whole string really is a path.
        $candidates = New-DuList 'string'
        if (($raw -match ',') -and (-not (Test-Path -LiteralPath $raw))) {
            foreach ($part in ($raw -split ',')) {
                if ($part.Trim().Length -gt 0) { $candidates.Add($part.Trim()) | Out-Null }
            }
        } else {
            $candidates.Add($raw) | Out-Null
        }

        foreach ($item in $candidates) {
            if ($item -match '[\*\?\[]') {
                $found2 = @(Resolve-Path -Path $item -ErrorAction SilentlyContinue)
                if ($found2.Count -eq 0) {
                    Write-Warning "du: '$item': No match found."
                    continue
                }
                foreach ($found in $found2) {
                    $target = $found.ProviderPath
                    if (-not $target) { $target = [string] $found.Path }
                    $roots.Add($target) | Out-Null
                }
                continue
            }

            if (-not (Test-Path -LiteralPath $item)) {
                Write-Warning "du: '$item': No such file or directory."
                continue
            }

            try {
                $itemInfo = Get-Item -LiteralPath $item -Force
                $roots.Add($itemInfo.FullName) | Out-Null
            } catch {
                Write-Warning "du: '$item': $($_.Exception.Message)"
            }
        }
    }

    return ,$roots
}

# ---------------------------------------------------------------------------
# Traversal
# ---------------------------------------------------------------------------

function Invoke-DuTree {
    <#
        Walks one root and returns @{ Records; Total; FileRoot }.
        Records hold one object per directory with Self (files directly inside),
        Total (cumulative) and a Parent reference. Totals are rolled up afterwards
        by processing deepest directories first.
    #>
    param([string] $Root, $Ctx)

    $records = New-DuList 'object'
    $rootTotal = [Int64] 0

    # A file passed as -Path behaves like `du somefile`.
    if ([System.IO.File]::Exists($Root)) {
        try {
            $file = New-Object System.IO.FileInfo($Root)
            $bytes = [Int64] $file.Length
            $Ctx.Files++
            Add-DuTopFile $Ctx $bytes $file.FullName
            $records.Add([pscustomobject]@{
                Path = $file.FullName; Depth = 0; Self = $bytes; Total = $bytes; Files = 1; Parent = $null
            })
            return @{ Records = $records; Total = $bytes; FileRoot = $true }
        } catch {
            Add-DuError $Ctx $Root $_
            return @{ Records = $records; Total = [Int64] 0; FileRoot = $true }
        }
    }

    $rootInfo = $null
    try {
        $rootInfo = New-Object System.IO.DirectoryInfo($Root)
        if (-not $rootInfo.Exists) {
            Add-DuError $Ctx $Root 'Cannot open directory: it does not exist or is not a directory.'
            return @{ Records = $records; Total = [Int64] 0; FileRoot = $false }
        }
    } catch {
        Add-DuError $Ctx $Root $_
        return @{ Records = $records; Total = [Int64] 0; FileRoot = $false }
    }

    $visited = New-Object 'System.Collections.Generic.HashSet[string]'
    $visited.Add($rootInfo.FullName.ToLowerInvariant()) | Out-Null

    $maxDepth = $Ctx.MaxDepth
    $stack = New-Object 'System.Collections.Generic.Stack[object]'
    $stack.Push([pscustomobject]@{ Dir = $rootInfo; Depth = 0; Owner = $null; Hops = 0; Links = @() })

    while ($stack.Count -gt 0) {
        $item = $stack.Pop()
        $dir = $item.Dir

        # The whole tree is measured regardless of -Depth, like `du --max-depth=N`:
        # directories deeper than the display limit get no row of their own, and
        # everything they contain rolls into the nearest shallower directory that
        # does get a row. Only the rows are trimmed, never the measurement.
        $keep = ($maxDepth -lt 0 -or $item.Depth -le $maxDepth)
        if ($keep) {
            $record = [pscustomobject]@{
                Path   = $dir.FullName
                Depth  = $item.Depth
                Self   = [Int64] 0
                Total  = [Int64] 0
                Files  = 0
                Parent = $item.Owner
            }
            if (-not $Ctx.Summary) { $records.Add($record) | Out-Null }
            $owner = $record
        } else {
            $record = $null
            $owner = $item.Owner
        }

        $Ctx.Dirs++
        Write-DuProgress $Ctx $dir.FullName

        # --- files directly inside this directory -------------------------
        try {
            foreach ($file in $dir.EnumerateFiles()) {
                try {
                    $attrs = $file.Attributes

                    if (($attrs -band $ReparseFlag) -and (-not $Ctx.FollowLinks)) {
                        # Symlink/hard-link-style entry: count 0, like du without -L.
                        $Ctx.LinkSkipped++
                        continue
                    }
                    if ((-not $Ctx.IncludeHidden) -and
                        (($attrs -band $HiddenFlag) -or ($attrs -band $SystemFlag))) {
                        $Ctx.HiddenSkipped++
                        continue
                    }
                    if (Test-DuExcluded $file.Name $file.FullName $Ctx.Exclude) {
                        $Ctx.Excluded++
                        continue
                    }

                    $length = [Int64] $file.Length
                    if ($keep) {
                        $record.Self += $length
                        $record.Files++
                    } else {
                        # No row for this directory, so credit its owning row.
                        $owner.Total += $length
                    }
                    $Ctx.Files++
                    if ($Ctx.Summary) { $rootTotal += $length }
                    Add-DuTopFile $Ctx $length $file.FullName
                } catch {
                    Add-DuError $Ctx $file.FullName $_
                }
            }
        } catch {
            Add-DuError $Ctx $dir.FullName $_ 'Cannot list files'
        }

        # --- child directories: always descended into ----------------------
        try {
            foreach ($child in $dir.EnumerateDirectories()) {
                try { $attrs = $child.Attributes } catch { $attrs = [System.IO.FileAttributes]::Normal }
                $isLink = ($attrs -band $ReparseFlag) -ne 0

                if ($isLink -and (-not $Ctx.FollowLinks)) {
                    $Ctx.LinkSkipped++
                    continue
                }

                $hops = $item.Hops
                if ($isLink) {
                    # Two guards against a link chain that folds back on itself:
                    # the same link name reappearing on this branch, and a hard
                    # limit on how many links a single branch may traverse.
                    if ($item.Links -contains $child.Name) {
                        $Ctx.CycleSkipped++
                        continue
                    }
                    if ($hops + 1 -gt $Ctx.LinkHopLimit) {
                        $Ctx.CycleSkipped++
                        continue
                    }
                    $hops = $hops + 1
                }

                # De-duplicate by the real target when the runtime can name it, so
                # a junction pointing back at an already measured directory is
                # counted once rather than re-walked under a longer path.
                $key = $child.FullName.ToLowerInvariant()
                if ($isLink) {
                    $target = Get-DuLinkTargetPath $child
                    if ($target) { $key = $target.ToLowerInvariant() }
                }
                if ($visited.Contains($key)) {
                    $Ctx.CycleSkipped++
                    continue
                }
                $visited.Add($key) | Out-Null

                if (Test-DuExcluded $child.Name $child.FullName $Ctx.Exclude) {
                    $Ctx.Excluded++
                    continue
                }

                $childLinks = $item.Links
                if ($isLink) { $childLinks = @($item.Links) + @($child.Name) }

                $stack.Push([pscustomobject]@{
                    Dir = $child; Depth = $item.Depth + 1; Owner = $owner
                    Hops = $hops; Links = $childLinks
                })
            }
        } catch {
            Add-DuError $Ctx $dir.FullName $_ 'Cannot list subdirectories'
        }
    }

    if ($Ctx.Summary) {
        return @{ Records = $records; Total = $rootTotal; FileRoot = $false }
    }

    # Children are always discovered after their parents, so deepest-first
    # ordering guarantees a directory's total is complete before it rolls up.
    $ordered = @($records | Sort-Object -Property Depth -Descending)
    foreach ($record in $ordered) {
        $record.Total = $record.Total + $record.Self
        if ($record.Parent) { $record.Parent.Total = $record.Parent.Total + $record.Total }
    }

    $total = [Int64] 0
    if ($records.Count -gt 0) { $total = $records[0].Total }

    return @{ Records = $records; Total = $total; FileRoot = $false }
}

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

function Get-Truncated {
    <#  Middle truncation: keeps the root prefix and the leaf name visible. #>
    param([string] $Text, [int] $Width)

    if ($Text.Length -le $Width) { return $Text }
    if ($Width -le 5) { return $Text.Substring(0, $Width) }

    $left = [int] (($Width - 3) / 2)
    $right = $Width - 3 - $left
    return $Text.Substring(0, $left) + '...' + $Text.Substring($Text.Length - $right)
}

function Write-DuTable {
    param([object[]] $Rows, $Ctx, [string] $Label)

    if (-not $Rows -or $Rows.Count -eq 0) {
        Write-Output ('{0}: no entries to display.' -f $Label)
        return
    }

    $dirWidth = 10
    $sizeWidth = 10
    foreach ($row in $Rows) {
        if ($row.Path.Length -gt $dirWidth) { $dirWidth = $row.Path.Length }
        $sizeText = Format-DuSize ([Int64] $row.Bytes) $Ctx.Human
        if ($sizeText.Length -gt $sizeWidth) { $sizeWidth = $sizeText.Length }
    }
    if ($dirWidth -gt $DirWidthMax) { $dirWidth = $DirWidthMax }

    $rule = '-' * ($dirWidth + $sizeWidth + 2)

    Write-Output $rule
    Write-Output ('{0}  {1}' -f 'Directory'.PadRight($dirWidth), 'Size'.PadLeft($sizeWidth))
    Write-Output $rule

    foreach ($row in $Rows) {
        $sizeText = Format-DuSize ([Int64] $row.Bytes) $Ctx.Human
        Write-Output ('{0}  {1}' -f
            (Get-Truncated $row.Path $dirWidth).PadRight($dirWidth),
            $sizeText.PadLeft($sizeWidth))
    }

    Write-Output $rule
    Write-Output ('{0}  {1}' -f
        'Total'.PadRight($dirWidth),
        (Format-DuSize ([Int64] $Ctx.GrandTotal) $Ctx.Human).PadLeft($sizeWidth))
    Write-Output $rule
}

function Write-DuTopFiles {
    param($Ctx)

    if ($Ctx.Top -le 0 -or $Ctx.TopFiles.Count -eq 0) { return }

    $sizeWidth = 10
    foreach ($file in $Ctx.TopFiles) {
        $sizeText = Format-DuSize ([Int64] $file.Bytes) $Ctx.Human
        if ($sizeText.Length -gt $sizeWidth) { $sizeWidth = $sizeText.Length }
    }

    $pathWidth = 40
    foreach ($file in $Ctx.TopFiles) {
        if ($file.Path.Length -gt $pathWidth) { $pathWidth = $file.Path.Length }
    }
    if ($pathWidth -gt $DirWidthMax) { $pathWidth = $DirWidthMax }

    $rule = '-' * ($pathWidth + $sizeWidth + 2)

    Write-Output ''
    Write-Output $rule
    Write-Output ('{0}  {1}' -f ('Largest files (top ' + $Ctx.TopFiles.Count + ')').PadRight($pathWidth),
        'Size'.PadLeft($sizeWidth))
    Write-Output $rule

    foreach ($file in $Ctx.TopFiles) {
        $sizeText = Format-DuSize ([Int64] $file.Bytes) $Ctx.Human
        Write-Output ('{0}  {1}' -f
            (Get-Truncated $file.Path $pathWidth).PadRight($pathWidth),
            $sizeText.PadLeft($sizeWidth))
    }

    Write-Output $rule
}

function Write-DuDiagnostics {
    param($Ctx)

    if ($Ctx.ErrorsCount -gt 0) {
        $header = 'du: {0} path(s) could not be read' -f $Ctx.ErrorsCount
        try { Write-Host $header -ForegroundColor Yellow } catch { Write-Output $header }

        $shown = 0
        foreach ($error in $Ctx.Errors) {
            if ($shown -ge $MaxShownErrors) { break }
            $shown++
            $line = '  skipped: {0} ({1})' -f $error.Path, $error.Message
            try { Write-Host $line -ForegroundColor DarkGray } catch { Write-Output $line }
        }
        if ($Ctx.ErrorsCount -gt $Ctx.Errors.Count) {
            $line = '  ({0} further errors not listed)' -f ($Ctx.ErrorsCount - $Ctx.Errors.Count)
            try { Write-Host $line -ForegroundColor DarkGray } catch { Write-Output $line }
        }
    }

    if (-not $Ctx.Stats) { return }

    Write-Output ''
    Write-Output ('Stats: {0} directories, {1} files, {2:N0} bytes counted, {3} skipped links, {4} repeats skipped, {5} hidden/system files skipped, {6} excluded entries, {7} errors' -f
        $Ctx.Dirs.ToString('N0', $Culture),
        $Ctx.Files.ToString('N0', $Culture),
        $Ctx.GrandTotal,
        $Ctx.LinkSkipped,
        $Ctx.CycleSkipped,
        $Ctx.HiddenSkipped,
        $Ctx.Excluded,
        $Ctx.ErrorsCount)
}

# ---------------------------------------------------------------------------
# Switch reference (shown by -Help and by a bare invocation)
# ---------------------------------------------------------------------------

function Write-DuLine {
    param([string] $Text, [string] $Color = 'Gray')

    try { Write-Host $Text -ForegroundColor $Color } catch { Write-Output $Text }
}

function Get-DuSwitchReference {
    <#
        Built from this script's own parameter metadata, so the listing can never
        drift from the real parameters, and the one-letter aliases are checked for
        duplicates here rather than by eye.
    #>
    $summaries = [ordered]@{
        Path          = @{ Label = '-Path <dirs>';     What = 'Directories to measure; accepts wildcards, several paths and file paths. Default: current directory.' }
        Depth         = @{ Label = '-Depth <N>';       What = 'du --max-depth=N, also spelled -MaxDepth: measure the whole tree, but print rows only for directories up to N levels deep. -1 (default) prints every directory.' }
        All           = @{ Label = '-All';             What = 'Include hidden and system files. Hidden directories are always traversed.' }
        Summary       = @{ Label = '-Summary';         What = 'Print one total per path instead of one row per directory (like du -s).' }
        HumanReadable = @{ Label = '-HumanReadable';   What = 'Show sizes as B, KB, MB, GB or TB (1024-based) instead of raw bytes.' }
        Sort          = @{ Label = '-Sort';            What = 'Order by size; that is already the default, so this is accepted for familiarity.' }
        Ascending     = @{ Label = '-Ascending';       What = 'Reverse the display order: smallest first, or Z-A when combined with -ByName.' }
        ByName        = @{ Label = '-ByName';          What = 'du --sort=name: order rows alphabetically by full path instead of by size. Case-insensitive.' }
        Largest       = @{ Label = '-Largest <N>';     What = 'Print only the N biggest directories.' }
        Top           = @{ Label = '-Top <N>';         What = 'Also list the N largest individual files after the table.' }
        Exclude       = @{ Label = '-Exclude <names>'; What = 'Skip matching names or paths; wildcards and comma-separated lists work.' }
        Progress      = @{ Label = '-Progress';        What = 'Show the live scan bar. This is the default.' }
        NoProgress    = @{ Label = '-NoProgress';      What = 'Suppress the live scan bar.' }
        FollowLinks   = @{ Label = '-FollowLinks';     What = 'Follow junctions and symbolic links, with cycle protection (off by default).' }
        Stats         = @{ Label = '-Stats';           What = 'Print scan statistics after the table.' }
        Help          = @{ Label = '-Help';            What = 'Print this reference and exit.' }
    }

    $parameters = $script:Command.Parameters
    $entries = New-DuList 'object'
    $letterOwner = New-DuList 'string'
    $letterUsed = New-DuList 'string'

    foreach ($name in $summaries.Keys) {
        $short = ''
        if ($parameters.ContainsKey($name)) {
            foreach ($alias in @($parameters[$name].Aliases)) {
                if ($alias.Length -ne 1) { continue }

                $letter = $alias.ToLowerInvariant()
                $index = $letterUsed.IndexOf($letter)
                if ($index -ge 0) {
                    throw ('du: the one-letter switch "-' + $alias + '" is claimed by both -' +
                        $letterOwner[$index] + ' and -' + $name + '; one-letter switches must be unique.')
                }
                $letterUsed.Add($letter) | Out-Null
                $letterOwner.Add($name) | Out-Null
                $short = '-' + $alias
            }
        }

        $entries.Add([pscustomobject]@{
            Name = $name
            Label = $summaries[$name].Label
            Short = $short
            What = $summaries[$name].What
        }) | Out-Null
    }

    return ,$entries
}

function Write-DuUsage {
    $switches = Get-DuSwitchReference

    $nameWidth = 'Switch'.Length
    $shortWidth = 'Short'.Length
    foreach ($entry in $switches) {
        if ($entry.Label.Length -gt $nameWidth) { $nameWidth = $entry.Label.Length }
        if ($entry.Short.Length -gt $shortWidth) { $shortWidth = $entry.Short.Length }
    }

    $textWidth = 66
    $rule = '-' * ($shortWidth + 2 + $nameWidth + 2 + $textWidth)

    Write-DuLine 'du.ps1 - disk usage of directories, like the Linux du command' 'Cyan'
    Write-DuLine ''
    Write-DuLine 'Usage: .\du.ps1 [[-Path] <dirs>] [-Depth|-MaxDepth N] [-All] [-Summary]'
    Write-DuLine '                [-HumanReadable] [-Sort] [-Ascending] [-ByName]'
    Write-DuLine '                [-Largest N] [-Top N] [-Exclude names]'
    Write-DuLine '                [-Progress | -NoProgress] [-FollowLinks] [-Stats] [-Help]'
    Write-DuLine ''
    Write-DuLine ('Short: ' + (($switches | ForEach-Object { $_.Short }) -join ' '))
    Write-DuLine '       each switch has its own letter; letters are not case sensitive'
    Write-DuLine ''
    Write-DuLine $rule
    Write-DuLine (('Short'.PadRight($shortWidth) + '  ' + 'Switch'.PadRight($nameWidth) + '  What it does')) 'DarkCyan'
    Write-DuLine $rule

    $indent = ' ' * ($shortWidth + 2 + $nameWidth + 2)
    foreach ($entry in $switches) {
        $text = $entry.What
        $isFirstLine = $true

        while ($text.Length -gt $textWidth) {
            # Wrap on a word boundary rather than chopping mid-word.
            $cut = $textWidth
            $space = $text.LastIndexOf(' ', $textWidth)
            if ($space -gt 0) { $cut = $space }

            $chunk = $text.Substring(0, $cut)
            if ($isFirstLine) {
                Write-DuLine (($entry.Short.PadRight($shortWidth) + '  ' + $entry.Label.PadRight($nameWidth) + '  ' + $chunk)) 'Gray'
                $isFirstLine = $false
            } else {
                Write-DuLine ($indent + $chunk) 'Gray'
            }
            $text = $text.Substring($cut).TrimStart()
        }

        if ($isFirstLine) {
            Write-DuLine (($entry.Short.PadRight($shortWidth) + '  ' + $entry.Label.PadRight($nameWidth) + '  ' + $text)) 'Gray'
        } else {
            Write-DuLine ($indent + $text) 'Gray'
        }
    }

    Write-DuLine $rule
    Write-DuLine ''
    Write-DuLine 'Examples' 'DarkCyan'
    Write-DuLine '  .\du.ps1 .                       measure the current directory'
    Write-DuLine '  .\du.ps1 C:\Users -h             C:\Users with K/M/G units (-h = -HumanReadable)'
    Write-DuLine '  .\du.ps1 C:\Users -d 1           like du --max-depth=1: totals complete,'
    Write-DuLine '                                   rows only for the top level of folders'
    Write-DuLine '  .\du.ps1 C:\Users -s             one total only'
    Write-DuLine '  .\du.ps1 C:\Users -b 10          the 10 biggest directories'
    Write-DuLine '  .\du.ps1 C:\Users -t 20          table plus the 20 biggest files'
    Write-DuLine '  .\du.ps1 C:\Users -a -m          hidden files included, plus statistics'
    Write-DuLine '  .\du.ps1 C:\Users -n             alphabetical order by path, like du --sort=name'
    Write-DuLine '  .\du.ps1 C:\Users -d 1 -n        top level of folders, listed A-Z'
    Write-DuLine '  .\du.ps1 . -s -h -m -q           short forms stack: -Summary -HumanReadable'
    Write-DuLine '                                   -Stats -NoProgress'
    Write-DuLine ''
    Write-DuLine 'Running .\du.ps1 with no parameters prints this reference. Pass a path, or' 'DarkGray'
    Write-DuLine '-Summary / -All and similar switches, to start a scan. For full help:' 'DarkGray'
    Write-DuLine '  Get-Help .\du.ps1 -Full' 'DarkGray'
    Write-DuLine 'Here -h means human-readable, as in du; the reference itself is -i or -Help.' 'DarkGray'
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

# A bare invocation lists the switches rather than silently measuring the current
# directory; -Help does the same thing explicitly.
if ($Help.IsPresent -or ($PSBoundParameters.Count -eq 0)) {
    Write-DuUsage
    return
}

if ($Depth -lt -1) {
    throw 'du: -Depth (alias -MaxDepth) must be -1 (unlimited) or a non-negative integer.'
}
if ($Largest -lt 0) { throw 'du: -Largest must be 0 (no limit) or a positive integer.' }
if ($Top -lt 0) { throw 'du: -Top must be 0 (none) or a positive integer.' }

if (-not $Path -or $Path.Count -eq 0) { $Path = @($PWD.Path) }

$ctx = @{
    Progress      = ($Progress.IsPresent -or (-not $NoProgress.IsPresent))
    Summary       = $Summary.IsPresent
    Human         = $HumanReadable.IsPresent
    IncludeHidden = $All.IsPresent
    FollowLinks   = $FollowLinks.IsPresent
    MaxDepth      = $Depth
    Exclude       = Split-DuList -Values $Exclude
    Top           = $Top
    Stats         = $Stats.IsPresent
    TopFiles      = New-DuList 'object'
    AllRecords    = New-DuList 'object'
    Errors        = New-DuList 'object'
    ErrorPaths    = New-Object 'System.Collections.Generic.HashSet[string]'
    ErrorsCount   = [Int64] 0
    Dirs          = [Int64] 0
    Files         = [Int64] 0
    LinkSkipped   = [Int64] 0
    CycleSkipped  = [Int64] 0
    LinkHopLimit  = $LinkHopLimit
    HiddenSkipped = [Int64] 0
    Excluded      = [Int64] 0
    GrandTotal    = [Int64] 0
    LastProgress  = Get-Date
}

$roots = Resolve-DuRoots $Path
if ($roots.Count -eq 0) {
    Write-Warning 'du: nothing to scan.'
    return
}

$rootTotals = New-DuList 'object'

try {
    foreach ($root in $roots) {
        $result = Invoke-DuTree -Root $root -Ctx $ctx
        $rootTotals.Add([pscustomobject]@{ Path = $root; Bytes = [Int64] $result.Total }) | Out-Null
        $ctx.GrandTotal += [Int64] $result.Total

        if ($ctx.Summary) {
            # Only totals matter in summary mode: drop the per-directory records.
            $result.Records.Clear()
        } else {
            foreach ($record in $result.Records) { $ctx.AllRecords.Add($record) | Out-Null }
        }
    }
} finally {
    Complete-DuProgress $ctx
}

# Build the directory rows.
$rows = New-DuList 'object'

if ($ctx.Summary) {
    foreach ($entry in $rootTotals) { $rows.Add($entry) | Out-Null }
} else {
    foreach ($record in $ctx.AllRecords) {
        $rows.Add([pscustomobject]@{ Path = $record.Path; Bytes = [Int64] $record.Total }) | Out-Null
    }
}

# Ordering: size by default (largest first), and -Ascending flips whatever order
# is in use. -ByName switches to alphabetical order, which starts at A.
# -Sort is accepted for command-line familiarity and has no effect of its own.
$reverse = $Ascending.IsPresent
$null = $Sort

if ($Largest -gt 0 -and $rows.Count -gt $Largest) {
    # -Largest always means the N biggest, whatever the display order is.
    $candidates = @($rows | Sort-Object -Property Bytes -Descending | Select-Object -First $Largest)
} else {
    $candidates = $rows
}

# Sorting strings with Sort-Object is case-insensitive, and PowerShell 5.1 has no
# -Ascending parameter for it, so the direction is chosen with -Descending.
if ($ByName.IsPresent) {
    $sorted = @($candidates | Sort-Object -Property Path -Descending:$reverse)
} elseif ($reverse) {
    $sorted = @($candidates | Sort-Object -Property Bytes)
} else {
    $sorted = @($candidates | Sort-Object -Property Bytes -Descending)
}

Write-DuTable -Rows $sorted -Ctx $ctx -Label 'du'
Write-DuTopFiles -Ctx $ctx
Write-DuDiagnostics -Ctx $ctx
