# Load all required files
Push-Location $PSScriptRoot
@(
    'BasicFunctions.ps1',
    'OctopusVariableSet.ps1'
) | foreach-object {
    $p = Resolve-Path $_ -ErrorAction SilentlyContinue
    If ($p -ne $null){
        . $p
    }
} 
Pop-Location

Export-ModuleMember *