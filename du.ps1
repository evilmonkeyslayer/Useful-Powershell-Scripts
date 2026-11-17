<#
.SYNOPSIS
    Reports disk usage for one or more directory trees, like the Linux `du` command.

.DESCRIPTION
    du.ps1 is a self-contained PowerShell similar to the Linux `du` (disk usage)
    utility. It walks directory trees with the built-in .NET types System.IO.DirectoryInfo
    and System.IO.FileInfo, sums file sizes using 64-bit integers, prints a cumulative
    size per directory (largest first), and prints a grand total.

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
    -q NoProgress, -l FollowLinks, -m Stats, -i Help. So .\du.ps1 C:\Users -h is the
    same as -HumanReadable, and .\du.ps1 . -s -h -q is the same as -Summary
    -HumanReadable -NoProgress. Letters are matched case-insensitively, as everywhere
    in PowerShell: -h and -H are the same switch. Note that -h means human-readable
    (as in du), not help; help is -i.

.PARAMETER Path
    Short form: -p
    One or more directories to analyse. Accepts wildcard patterns.
    Defaults to the current directory when any other switch is given; a run with no
    switches at all prints the switch reference instead. A file path is accepted too
    and reported as a single entry (like `du somefile`).
    Paths are checked literally first, so names containing [ ] ? * (for example
    C:\Torrents\[group] or C:\Data\data[1]) are read as real names, not globs.
    Relative paths such as . .. and .\sub are measured from the directory shown in
    the prompt, which is also where a run with no -Path starts.

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
    Thousands separators are always the invariant-culture comma, whatever the
    machine's regional settings are.

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
    Cannot be combined with -NoProgress.

.PARAMETER NoProgress
    Short form: -q
    Disable the progress display. Useful in scripts, CI jobs and log files.
    Cannot be combined with -Progress.

.PARAMETER Top
    Short form: -t
    After the directory table, list the N largest files found in the tree(s).

.PARAMETER Exclude
    Short form: -x
    Wildcard patterns to skip. Matched against a directory or file name; a pattern
    containing \ or / is matched against the full path instead. Matching directories
    are skipped together with everything below them (like `du --exclude`).
    Each pattern is tried both as a glob (du-compatible) and as a plain name, so a
    folder whose real name contains [ or ? is matched by writing that name exactly.

.PARAMETER FollowLinks
    Short form: -l
    Follow directory junctions and symbolic links. Cycle protection is enabled when
    following, but linked trees are still counted twice if they are reachable by
    more than one path.

.PARAMETER Stats
    Short form: -m
    Print scan statistics (elapsed time, directories, files, skipped links, skipped
    hidden files, excluded entries, errors) after the table.

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
    .\du.ps1 -Path 'C:\Torrents\[group]Rartv' -h
    A literal folder name containing brackets is read as a name, not as a glob.

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
    Each letter belongs to exactly one switch; the script checks this at start-up,
    before any scanning, and refuses to start if two switches ever claim the same
    letter. The reference listing is built from the same check, so it can never
    drift from the real parameters.
    Because CmdletBinding adds the PowerShell common parameters, -p, -d, -t, -v and
    -i are these switches rather than the usual prefixes of -PipelineVariable,
    -Debug, -Transcript, -Verbose and -InformationVariable; the full names of those
    common parameters still work, and -Verbose reports which paths were scanned and
    why a path was dropped.

    Known differences from Linux du:
      * Relative paths (. .. .\sub) are resolved from PowerShell's current
        location, the directory in the prompt - not from the process working
        directory, which some hosts leave at C:\Windows\System32.
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
      * -Exclude never removes a path named explicitly on the command line; it
        only prunes entries found while walking. du skips an excluded root.
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
      * Launched with `powershell -File`, comma-separated values for -Path arrive
        as a single string; the script splits them, so both `-Path a,b` and
        `-Path 'a','b'` work. -Exclude is split on commas too, but never inside a
        pattern containing \ or / so a path pattern may hold a comma.
      * Unreadable paths are reported as warnings (not coloured console text), so
        they land on the warning stream and can be redirected or silenced with
        -WarningAction SilentlyContinue.
      * Exit code is 1 when any path could not be read, and 0 otherwise, which
        makes the script usable as a CI check. A dot-sourced run leaves the caller
        session alone and reports the code in $duExitCode instead.
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

# This script's own command info, so the switch reference, the alias check and the
# banner read real metadata instead of a hand-written copy, and stay correct if the
# file is renamed.
$script:Command    = $MyInvocation.MyCommand
$script:ScriptName = if ($script:Command) { $script:Command.Name } else { 'du.ps1' }
# '.' means dot-sourced: an exit there would close the caller's session, so the
# exit code is only recorded in that case.
$script:DotSourced = $MyInvocation.InvocationName -eq '.'

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
$NoLinks          = @()    # shared empty link trail, so plain frames do not allocate

# .NET Core (PowerShell 7+) can name the real target of a junction or symlink.
# Windows PowerShell 5.1 cannot, so cycle detection there falls back to the hop
# limit above instead of exact target de-duplication.
$CanResolveLinks = $PSVersionTable.PSVersion.Major -ge 6

$Culture = [System.Globalization.CultureInfo]::InvariantCulture

function New-DuObjectList {
    # The leading comma stops PowerShell unrolling the empty list into nothing
    # when the function's output is assigned to a variable.
    return ,[System.Collections.Generic.List[object]]::new()
}

function New-DuStringList {
    return ,[System.Collections.Generic.List[string]]::new()
}

function New-DuHashSet {
    <#  Case-insensitive set without lowercasing every key by hand. #>
    return ,[System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase)
}

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
    if ($value -ge 100) { return ($value.ToString('N0', $Culture) + ' ' + $units[$index]) }
    return ($value.ToString('N1', $Culture) + ' ' + $units[$index])
}

function Split-DuList {
    <#
        'powershell -File du.ps1 -Exclude a,b' arrives as one string; split it.
        Patterns holding \ or / are left intact, so a path pattern may contain a
        comma ('*\Program Files (x86),Data') without being chopped in half.
    #>
    param([string[]] $Values)

    $items = New-DuStringList
    foreach ($value in @($Values)) {
        if ([string]::IsNullOrWhiteSpace($value)) { continue }
        if (($value -match ',') -and ($value -notmatch '[\\/]')) {
            foreach ($part in ($value -split ',')) {
                if ($part.Trim().Length -gt 0) { $items.Add($part.Trim()) }
            }
        } else {
            $items.Add($value)
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

    if ([string]::IsNullOrWhiteSpace($Where)) { $Where = '(unknown path)' }

    # One report per path: a directory that cannot be listed fails both for its
    # files and for its subdirectories, and reporting it twice is noise. The set is
    # case-insensitive, so two spellings of one path are not two reports.
    $key = $Where
    if ($Ctx.ErrorPaths.Contains($key)) { return }
    # HashSet.Add returns a Boolean: swallow it, or it leaks into the output of
    # whichever function is reporting the error.
    $null = $Ctx.ErrorPaths.Add($key)

    $message = Get-DuMessage $ErrorRecord
    if ($Prefix) { $message = $Prefix + ': ' + $message }

    $Ctx.ErrorsCount++
    if ($Ctx.Errors.Count -lt $MaxStoredErrors) {
        $Ctx.Errors.Add([pscustomobject]@{ Path = $Where; Message = $message })
    }
}

function ConvertTo-DuPatterns {
    <#
        Compile -Exclude once instead of re-classifying every pattern for every
        entry: name patterns are matched against the leaf, pathy patterns (those
        holding \ or /) against the full path.
    #>
    param([string[]] $Raw)

    $names = New-DuStringList
    $paths = New-DuStringList

    foreach ($pattern in (Split-DuList -Values $Raw)) {
        if ($pattern -match '[\\/]') { $paths.Add($pattern) } else { $names.Add($pattern) }
    }

    return @{
        Names   = $names
        Paths   = $paths
        HasPath = ($paths.Count -gt 0)
        Any     = (($names.Count + $paths.Count) -gt 0)
    }
}

function Test-DuExcluded {
    <#
        Match a compiled -Exclude set. Each pattern is tried as a glob (du's
        --exclude semantics) and as a plain name, so a folder whose real name
        contains [ or ? is still matched when written exactly.
    #>
    param($Patterns, [string] $Name, [string] $FullPath)

    if (-not $Patterns.Any) { return $false }

    foreach ($pattern in $Patterns.Names) {
        if ($Name -like $pattern -or $Name -eq $pattern) { return $true }
    }

    if ($Patterns.HasPath) {
        foreach ($pattern in $Patterns.Paths) {
            if ($FullPath -like $pattern -or $FullPath -eq $pattern) { return $true }
        }
    }

    return $false
}

function Write-DuProgress {
    param($Ctx, [string] $Current)

    if (-not $Ctx.Progress) { return }

    # A stopwatch rather than Get-Date/New-TimeSpan: no DateTime allocation per
    # directory in a loop that runs over hundreds of thousands of them.
    if ($Ctx.Clock.ElapsedMilliseconds -lt $Ctx.NextProgress) { return }
    $Ctx.NextProgress = $Ctx.Clock.ElapsedMilliseconds + $ProgressInterval

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

function Set-DuExitCode {
    <#
        Report the exit code the way du does: 0 on success, 1 when something could
        not be read. Recording it as well makes it visible to a dot-sourced run,
        which must not exit and close its own session.
    #>
    param([int] $Code)

    $script:duExitCode = $Code
    if ($script:DotSourced) { return }
    exit $Code
}

function Stop-DuScript {
    <#
        End the run: 1 when any path could not be read, 0 otherwise. A plain run
        also exits 0 on success so a stale $LASTEXITCODE from an earlier command is
        not mistaken for a failed scan.
    #>
    param($Ctx)
    Complete-DuProgress $Ctx

    if ($Ctx.ErrorsCount -gt 0) { Set-DuExitCode 1 } else { Set-DuExitCode 0 }
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

function Get-DuBasePath {
    <#
        The directory relative paths are measured from: PowerShell's own current
        location, which is what the user sees in the prompt.
    #>
    $location = Get-Location -PSProvider FileSystem -ErrorAction SilentlyContinue
    if ($location -and $location.Path) { return $location.Path }
    if ($PWD.Path) { return $PWD.Path }
    return [System.IO.Directory]::GetCurrentDirectory()
}

function Get-DuLiteralPath {
    <#
        Resolve one -Path entry without wildcard interpretation.

        Resolve-Path -LiteralPath does two things du needs: [ ] ? * are taken as
        literal characters, so a folder named data[1] is found instead of being read
        as a character class, and a relative path is anchored on PowerShell's own
        current location - the directory shown in the prompt. Letting .NET resolve
        '.' and '..' would use the *process* working directory instead, which hosts
        such as the ISE leave at C:\Windows\System32, so 'du.ps1 .' would measure
        System32 rather than the current folder.

        Returns $null when the path does not exist.
    #>
    param([string] $Item)

    $found = @(Resolve-Path -LiteralPath $Item -ErrorAction SilentlyContinue)
    if ($found.Count -eq 0) { return $null }

    $target = $found[0].ProviderPath
    if (-not $target) { $target = [string] $found[0].Path }

    # Drop a trailing \ from C:\dir\ so the printed path looks like a directory
    # name; a bare root such as C:\ keeps its separator.
    if ($target.Length -gt 3 -and $target.EndsWith('\') -and -not $target.EndsWith(':\')) {
        $target = $target.TrimEnd('\')
    }
    return $target
}

function Test-DuPathExists {
    <#  True when the entry names something real, wildcards not read as patterns. #>
    param([string] $Item)
    return [bool] (Get-DuLiteralPath $Item)
}

function Add-DuRoot {
    <#  Add a resolved path to the root list unless it is already there. #>
    param($Roots, [string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    if (-not $Roots.Contains($Path)) { $Roots.Add($Path) }
}

function Resolve-DuRoots {
    <#
        Expand -Path into existing absolute paths, literal names checked first.
        A -Path that cannot be resolved is reported like du reports a bad operand
        and, when $Ctx is given, counted as an error so the exit code becomes 1.
    #>
    param([string[]] $Requested, $Ctx)

    function Add-DuRootFailure([string] $Path, [string] $Message) {
        Write-Warning ('du: ''' + $Path + ''': ' + $Message)
        if (-not $Ctx) { return }
        $Ctx.ErrorsCount++
        if ($Ctx.Errors.Count -lt $MaxStoredErrors) {
            $Ctx.Errors.Add([pscustomobject]@{ Path = $Path; Message = $Message })
        }
    }

    $roots = New-DuStringList

    foreach ($raw in @($Requested)) {
        if ([string]::IsNullOrWhiteSpace($raw)) { continue }

        # 'powershell -File du.ps1 -Path a,b' hands over "a,b" as one string, so
        # split comma-joined lists unless the whole string really is a path.
        $candidates = New-DuStringList
        if (($raw -match ',') -and (-not (Test-DuPathExists $raw))) {
            foreach ($part in ($raw -split ',')) {
                if ($part.Trim().Length -gt 0) { $candidates.Add($part.Trim()) }
            }
        } else {
            $candidates.Add($raw)
        }

        foreach ($item in $candidates) {
            # Literal first: Resolve-Path -LiteralPath keeps [ ] ? * as plain
            # characters and anchors a relative path on the PowerShell location, so
            # 'lit[1]' is measured and '.' means the directory in the prompt.
            $literal = Get-DuLiteralPath $item
            if ($literal) {
                Add-DuRoot $roots $literal
                continue
            }

            if ($item -match '[\*\?\[]') {
                $found = @(Resolve-Path -Path $item -ErrorAction SilentlyContinue)
                if ($found.Count -eq 0) {
                    Add-DuRootFailure $item 'No match found.'
                    continue
                }
                foreach ($entry in $found) {
                    $target = $entry.ProviderPath
                    if (-not $target) { $target = [string] $entry.Path }
                    Add-DuRoot $roots $target
                }
                continue
            }

            Add-DuRootFailure $item 'No such file or directory.'
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
        Total (cumulative), Shown (whether it gets a row) and a Parent reference.
        Totals are rolled up afterwards from the deepest directories upwards.
    #>
    param([string] $Root, $Ctx)

    $records = New-DuObjectList
    $rootTotal = [Int64] 0

    # A file passed as -Path behaves like `du somefile`.
    if ([System.IO.File]::Exists($Root)) {
        try {
            $file = New-Object System.IO.FileInfo($Root)
            $bytes = [Int64] $file.Length
            $Ctx.Files++
            Add-DuTopFile $Ctx $bytes $file.FullName
            $records.Add([pscustomobject]@{
                Path = $file.FullName; Shown = $true; Self = $bytes; Total = $bytes;
                Files = 1; Parent = $null
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

    $visited = New-DuHashSet
    # HashSet.Add hands back a Boolean; drop it so it cannot join this function's
    # output and corrupt the result object handed back to the caller.
    $null = $visited.Add($rootInfo.FullName)

    $maxDepth = $Ctx.MaxDepth

    # In summary mode no per-directory object is needed at all, so nothing is
    # allocated and every byte goes straight into the running root total.
    $keepRecords = -not $Ctx.Summary
    $rootRecord = $null

    $stack = New-Object 'System.Collections.Generic.Stack[object]'
    $stack.Push([pscustomobject]@{
        Dir = $rootInfo; Depth = 0; Parent = $null; Hops = 0; Links = $NoLinks
    })

    while ($stack.Count -gt 0) {
        $item = $stack.Pop()
        $dir = $item.Dir

        # The whole tree is measured regardless of -Depth, like `du --max-depth=N`:
        # directories deeper than the display limit still get a record (so their
        # bytes roll upward) but Shown stays false, so they print no row.
        $record = $null
        if ($keepRecords) {
            $record = [pscustomobject]@{
                Path   = $dir.FullName
                Shown  = ($maxDepth -lt 0 -or $item.Depth -le $maxDepth)
                Self   = [Int64] 0
                Total  = [Int64] 0
                Files  = 0
                Parent = $item.Parent
            }
            $records.Add($record)
            if (-not $rootRecord) { $rootRecord = $record }
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

                    # FullName is only built when something actually needs it.
                    if ($Ctx.ExcludePatterns.Any) {
                        $full = $null
                        if ($Ctx.ExcludePatterns.HasPath) { $full = $file.FullName }
                        if (Test-DuExcluded $Ctx.ExcludePatterns $file.Name $full) {
                            $Ctx.Excluded++
                            continue
                        }
                    }

                    $length = [Int64] $file.Length
                    if ($record) {
                        $record.Self += $length
                        $record.Files++
                    } else {
                        $rootTotal += $length
                    }
                    $Ctx.Files++
                    if ($Ctx.Top -gt 0) { Add-DuTopFile $Ctx $length $file.FullName }
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

                # Exclusion is decided before the path is recorded anywhere, so an
                # excluded directory counts as excluded (not as a repeat) and costs
                # nothing beyond the name match.
                if ($Ctx.ExcludePatterns.Any) {
                    $full = $null
                    if ($Ctx.ExcludePatterns.HasPath) { $full = $child.FullName }
                    if (Test-DuExcluded $Ctx.ExcludePatterns $child.Name $full) {
                        $Ctx.Excluded++
                        continue
                    }
                }

                $isLink = ($attrs -band $ReparseFlag) -ne 0
                if ($isLink -and (-not $Ctx.FollowLinks)) {
                    $Ctx.LinkSkipped++
                    continue
                }

                $hops = $item.Hops
                $links = $item.Links
                if ($isLink) {
                    # Two guards against a link chain that folds back on itself:
                    # the same link name reappearing on this branch, and a hard
                    # limit on how many links a single branch may traverse.
                    if ($links -contains $child.Name) { $Ctx.CycleSkipped++; continue }
                    if ($hops + 1 -gt $LinkHopLimit) { $Ctx.CycleSkipped++; continue }
                    $hops = $hops + 1
                    $links = @($links) + @($child.Name)
                }

                # De-duplicate by the real target when the runtime can name it, so
                # a junction pointing back at an already measured directory is
                # counted once rather than re-walked under a longer path.
                $key = $child.FullName
                if ($isLink) {
                    $target = Get-DuLinkTargetPath $child
                    if ($target) { $key = $target }
                }
                if ($visited.Contains($key)) { $Ctx.CycleSkipped++; continue }
                $null = $visited.Add($key)

                $stack.Push([pscustomobject]@{
                    Dir = $child; Depth = $item.Depth + 1; Parent = $record
                    Hops = $hops; Links = $links
                })
            }
        } catch {
            Add-DuError $Ctx $dir.FullName $_ 'Cannot list subdirectories'
        }
    }

    if ($Ctx.Summary) {
        return @{ Records = $records; Total = $rootTotal; FileRoot = $false }
    }

    # A parent's record is always added before any record below it, so walking the
    # list backwards guarantees every directory is complete before it rolls up.
    # (Sorting by depth cost O(n log n) plus a copy of the whole list.)
    for ($i = $records.Count - 1; $i -ge 0; $i--) {
        $record = $records[$i]
        $record.Total = $record.Total + $record.Self
        if ($record.Parent) { $record.Parent.Total = $record.Parent.Total + $record.Total }
    }

    $total = [Int64] 0
    if ($rootRecord) { $total = $rootRecord.Total }

    return @{ Records = $records; Total = $total; FileRoot = $false }
}

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

function Get-DuTruncated {
    <#  Middle truncation: keeps the root prefix and the leaf name visible. #>
    param([string] $Text, [int] $Width)

    if ($Text.Length -le $Width) { return $Text }
    if ($Width -le 5) { return $Text.Substring(0, $Width) }

    $left = [int] (($Width - 3) / 2)
    $right = $Width - 3 - $left
    return $Text.Substring(0, $left) + '...' + $Text.Substring($Text.Length - $right)
}

function Format-DuTable {
    <#
        One table renderer for both the directory rows and the largest-files rows:
        measures the columns, formats each size once, and returns the lines.
        $TotalLabel adds the closing total block; pass '' for no footer.
    #>
    param(
        $Rows,          # array or List[object]: both expose Count and an indexer
        [bool] $Human,
        [string] $PathHeader,
        [string] $TotalLabel,
        [Int64] $TotalBytes,
        [int] $WidthLimit
    )

    $lines = New-DuStringList
    if (-not $Rows -or $Rows.Count -eq 0) { return ,$lines }

    $sizes = [string[]]::new($Rows.Count)
    $pathWidth = 10
    $sizeWidth = 10

    for ($i = 0; $i -lt $Rows.Count; $i++) {
        $sizeText = Format-DuSize ([Int64] $Rows[$i].Bytes) $Human
        $sizes[$i] = $sizeText
        if ($Rows[$i].Path.Length -gt $pathWidth) { $pathWidth = $Rows[$i].Path.Length }
        if ($sizeText.Length -gt $sizeWidth) { $sizeWidth = $sizeText.Length }
    }
    if ($pathWidth -gt $WidthLimit) { $pathWidth = $WidthLimit }

    $totalText = $null
    if ($TotalLabel) {
        $totalText = Format-DuSize $TotalBytes $Human
        if ($totalText.Length -gt $sizeWidth) { $sizeWidth = $totalText.Length }
    }

    $rule = '-' * ($pathWidth + $sizeWidth + 2)

    # Sizes are built into a variable before List.Add(): inside a method call the
    # commas of '-f a, b' would be read as separate method arguments.
    $lines.Add($rule)
    $heading = '{0}  {1}' -f $PathHeader.PadRight($pathWidth), 'Size'.PadLeft($sizeWidth)
    $lines.Add($heading)
    $lines.Add($rule)

    for ($i = 0; $i -lt $Rows.Count; $i++) {
        $pathText = (Get-DuTruncated $Rows[$i].Path $pathWidth).PadRight($pathWidth)
        $row = '{0}  {1}' -f $pathText, $sizes[$i].PadLeft($sizeWidth)
        $lines.Add($row)
    }

    $lines.Add($rule)
    if ($TotalLabel) {
        $totalLine = '{0}  {1}' -f $TotalLabel.PadRight($pathWidth), $totalText.PadLeft($sizeWidth)
        $lines.Add($totalLine)
        $lines.Add($rule)
    }

    return ,$lines
}

function Write-DuTable {
    param($Rows, $Ctx)

    if (-not $Rows -or $Rows.Count -eq 0) {
        Write-Output 'du: no entries to display.'
        return
    }

    foreach ($line in (Format-DuTable $Rows $Ctx.Human 'Directory' 'Total' $Ctx.GrandTotal $DirWidthMax)) {
        Write-Output $line
    }
}

function Write-DuTopFiles {
    param($Ctx)

    if ($Ctx.Top -le 0 -or $Ctx.TopFiles.Count -eq 0) { return }

    $header = 'Largest files (top ' + $Ctx.TopFiles.Count + ')'

    Write-Output ''
    foreach ($line in (Format-DuTable $Ctx.TopFiles $Ctx.Human $header '' 0 $DirWidthMax)) {
        Write-Output $line
    }
}

function Write-DuDiagnostics {
    param($Ctx)

    if ($Ctx.ErrorsCount -gt 0) {
        # Warnings, not coloured console text: they land on the warning stream, so
        # they survive redirection and can be silenced with -WarningAction.
        Write-Warning ('du: {0} path(s) could not be read' -f $Ctx.ErrorsCount)
        $shown = 0
        foreach ($error in $Ctx.Errors) {
            if ($shown -ge $MaxShownErrors) { break }
            $shown++
            Write-Warning ('  skipped: {0} ({1})' -f $error.Path, $error.Message)
        }
        if ($Ctx.ErrorsCount -gt $Ctx.Errors.Count) {
            Write-Warning ('  ({0} further errors not listed)' -f ($Ctx.ErrorsCount - $Ctx.Errors.Count))
        }
    }

    if (-not $Ctx.Stats) { return }

    Write-Output ''
    Write-Output ('Stats: {0} path(s) scanned in {1:N1}s, {2} directories, {3} files, {4:N0} bytes counted, {5} skipped links, {6} repeats skipped, {7} hidden/system files skipped, {8} excluded entries, {9} errors' -f
        $Ctx.Roots,
        $Ctx.Clock.Elapsed.TotalSeconds,
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

function Get-DuAliasMap {
    <#
        letter -> parameter name, read from this script's own metadata. Throws if
        two switches ever claim the same letter, so uniqueness is enforced at
        start-up rather than by eye.
    #>
    $map = [System.Collections.Generic.Dictionary[string, string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase)

    if (-not $script:Command) { return $map }

    foreach ($name in $script:Command.Parameters.Keys) {
        foreach ($alias in @($script:Command.Parameters[$name].Aliases)) {
            if (-not $alias -or $alias.Length -ne 1) { continue }

            if ($map.ContainsKey($alias)) {
                throw ('du: the one-letter switch "-' + $alias + '" is claimed by both -' +
                    $map[$alias] + ' and -' + $name + '; one-letter switches must be unique.')
            }
            $map.Add($alias, $name)
        }
    }

    return $map
}

function Get-DuSwitchReference {
    <#
        Built from this script's own parameter metadata, so the listing can never
        drift from the real parameters.
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

    $aliases = Get-DuAliasMap
    $entries = New-DuObjectList

    foreach ($name in $summaries.Keys) {
        $short = ''
        foreach ($letter in $aliases.Keys) {
            if ($aliases[$letter] -eq $name) { $short = '-' + $letter; break }
        }

        $entries.Add([pscustomobject]@{
            Name  = $name
            Label = $summaries[$name].Label
            Short = $short
            What  = $summaries[$name].What
        })
    }

    return ,$entries
}

function Get-DuWrapped {
    <#  Wrap text on word boundaries so the reference never chops a word. #>
    param([string] $Text, [int] $Width)

    $lines = New-DuStringList
    $remaining = $Text

    while ($remaining.Length -gt $Width) {
        $cut = $Width
        $space = $remaining.LastIndexOf(' ', $Width)
        if ($space -gt 0) { $cut = $space }
        $lines.Add($remaining.Substring(0, $cut))
        $remaining = $remaining.Substring($cut).TrimStart()
    }
    if ($remaining.Length -gt 0) { $lines.Add($remaining) }

    return ,$lines
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
    $indent = ' ' * ($shortWidth + 2 + $nameWidth + 2)

    Write-DuLine ('{0} - disk usage of directories, like the Linux du command' -f $script:ScriptName) 'Cyan'
    Write-DuLine ''
    Write-DuLine ('Usage: .\{0} [[-Path] <dirs>] [-Depth|-MaxDepth N] [-All] [-Summary]' -f $script:ScriptName)
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

    foreach ($entry in $switches) {
        $lines = Get-DuWrapped $entry.What $textWidth
        $lead = $entry.Short.PadRight($shortWidth) + '  ' + $entry.Label.PadRight($nameWidth) + '  '
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i -eq 0) {
                Write-DuLine ($lead + $lines[$i]) 'Gray'
            } else {
                Write-DuLine ($indent + $lines[$i]) 'Gray'
            }
        }
    }

    Write-DuLine $rule
    Write-DuLine ''
    Write-DuLine 'Examples' 'DarkCyan'
    Write-DuLine ('  .\{0} .                       measure the current directory' -f $script:ScriptName)
    Write-DuLine ('  .\{0} C:\Users -h             C:\Users with K/M/G units (-h = -HumanReadable)' -f $script:ScriptName)
    Write-DuLine ('  .\{0} C:\Users -d 1           like du --max-depth=1: totals complete,' -f $script:ScriptName)
    Write-DuLine '                                   rows only for the top level of folders'
    Write-DuLine ('  .\{0} C:\Users -s             one total only' -f $script:ScriptName)
    Write-DuLine ('  .\{0} C:\Users -b 10          the 10 biggest directories' -f $script:ScriptName)
    Write-DuLine ('  .\{0} C:\Users -t 20          table plus the 20 biggest files' -f $script:ScriptName)
    Write-DuLine ('  .\{0} C:\Users -a -m          hidden files included, plus statistics' -f $script:ScriptName)
    Write-DuLine ('  .\{0} C:\Users -n             alphabetical order by path, like du --sort=name' -f $script:ScriptName)
    Write-DuLine ('  .\{0} C:\Users -d 1 -n        top level of folders, listed A-Z' -f $script:ScriptName)
    Write-DuLine ('  .\{0} . -s -h -m -q           short forms stack: -Summary -HumanReadable' -f $script:ScriptName)
    Write-DuLine '                                   -Stats -NoProgress'
    Write-DuLine ''
    Write-DuLine ('Running .\{0} with no parameters prints this reference. Pass a path,' -f $script:ScriptName) 'DarkGray'
    Write-DuLine 'or -Summary / -All and similar switches, to start a scan. For full help:' 'DarkGray'
    Write-DuLine ('  Get-Help .\{0} -Full' -f $script:ScriptName) 'DarkGray'
    Write-DuLine 'Here -h means human-readable, as in du; the reference itself is -i or -Help.' 'DarkGray'
}

# ---------------------------------------------------------------------------
# Context for one scan
# ---------------------------------------------------------------------------

function New-DuContext {
    param([string[]] $Exclude, [int] $Top, [int] $MaxDepth, [bool] $ProgressOn,
          [bool] $SummaryOn, [bool] $HumanOn, [bool] $HiddenOn, [bool] $LinksOn,
          [bool] $StatsOn)

    return @{
        Progress        = $ProgressOn
        Summary         = $SummaryOn
        Human           = $HumanOn
        IncludeHidden   = $HiddenOn
        FollowLinks     = $LinksOn
        MaxDepth        = $MaxDepth
        ExcludePatterns = ConvertTo-DuPatterns -Raw $Exclude
        Top             = $Top
        Stats           = $StatsOn
        TopFiles        = New-DuObjectList
        AllRecords      = New-DuObjectList
        Errors          = New-DuObjectList
        ErrorPaths      = New-DuHashSet
        ErrorsCount     = [Int64] 0
        Dirs            = [Int64] 0
        Files           = [Int64] 0
        LinkSkipped     = [Int64] 0
        CycleSkipped    = [Int64] 0
        HiddenSkipped   = [Int64] 0
        Excluded        = [Int64] 0
        GrandTotal      = [Int64] 0
        Roots           = 0
        Clock           = [System.Diagnostics.Stopwatch]::StartNew()
        NextProgress    = [Int64] 0
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

# A bare invocation lists the switches rather than silently measuring the current
# directory; -Help does the same thing explicitly.
if ($Help.IsPresent -or ($PSBoundParameters.Count -eq 0)) {
    Write-DuUsage
    Set-DuExitCode 0
    return
}

# Enforced before anything else: a scan should not run with a broken alias table.
$null = Get-DuAliasMap

if ($Depth -lt -1) {
    throw 'du: -Depth (alias -MaxDepth) must be -1 (unlimited) or a non-negative integer.'
}
if ($Largest -lt 0) { throw 'du: -Largest must be 0 (no limit) or a positive integer.' }
if ($Top -lt 0) { throw 'du: -Top must be 0 (none) or a positive integer.' }
if ($Progress.IsPresent -and $NoProgress.IsPresent) {
    throw 'du: -Progress (-v) and -NoProgress (-q) cannot both be given.'
}

if (-not $Path -or $Path.Count -eq 0) { $Path = @(Get-DuBasePath) }

$ctx = New-DuContext -Exclude $Exclude -Top $Top -MaxDepth $Depth `
    -ProgressOn ($Progress.IsPresent -or (-not $NoProgress.IsPresent)) `
    -SummaryOn $Summary.IsPresent -HumanOn $HumanReadable.IsPresent `
    -HiddenOn $All.IsPresent -LinksOn $FollowLinks.IsPresent -StatsOn $Stats.IsPresent

$roots = Resolve-DuRoots -Requested $Path -Ctx $ctx
if ($roots.Count -eq 0) {
    # Only reached after the per-path messages above, so this adds no new error.
    Write-Warning 'du: nothing to scan.'
    Stop-DuScript $ctx
    return
}

$ctx.Roots = $roots.Count
Write-Verbose ('du: measuring {0} path(s): {1}' -f $roots.Count, ($roots -join ', '))

$rootTotals = New-DuObjectList

try {
    foreach ($root in $roots) {
        $result = Invoke-DuTree -Root $root -Ctx $ctx
        $rootTotals.Add([pscustomobject]@{ Path = $root; Bytes = [Int64] $result.Total })
        $ctx.GrandTotal += [Int64] $result.Total
        Write-Verbose ('du: {0} = {1:N0} bytes' -f $root, [Int64] $result.Total)

        if ($ctx.Summary) {
            # Only totals matter in summary mode: drop the per-directory records.
            $result.Records.Clear()
        } else {
            foreach ($record in $result.Records) { $ctx.AllRecords.Add($record) }
        }
    }
} finally {
    Complete-DuProgress $ctx
}

# Build the directory rows. Only directories inside -Depth get a row; their totals
# already carry everything below them however deep.
$rows = New-DuObjectList

if ($ctx.Summary) {
    foreach ($entry in $rootTotals) { $rows.Add($entry) }
} else {
    foreach ($record in $ctx.AllRecords) {
        if ($record.Shown) {
            $rows.Add([pscustomobject]@{ Path = $record.Path; Bytes = [Int64] $record.Total })
        }
    }
}

# Ordering: size by default (largest first), and -Ascending flips whatever order
# is in use. -ByName switches to alphabetical order, which starts at A; it wins if
# -Sort is also given, since -Sort only names the already-default order.
$reverse = $Ascending.IsPresent
$byName = $ByName.IsPresent -and (-not $Sort.IsPresent)

if ($Largest -gt 0 -and $rows.Count -gt $Largest) {
    # -Largest always means the N biggest, whatever the display order is.
    $candidates = @($rows | Sort-Object -Property Bytes -Descending | Select-Object -First $Largest)
} else {
    $candidates = $rows
}

# Sorting strings with Sort-Object is case-insensitive, and PowerShell 5.1 has no
# -Ascending parameter for it, so the direction is chosen with -Descending.
if ($byName) {
    $sorted = @($candidates | Sort-Object -Property Path -Descending:$reverse)
} elseif ($reverse) {
    $sorted = @($candidates | Sort-Object -Property Bytes)
} else {
    $sorted = @($candidates | Sort-Object -Property Bytes -Descending)
}

Write-DuTable -Rows $sorted -Ctx $ctx
Write-DuTopFiles -Ctx $ctx
Write-DuDiagnostics -Ctx $ctx

# Signal failure to callers (CI checks), without killing a dot-sourcing session.
Stop-DuScript $ctx
