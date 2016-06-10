function Remove-OctopusResource {
    <#
    .SYNOPSIS
    Remove Octopus resource
    
    .PARAMETER uri
    Resource URI
    .PARAMETER Server
    Octopus server URL. By default taken from OCTOPUS_URI environment variable.
    .PARAMETER ApiKey
    Octopus API key. By default taken from OCTOPUS_API_KEY environment variable.
    #>
    [CmdletBinding()]
    param (
        [Parameter(mandatory=$true,position=0)][ValidateNotNullOrEmpty()]
        [string]$uri,
        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$Server=$ENV:OCTOPUS_URI,
        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$ApiKey=$ENV:OCTOPUS_API_KEY
    )
    Write-Verbose "[DELETE]: $uri"
    return Invoke-RestMethod -Method Delete -Uri "$Server/api/$uri" -Headers @{"X-Octopus-ApiKey" = $ApiKey}
}