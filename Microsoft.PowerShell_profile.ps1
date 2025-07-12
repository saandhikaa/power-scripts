function prompt {
    # ANSI escape codes for colors
    $resetColor = "$([char]27)[0m"
    $blue = "$([char]27)[1;34m"
    $brightPink = "$([char]27)[1;95m"  # Brighter pink for branch
    $yellow = "$([char]27)[1;33m"
    $green = "$([char]27)[1;32m"
    $red = "$([char]27)[1;31m"
    $cyan = "$([char]27)[1;36m"

    # Git status variables with normal symbols (powerlevel style)
    $gitBranch = ''
    $gitSymbol = [char]0xe0a0  # Nerd Fonts Git Branch Symbol ()
    $gitUntrackedSymbol = '?'  # Powerlevel-style symbol for untracked files
    $gitModifiedSymbol = '!'   # Powerlevel-style symbol for modified files
    $gitDeletedSymbol = 'x'    # Powerlevel-style symbol for deleted files
    $gitPushSymbol = '↑'       # Powerlevel-style symbol for push
    $gitPullSymbol = '↓'       # Powerlevel-style symbol for pull

    # Get the full current path and shorten if needed
    $fullPath = (Get-Location).Path
    $pathParts = $fullPath -split '\\'
    $maxLength = 70

    if ($fullPath.Length -gt $maxLength) {
        # Split path into parts and keep the last part (leaf)
        $pathParts = $fullPath -split '\\'
        $leaf = $pathParts[-1]
        $shortenedPath = " ..." + ($fullPath.Substring($fullPath.Length - $maxLength + 3))
    } else {
        $shortenedPath = $fullPath
    }

    # Check if current location is a git repository
    if (Test-Path .git) {
        # Get the current branch name
        $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null

        # Get uncommitted changes
        $gitStatus = git status --porcelain 2>$null
        $untracked = ($gitStatus | Select-String '^\?\?' -AllMatches).Matches.Count
        $modified = ($gitStatus | Select-String '^ M' -AllMatches).Matches.Count
        $deleted = ($gitStatus | Select-String '^ D' -AllMatches).Matches.Count

        # Check if need to push or pull
        $ahead = git rev-list --count "HEAD@{u}..HEAD" 2>$null
        $behind = git rev-list --count "HEAD..HEAD@{u}" 2>$null

        # Construct Git branch details with powerlevel-style symbols and colors
        $gitDetails = ""
        if ($untracked -gt 0) { $gitDetails += " $cyan$gitUntrackedSymbol$untracked$resetColor" }
        if ($modified -gt 0) { $gitDetails += " $yellow$gitModifiedSymbol$modified$resetColor" }
        if ($deleted -gt 0) { $gitDetails += " $red$gitDeletedSymbol$deleted$resetColor" }
        if ($ahead -gt 0) { $gitDetails += " $green$gitPushSymbol$ahead$resetColor" }
        if ($behind -gt 0) { $gitDetails += " $green$gitPullSymbol$behind$resetColor" }

        # Apply bright pink color to branch name
        $gitBranch = " $brightPink$gitSymbol $gitBranch$resetColor$gitDetails"
    }

    # Build the prompt with colored path and Git status
    "`n$blue$shortenedPath$gitBranch$resetColor`n> "
}
