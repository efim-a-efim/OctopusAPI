#Require Version=5
function New-OctopusVariableSet {
    <#
    .SYNOPSIS
    Creates new Octopus variable set object
    .DESCRIPTION
    Gets new variable set from Octopus or creates it if it does not exist.

    .PARAMETER uri
    URI of the variable set

    .PARAMETER Name
    Library variable set name
    .PARAMETER Create
    Create library variable set if it does not exist
    .PARAMETER Description
    Library variable set description
    .PARAMETER Project
    Project name to get project's variable set
    .PARAMETER Server
    Octopus server URL. By default taken from OCTOPUS_URI environment variable.
    .PARAMETER ApiKey
    Octopus API key. By default taken from OCTOPUS_API_KEY environment variable.
    .OUTPUTS
    [OctopusVariableSet] object
    #>
    [CmdletBinding(DefaultParameterSetName='ByURI')]
    param (
        [Parameter(mandatory=$true,position=0,ParameterSetName='ByURI')][ValidateNotNullOrEmpty()]
        [string]$uri,
        
        [Parameter(mandatory=$true,position=0,ParameterSetName='ByName')][ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(mandatory=$false,position=1,ParameterSetName='ByName')][ValidateNotNull()]
        [string]$Description='',
        [Parameter(mandatory=$false,ParameterSetName='ByName')]
        [switch]$Create,
        
        [Parameter(mandatory=$true,position=0,ParameterSetName='ByProject')][ValidateNotNullOrEmpty()]
        [string]$Project,
                
        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$Server=$ENV:OCTOPUS_URI,
        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$ApiKey=$ENV:OCTOPUS_API_KEY
    )

    $SetId = $null
    switch -exact ($PSCmdlet.ParameterSetName) {
        'ByName' {
            $res = (Get-OctopusResource 'libraryvariablesets/all' -Server $Server -ApiKey $ApiKey) | where {$_.Name -eq $Name}
            If ($res) {
                $SetId = $res[0].VariableSetId
            } else {
                If ($Create.IsPresent){
                    # Create new variable set
                    $varSetObj = New-Object psobject -Property @{
                        Name = $Name
                        Description = $Description
                        ContentType = 'Variables'
                    }
                    $SetId = (New-OctopusResource 'libraryvariablesets' $varSetObj -Server $Server -ApiKey $ApiKey).Id
                }
            }
        }
        'ByProject' {
            $res = (Get-OctopusResource 'projects/all' -Server $Server -ApiKey $ApiKey)|Where {$_.Name -eq $Project}
            If ($res) {
                $SetId = $res[0].VariableSetId
            }            
        }

        'ByURI' {
            if ($uri.StartsWith('variables/')) {
                $SetId = ($uri -split '/')[1]
            } else {
                $res = Get-OctopusResource $uri -Server $Server -ApiKey $ApiKey
                If ($res) {
                    $SetId = $res.VariableSetId
                }
            }
        }
    }
    Write-Verbose $SetId
    If (-Not $SetId) { return $null }
    return [OctopusVariableSet]::New($SetId, $Server, $ApiKey)
}


