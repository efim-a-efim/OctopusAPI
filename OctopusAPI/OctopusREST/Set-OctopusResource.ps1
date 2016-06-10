function Set-OctopusResource {
    <#
    .SYNOPSIS
    Set Octopus resource value
    
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
        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$Server=$ENV:OCTOPUS_URI,
        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$ApiKey=$ENV:OCTOPUS_API_KEY
    )
    Write-Verbose "[PUT]: $uri"
    $body = $resource | ConvertTo-Json -Depth 10
    Write-Debug "Body: $body"
    return Invoke-RestMethod -Method Put -Uri "$Server/api/$uri" -Body $body -Headers @{"X-Octopus-ApiKey" = $ApiKey}
}
