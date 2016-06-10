#Require Version=5
Class OctopusVariableSet {
    hidden [string]$Server;
    hidden [string]$ApiKey;
    hidden [string]$id;
    
    hidden [object]$Content;
    
    OctopusVariableSet([string]$id, [string]$Server=$env:OCTOPUS_URI, [string]$ApiKey=$env:OCTOPUS_API_KEY) {
        $this.Server = $Server
        $this.ApiKey = $ApiKey
        $this.id = $id
        $this.update()
    }
    
    hidden [void]update(){
        $this.Content = Get-OctopusResource "variables/$($this.Id)" 
    }
    
    hidden [void] apply() {
        Set-OctopusResource "variables/$($this.Content.Id)" $this.Content
        $this.update()
    }
    
    hidden [hashtable] convert_scope([hashtable]$scope) {
        $realScope = @{}
        @('Environment','Machine','Action','Role') | foreach {
            $scopeKey = $_
            If ($Scope.ContainsKey($scopeKey)) {
                $realScope[$scopeKey] = @()
                $Scope[$scopeKey] | foreach {
                    $scopeName = $_
                    $s = (Get-OctopusResource "$($scopeKey)s/all").Where({$_.Name -eq $scopeName}) 
                    If ($s) {$realScope[$scopeKey] += $($s.Id)}
                }
            }
        }
        return $realScope
    }
    
    hidden [bool] compare_scope($scope1, $scope2) {
        If ($scope1 -eq $null -or $scope1 -eq @{} -or $scope1.Keys -eq $null -or $scope1.Keys.Count -eq 0) {
            If ($scope2 -eq $null -or $scope2 -eq @{} -or $scope2.Keys -eq $null -or $scope2.Keys.Count -eq 0 ) {return $true}
            return $false
        }
        If (Compare-Object $scope1.Keys $scope2.Keys) { return $false }
        
        $scope1.Keys | foreach {
            If (Compare-Object $scope1[$_] $scope2[$_]) {return $false }
        }
        return $true
    }
    
    [string] get([string]$name) { return $this.get($name, @{}) }
    [string] get([string]$name, [hashtable]$scope) {
        $var = $this.get_with_properties($name, $scope)
        If ($var) {return $var.Value}
        return $null
    }

    [object] get_with_properties([string]$name) { return $this.get_with_properties($name, @{}) }
    [object] get_with_properties([string]$name, [hashtable]$scope) {
        $this.update()
        $s = $this.convert_scope($scope)
        $var = $this.Content.Variables | Where {$_.Name -eq $name} | Where {$this.compare_scope($s, $_.Scope)}
        If ($var) {
            $sc = @{}
            $var.Scope.PSObject.Properties | foreach {$sc[$_.Name]=[array]$_.Value}
            return New-Object psobject -Property @{
                Id = $var.Id
                Name = $var.Name
                Value = $var.Value
                Scope = $sc
                IsSensitive = $var.IsSensitive
                IsEditable = $var.IsEditable
                Prompt = $var.Prompt
            }
        }
        return $null
    }
    
    hidden [void]set_variable([string]$name, [string]$value, [psobject]$scope, [bool]$sensitive, [string]$prompt){
        $need_to_add = $true
        $this.Content.Variables | Where {$_.Name -eq $name} | Where { $this.compare_scope($_.Scope, $s) } | foreach {
            $_.Value=$value;
            $need_to_add=$false
        }
        If ($need_to_add) {
            $newVar = New-Object psobject -Property @{
                Id = [guid]::NewGuid()
                Name = $name
                Value = $value
                Scope = $scope
                IsSensitive = $sensitive
                IsEditable = $true
                Prompt = $prompt
            }
            $this.Content.Variables += $newVar
        }
    }
    
    
    [void]set([string]$name, [string]$value) {$this.set($name, $value, @{}, $false, '')}
    [void]set([string]$name, [string]$value, [hashtable]$scope) {$this.set($name, $value, $scope, $false, '')}
    [void]set([string]$name, [string]$value, [hashtable]$scope, [bool]$sensitive) {$this.set($name, $value, $scope, $sensitive, '')}
    [void]set([string]$name, [string]$value, [hashtable]$scope, [bool]$sensitive, [string]$prompt) {
        $this.update()
        $s = New-Object psobject -Property $this.convert_scope($scope)
        $this.set_variable($name, $value, $s, $sensitive, $prompt)
        $this.apply()
    }

    [void]load([hashtable]$variables){$this.load([hashtable]$variables, $false, @{}, $false)}
    [void]load([hashtable]$variables, [bool]$clear, [hashtable]$scope) { $this.load([hashtable]$variables, $clear, $scope, $false) }
    [void]load([hashtable]$variables, [bool]$clear, [hashtable]$scope, [bool]$sensitive) {
        If ($clear) {
            $this.Content.Variables = @()
        } else {
            $this.update()
        }
        $s = New-Object psobject -Property $this.convert_scope($scope)
        
        $variables.Keys | foreach {
            $this.set_variable($_, $variables[$_], $s, $sensitive, '')
        }
        
        $this.apply()
    }

    [void]load([OctopusVariableSet]$variables){$this.load([OctopusVariableSet]$variables, $false)}
    [void]load([OctopusVariableSet]$variables, [bool]$clear){
        If ($clear) {
            $this.Content.Variables = @()
        } else {
            $this.update()
        }
        $variables.Content.Variables | foreach {
            $this.set_variable([string]$_.Name, [string]$_.Value, [psobject]$_.Scope, [bool]$_.Sensitive, [string]$_.Prompt)
        }
        $this.apply()
    }
        
    [void]clear() {
        $this.Content.Variables = @()
        $this.apply()
    }
    
    [void]remove([string]$name, [hashtable]$scope){
        $this.update()
        $newVariables = @{}
        $this.Content.Variables | Where {
            -Not ($_.Name -eq $name) -and -Not $this.compare_scope($_.Scope, $this.convert_scope($scope))
        } | foreach ($newVariables.Add($_))
        $this.Content.Variables = $newVariables
        $this.apply()
    }
    
    [void]remove([string]$name){
        $this.update()
        $newVariables = [System.Collections.ArrayList]@()
        $this.Content.Variables | Where { -Not ($_.Name -Like $name) } | foreach {$newVariables.Add($_)}
        $this.Content.Variables = [Array]$newVariables
        $this.apply()
    }
    
    [string]export() {
        $this.update()
        return $($this.Content.Variables | ConvertTo-Json -Depth 10)
    }
    
    [void]import([object[]]$data){
        $this.Content.Variables = $data
        $this.apply()
    }
    
    [void]each([scriptblock]$action){
        $this.Content.Variables | foreach {
            Invoke-Command -ScriptBlock $action -ArgumentList @( $_ )
        }
    }
    
    [bool]contains([string]$name){ return $this.contains($name, @{})}
    [bool]contains([string]$name, [hashtable]$scope) {
        $vars = $this.Content.Variables | Where { $_.Name -Like $name -and $this.compare_scope($_.Scope, $this.convert_scope($scope))}
        If ($vars) {return $true}
        return $false
    }

    [bool]contains_value([string]$value){
        $vars = $this.Content.Variables | Where { $_.value -eq $value -or $_.Value -Like $value -or $_.Value -Match $value }
        If ($vars) {return $true}
        return $false
    }

    [void]rename_variable([string]$name, [string]$new_name){
        $this.Content.Variables | Where {$_.Name -eq $name} | ForEach-Object {$_.Name = $new_name}
        $this.apply()
    }
    [void]replace_variable([string]$name, [string]$new_name){
        $this.Content.Variables | Where {$_.Value -Match [regex]::escape("#{$name}")} | ForEach-Object { $_.Value = $_.Value -replace [regex]::escape("#{$name}"),"#{$new_name}"}
        $this.apply()
    }
}
