function New-OctopusResource {
    <#
    .SYNOPSIS
    Create Octopus resource
    
    .PARAMETER uri
    Resource URI
    .PARAMETER resource
    Resource body as object
    .PARAMETER Server
    Octopus server URL. By default taken from OCTOPUS_URI environment variable.
    .PARAMETER ApiKey
    Octopus API key. By default taken from OCTOPUS_API_KEY environment variable.
    #>
    [CmdletBinding()]
    param (
        [Parameter(mandatory=$true,position=0)][ValidateNotNullOrEmpty()]
        [string]$uri,
        [Parameter(mandatory=$true,position=1)][ValidateNotNull()]
        [object]$resource,
        [Parameter(mandatory=$false)]
        [string]$Server=$ENV:OCTOPUS_URI,
        [Parameter(mandatory=$false)]
        [string]$ApiKey=$ENV:OCTOPUS_API_KEY
    )
    Write-Verbose "[POST]: $uri"
    return Invoke-RestMethod -Method Post -Uri "$Server/api/$uri" -Body $($resource | ConvertTo-Json -Depth 20) -Headers @{"X-Octopus-ApiKey" = $ApiKey}
}
