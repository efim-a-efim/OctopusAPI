#Requires -Version 5

function Get-OctopusResource {
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

function Get-OctopusLinkedResource {
    <#
    .SYNOPSIS
    Get linked Octopus resource by link name. Useful for hierarchy browsing.
    
    .PARAMETER Resource
    Octopus resource that contains links
    
    .PARAMETER Link
    Link name
    
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

function Set-OctopusResource {
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

function Remove-OctopusResource {
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

function New-OctopusResource {
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


function Ignore-SSLErrors {
    add-type -TypeDefinition  @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
