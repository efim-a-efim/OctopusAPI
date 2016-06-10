function Get-OctopusLinkedResource {
    <#
    .SYNOPSIS
    Get linked Octopus resource by link name. Useful for hierarchy browsing.

    .PARAMETER Resource
    Octopus resource that contains links

    .PARAMETER Resource
    Resource with links
    .PARAMETER Link
    Link name
    .PARAMETER Server
    Octopus server URL. By default taken from OCTOPUS_URI environment variable.
    .PARAMETER ApiKey
    Octopus API key. By default taken from OCTOPUS_API_KEY environment variable.

    .OUTPUTS object
    Octopus resource by link or Null if resource not found. 

    .EXAMPLE
    # Get Octopus API root
    $root = Get-OctopusResource ''
    $tasks = Get-OctopusLinkedResource $root 'Tasks'
    #>
    [CmdletBinding()]
    param (
        [Parameter(mandatory=$true,position=0)][ValidateNotNullOrEmpty()]
        [object]$Resource,
        [Parameter(mandatory=$true,position=1)][ValidateNotNullOrEmpty()]
        [string]$Link,
        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$Server=$ENV:OCTOPUS_URI,
        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$ApiKey=$ENV:OCTOPUS_API_KEY
    )
    
    If (-Not ( (Get-Member -InputObject $Resource).Name.Contains('Links') ) ) { return $null }
    $links = $Resource.Links.PSObject.Properties.Where({$_.Name -eq $Link})
    If (-Not $links ) { return $null }
    $uri = $links[0].Value
    Write-Verbose $uri
    # remove parameters
    If ($uri -match '\{[\w\,\-]+\}') { $uri = $uri.Substring(0, $uri.IndexOf('{')) }
    
    Write-Verbose "[GET]: $uri"
    return Invoke-RestMethod -Method Get -Uri "$Server/$uri" -Headers @{"X-Octopus-ApiKey" = $ApiKey}
}