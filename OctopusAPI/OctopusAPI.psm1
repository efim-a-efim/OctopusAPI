Push-Location $PSScriptRoot
@(
    # Helpers and classes must be loaded first
    'Helpers\*.ps1',
    'OctopusREST\*.ps1',
    'Classes\*.ps1',
    # Worker functions
    'Variables\*.ps1'
) | ForEach-Object {
    Resolve-Path $_ -ErrorAction SilentlyContinue | Where {$_ -ne $null} | ForEach-Object {
        . $_
    }
}
Pop-Location

Export-ModuleMember *