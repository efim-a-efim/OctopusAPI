function Normalize-YAML {
    <#
    .SYNOPSIS
    
    Normalize YAML content by adding quotes to all values except numbers
    
    .PARAMETER Data
    Input data as strings
    
    .INPUTS
    System.String objects containing YAML
    
    .OUTPUTS
    System.String objects with normalized YAML
    
    .EXAMPLE
    Get-Content '.\content.yaml' | Normalize-YAML
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$true)]
        [string[]]$Data
    )
    $Data | ForEach-Object {
        If ( (($_ -split '\:\s*',2)[1] -ne $null) -and (($_ -split '\:\s*',2)[1] -ne '') -and -not ( ($_ -split '\:\s*',2)[1].StartsWith("'") ) -and -not ( ($_ -split '\:\s*',2)[1].StartsWith('"') )) { 
            "$(($_ -split '\:\s*',2)[0]): '$(($_ -split '\:\s*',2)[1])'" 
        } else {
            $_
        }
    }
}

Export-ModuleMember *