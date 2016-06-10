function Get-OctopusResource {
    <#
    .SYNOPSIS
    Get Octopus resource as object
    
    .PARAMETER uri
    Resource URI
    .PARAMETER Server
    Octopus server URL. By default taken from OCTOPUS_URI environment variable.
    .PARAMETER ApiKey
    Octopus API key. By default taken from OCTOPUS_API_KEY environment variable.

    .OUTPUTS
    JSON representation of resource
    #>
    [CmdletBinding()]
    param (
        [Parameter(mandatory=$true,position=0)][ValidateNotNull()]
        [string]$uri,
        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$Server=$ENV:OCTOPUS_URI,
        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$ApiKey=$ENV:OCTOPUS_API_KEY
    )
    Write-Verbose "[GET]: $uri"
    return Invoke-RestMethod -Method Get -Uri "$Server/api/$uri" -Headers @{"X-Octopus-ApiKey" = $ApiKey}
}
