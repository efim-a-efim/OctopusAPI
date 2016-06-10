#Require Version=5
function Rename-OctopusVariable {
    <#
    .SYNOPSIS
    Rename variable(s) in Octopus
    .DESCRIPTION
    Rename variable(s) in Octopus. Renames all references to the variable.
    If -CreateMock parameter specified, will also create a transitional variable with value referencing new variable name.

    .PARAMETER Name
    Old variable name.
    .PARAMETER NewName
    New name for the variable.
    .PARAMETER NameMap
    Hashtable with old variable names as keys and new names as values. Use for mass variables renaming.
    .PARAMETER Filter
    Limit action to specified project/library variable set name. Supports wildcards.
    .PARAMETER CreateMock
    Create additional variable with old name and value referencing new variable.
    .PARAMETER Server
    Octopus server URL. By default taken from OCTOPUS_URI environment variable.
    .PARAMETER ApiKey
    Octopus API key. By default taken from OCTOPUS_API_KEY environment variable.

    .EXAMPLE
    # single variable rename
    Rename-OctopusVariable -Name 'VarOld' -NewName 'VarNew'
    .EXAMPLE
    # Limit to all variable sets/projects starting with 'OctoFX'
    Rename-OctopusVariable -Name 'VarOld' -NewName 'VarNew' -Filter 'OctoFX*'
    .EXAMPLE
    # Create intermediate transitional variable
    Rename-OctopusVariable -Name 'VarOld' -NewName 'VarNew' -Filter 'OctoFX*' -CreateMock
    .EXAMPLE
    # Mass rename
    @{
        'OldVar1'='OctoFX.Var1'
        'OldVar2'='OctoFX.Var2'
    } | Rename-OctopusVariable -Filter 'OctoFX*' -CreateMock
    #>
    [CmdletBinding(DefaultParameterSetName="Multiple")]
    Param(
        [Parameter(
            mandatory=$true,
            position=0,
            ValueFromPipeline=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='Single')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Alias("Value")]
        [Parameter(
            mandatory=$true,
            position=1,
            ValueFromPipeline=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='Single')]
        [ValidateNotNullOrEmpty()]
        [string]$NewName,

        [Parameter(
            mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Variable names hash",
            ParameterSetName='Multiple')]
        [ValidateNotNullOrEmpty()]
        [hashtable[]]$NameMap,

        [Parameter(mandatory=$false)]
        [switch]$CreateMock,
        [Parameter(mandatory=$false)]
        [SupportsWildcards()]
        [string]$Filter='*',

        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$Server=$ENV:OCTOPUS_URI,
        [Parameter(mandatory=$false)][ValidateNotNullOrEmpty()]
        [string]$ApiKey=$ENV:OCTOPUS_API_KEY
    )

    begin {
        $InputArray = @()
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Single' {
                $InputArray += @{"$Name"="$NewName"}
            }
            'Multiple' {
                $InputArray += $NameMap
                }
        }
    }

    end {
        foreach($uri in @('libraryvariablesets/all', 'projects/all')){
            (Get-OctopusResource -uri $uri -Server $Server -ApiKey $ApiKey) | ForEach-Object {
                If ($_.Name -Like $Filter) {
                    $vs = New-OctopusVariableSet -uri "variables/$($_.VariableSetId)" -Server $Server -ApiKey $ApiKey
                    Write-Verbose "Variable set ID: $($vs.Id)"
                    foreach($h in $InputArray) {
                        $h | Write-Verbose
                        $h.GetEnumerator() | ForEach-Object {
                            Write-Verbose "Renaming variable $($_.Name) to $($_.Value)"
                            $vs.rename_variable($_.Name, $_.Value)
                            $vs.replace_variable($_.Name, $_.Value)
                            If ($CreateMock.IsPresent){
                                Write-Verbose "Creating mock variable $($_.Name) with value '#{$($_.Value)}'"
                                $vs.set($_.Name, "#{$($_.Value)}")
                            }
                        }
                    }
                }
            }
        }
    }
}