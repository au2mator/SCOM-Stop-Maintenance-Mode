#########
# au2mator PS Services
# Start SCOM Maintenance Mode
# v 1.0 Initial Release
# URL: https://au2mator.com/?p=17286
#################



#region InputParamaters
##Question in au2mator
param (
    [parameter(Mandatory = $true)] 
    [String]$c_ScomDA,

    [parameter(Mandatory = $true)] 
    [String]$c_Comment, 
 
    [parameter(Mandatory = $true)] 
    [String]$InitiatedBy, 

    [parameter(Mandatory = $true)] 
    [String]$RequestId, 
 
    [parameter(Mandatory = $true)] 
    [String]$Service, 
 
    [parameter(Mandatory = $true)] 
    [String]$TargetUserId
)
#endregion  InputParamaters

#region Controll
$DoImportPSSession = $true
$ErrorCount = 0

#endregion Conroll

#region Variables
[string]$OpsmgrServer = 'Demo01'
[string]$LogPath = "C:\_SCOworkingDir\TFS\PS-Services\SCOM - Stop Maintenance Mode"
[string]$LogfileName = "Stop-Maintenance Mode"
#endregion Variables

#region Functions
function Write-au2matorLog {
    [CmdletBinding()]
    param
    (
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR')]
        [string]$Type,
        [string]$Text
    )
       
    # Set logging path
    if (!(Test-Path -Path $logPath)) {
        try {
            $null = New-Item -Path $logPath -ItemType Directory
            Write-Verbose ("Path: ""{0}"" was created." -f $logPath)
        }
        catch {
            Write-Verbose ("Path: ""{0}"" couldn't be created." -f $logPath)
        }
    }
    else {
        Write-Verbose ("Path: ""{0}"" already exists." -f $logPath)
    }
    [string]$logFile = '{0}\{1}_{2}.log' -f $logPath, $(Get-Date -Format 'yyyyMMdd'), $LogfileName
    $logEntry = '{0}: <{1}> <{2}> <{3}> {4}' -f $(Get-Date -Format dd.MM.yyyy-HH:mm:ss), $Type, $RequestId, $Service, $Text
    Add-Content -Path $logFile -Value $logEntry
}

function Get-Params {
    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    # Get the list of parameters for the command
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    # Grab each parameter value, using Get-Variable
    foreach ($Parameter in $ParameterList) {
        $List = Get-Variable -Name $Parameter.Values.Name -ErrorAction SilentlyContinue;
        foreach ($L in $List) {
            Write-au2matorLog -Type INFO -Text ('VariableName: {0}  --  Value: {1}' -f $L.Name, $L.Value)
        }
    }
}
#endregion Functions


#region Script
Write-au2matorLog -Type INFO -Text "Start Script"
Write-au2matorLog -Type INFO -Text "Write Variables and Values"
Get-Params

if ($DoImportPSSession) {

    Write-au2matorLog -Type INFO -Text "Import-Pssession"
    $PSSession = New-PSSession -ComputerName $OpsmgrServer
    Import-PSSession -Session $PSSession -DisableNameChecking -ArgumentList '.\SCOM - Stop Maintenance Mode' -AllowClobber
}
else {
        
}

Write-au2matorLog -Type INFO -Text "Import SCOM PS Module"
Import-Module OperationsManager

Write-au2matorLog -Type INFO -Text "Try to stop Maintenance Mode"
try {
    $scomclasseinstance = Get-SCOMClassInstance -DisplayName $c_ScomDA | Where-Object -Property FullName -Value "Service_*" -Like
    $NewEndTime = Get-Date;
    $scomclasseinstance | Get-SCOMMaintenanceMode | Set-SCOMMaintenanceMode -EndTime $NewEndTime -Comment $c_Comment 
    Write-au2matorLog -Type INFO -Text "Maintenance Mode stopped"
    
}
catch {
    $ErrorCount = 1
    Write-au2matorLog -Type ERROR -Text "Error on Maintenance Mode DeActivation"
    Write-au2matorLog -Type ERROR -Text $Error
    
}
#endregion Script


#region Return
## return to au2mator Services
if ($ErrorCount -eq 0) {
    return "Maintenance Mode Set for $c_ScomDA"
}
else {
    return "Error on Set Maintenance Mode for $c_ScomDA, see Log File for Details"
}  

Write-au2matorLog -Type INFO -Text "Service finished"
#endregion Return