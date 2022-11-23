<#
.SYNOPSIS
Set Windows configurations for Azure to prepare a Windows VHD from on-prem to create Azure Windows VM.
.DESCRIPTION
Before you upload a Windows virtual machine (VM) from on-premises to Azure, you must prepare the virtual hard disk (VHD or VHDX). Azure supports both generation 1 and generation 2 VMs that are in VHD file format and that have a fixed-size disk. The script must run before you are going to start the Sysprep. The maximum size allowed for the OS VHD on a generation 1 VM is 2 TB.

You can convert a VHDX file to VHD, convert a dynamically expanding disk to a fixed-size disk, but you can't change a VM's generation. For more information, see https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/Should-I-create-a-generation-1-or-2-virtual-machine-in-Hyper-V and https://docs.microsoft.com/en-us/azure/virtual-machines/generation-2

For information about the support policy for Azure VMs, see https://docs.microsoft.com/en-US/troubleshoot/azure/virtual-machines/server-software-support

The instructions in this article apply to:

The 64-bit version of Windows Server 2008 R2 and later Windows Server operating systems. For information about running a 32-bit operating system in Azure, https://docs.microsoft.com/en-US/troubleshoot/azure/virtual-machines/support-32-bit-operating-systems-virtual-machines 
If any Disaster Recovery tool will be used to migrate the workload, like Azure Site Recovery or Azure Migrate, this process is still required on the Guest OS to prepare the image before the migration.
.NOTES
The script is provided 'as is' and without warranty of any kind. 
Version: 2.0 - Minor changes.
Version log changes: 1.7 - First variant of script, setting up variables and functions
                           - PowerShell Module development
                           - Creating the Module manifest
Version log changes: 1.8 - Updated the Write-Host values and messages.
Version log changes: 1.9 - Minor fixes.
Author: Andrei Pintica (@AndreiPintica)
#>

#Variables
$foregroundColor1 = "Red"
$foregroundColor2 = "Green"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "
$global:currenttime = Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}

## Check if PowerShell runs as Administrator, otherwise exit the script

if ($isAdministrator -eq $false) {
    # Check if running as Administrator, otherwise exit the script
    Write-Host ($writeEmptyLine + "Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    Start-Sleep -s 3
    exit
} else {
    # If running as Administrator, start script execution    
    Write-Host ($writeEmptyLine + "Script started. Without any errors, it will need around 2 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine 
}

<#---------------------------Set Windows configurations for Azure----------------------#>

#The System File Checker (SFC) is used to verify and replace Windows system files.
function SfcFix () {
    Start-Process -FilePath "${env:Windir}\System32\SFC.EXE" -ArgumentList '/scannow' -Wait -Verb RunAs 
}
Write-Host ($writeEmptyLine + "SFC Scan started" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function SfcFix

#Remove all persistent routes
function RemovePersistentRoutes () {
    Get-WmiObject Win32_IP4PersistedRouteTable | Select-Object Destination, Mask, Nexthop, Metric1 | Where-Object -FilterScript {$_.Metric1 -eq 1} | ForEach-Object {ROUTE DELETE $_.Destination}    
}
Write-Host ($writeEmptyLine + "Remove all persistent routes - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

Export-ModuleMember -Function RemovePersistentRoutes

#Remove proxy
function RemoveProxy () {    
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyServer -Value ""
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -Value 0
}
Write-Host ($writeEmptyLine + "Remove proxy - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function RemoveProxy

#Diskpart SAN Policy to Onlineall
function SetSanPolicy () {
    Set-StorageSetting -NewDiskPolicy OnlineAll
}
Write-Host ($writeEmptyLine + "Diskpart SAN Policy to Onlineall - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function SetSanPolicy

#Set Coordinated Universal Time (UTC)
function UTC () { 
    Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation -Name RealTimeIsUniversal -Value 1 -Type DWord -Force
    Set-Service -Name w32time -StartupType Automatic 
}
Write-Host ($writeEmptyLine + "Set Coordinated Universal Time (UTC) - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function UTC

#Set power profile to high performance
function PowerProfile () {
powercfg.exe /setactive SCHEME_MIN
}
Write-Host ($writeEmptyLine + "Set power profile to high performance - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function PowerProfile

#Set TMP and TEMP to default values
function Temp () {
    [System.Environment]::SetEnvironmentVariable('TEMP','%SystemRoot%\TEMP',[System.EnvironmentVariableTarget]::Machine)
    [System.Environment]::SetEnvironmentVariable('TMP','%SystemRoot%\TEMP',[System.EnvironmentVariableTarget]::Machine)
}
Write-Host ($writeEmptyLine + "Set TMP and TEMP to default values - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
Export-ModuleMember -Function Temp

<#---------------------------Check the Windows Services---------------------------------#>

#Check Windows Services
function WindowsServices () {
Get-Service -Name BFE, Dhcp, Dnscache, IKEEXT, iphlpsvc, nsi, mpssvc, RemoteRegistry |
Where-Object StartType -ne Automatic |
Set-Service -StartupType Automatic
  
Get-Service -Name Netlogon, Netman, TermService |
Where-Object StartType -ne Manual |
Set-Service -StartupType Manual
}
Write-Host ($writeEmptyLine + "Check Windows Services - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function WindowsServices
<#-------------------------------Update remote desktop registry settings--------------------#>

#Enable Remote Desktop Protocol (RDP)
function EnableRDP () {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0 -Type DWord -Force
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name fDenyTSConnections -Value 0 -Type DWord -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
}
Write-Host ($writeEmptyLine + "Enable Remote Desktop Protocol (RDP) - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function EnableRDP

#Set default 3389 port for RDP
function DefaultRDP () {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name PortNumber -Value 3389 -Type DWord -Force
}
Write-Host ($writeEmptyLine + "Set default 3389 port for RDP- Done" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function DefaultRDP

#The listener is listening on every network interface
function RDPListener () { 
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name LanAdapter -Value 0 -Type DWord -Force     
}
Write-Host ($writeEmptyLine + "The listener is listening on every network interface - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function RDPListener

#Configure network-level authentication (NLA) mode for the RDP connections:
function NLA () {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1 -Type DWord -Force
}
Write-Host ($writeEmptyLine + "NLA value set to 1" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function NLA

#Set the keep-alive value
function KeepAlive () {
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name KeepAliveEnable -Value 1  -Type DWord -Force
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name KeepAliveInterval -Value 1  -Type DWord -Force
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name KeepAliveTimeout -Value 1 -Type DWord -Force
}
Write-Host ($writeEmptyLine + "Configure keep-alive value - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function KeepAlive

#Set the reconnect options
function Reconnect () {
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name fDisableAutoReconnect -Value 0 -Type DWord -Force
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name fInheritReconnectSame -Value 1 -Type DWord -Force
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name fReconnectSame -Value 0 -Type DWord -Force  
}
Write-Host ($writeEmptyLine + "Set reconnect options - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function Reconnect

#Limit the number of concurrent connections:
function LimitConnections () {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name MaxInstanceCount -Value 4294967295 -Type DWord -Force
}
Write-Host ($writeEmptyLine + "Limit the number of conccurrent connections - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function LimitConnections

#Remove any self-signed certificates tied to the RDP listener
function RDPCert () {
    if ((Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').Property -contains 'SSLCertificateSHA1Hash')
{
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name SSLCertificateSHA1Hash -Force
}
}
Write-Host ($writeEmptyLine + "Remove any self-signed certificates tied to the RDP listener - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function RDPCert

<#----------------------------------------Configure Windows Firewall rules---------------------------#>

#Turn on Windows Firell an the three profiles (domain,standard and public)
function Firewall () {
    Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True | Out-Null
}
Write-Host ($writeEmptyLine + "Turn on Windows Firell an the three profiles (domain,standard and public) - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function Firewall

#Allow WindowsRM through firewall profiles and enable the PowerShell remote service

function PSRemoteWinrm () {
    Enable-PSRemoting -Force
    Set-NetFirewallRule -Name WINRM-HTTP-In-TCP, WINRM-HTTP-In-TCP-PUBLIC -Enabled True
}
Write-Host ($writeEmptyLine + "Allow WindowsRM through firewall profiles and enable the PowerShell remote service - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function PSRemoteWinrm


#Enable firewall rule to allow the RDP traffic
function allowRDP() {
    Set-NetFirewallRule -Group '@FirewallAPI.dll,-28752' -Enabled True
}
Write-Host ($writeEmptyLine + "Enable firewall rule to allow the RDP traffic - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
Export-ModuleMember -Function  allowRDP

#Enable rule for file and printer sharing so the VM can respond go ping requests inside the virtual network
function ICMP4 () {
    Set-NetFirewallRule -Name FPS-ICMP4-ERQ-In -Enabled True | Out-Null
}
Write-Host ($writeEmptyLine + "ICMP allowed trough Windows Firewall for IPv4 and IPv6" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
Export-ModuleMember -Function ICMP4


#Create a rule for Azure Platform network

function AzurePlatform () {
    New-NetFirewallRule -DisplayName AzurePlatform -Direction Inbound -RemoteAddress 168.63.129.16 -Profile Any -Action Allow -EdgeTraversalPolicy Allow
    New-NetFirewallRule -DisplayName AzurePlatform -Direction Outbound -RemoteAddress 168.63.129.16 -Profile Any -Action Allow
}
Write-Host ($writeEmptyLine + "Create a rule for Azure Platform network Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
Export-ModuleMember -Function AzurePlatform

<#-------------------------------------Verify the VM---------------------------------------------------#>

#To make sure the disk is healthy and consistent, check the disk at the next VM restart

function Chdsk () {
    chkdsk.exe /f
}
Export-ModuleMember -Function Chdsk

#Set the Boot Configuration Data (BCD) settings
function BCD () {
  
bcdedit.exe /set "{bootmgr}" integrityservices enable
bcdedit.exe /set "{default}" device partition=C:
bcdedit.exe /set "{default}" integrityservices enable
bcdedit.exe /set "{default}" recoveryenabled Off
bcdedit.exe /set "{default}" osdevice partition=C:
bcdedit.exe /set "{default}" bootstatuspolicy IgnoreAllFailures

#Enable Serial Console Feature
bcdedit.exe /set "{bootmgr}" displaybootmenu yes
bcdedit.exe /set "{bootmgr}" timeout 5
bcdedit.exe /set "{bootmgr}" bootems yes
bcdedit.exe /ems "{current}" ON
bcdedit.exe /emssettings EMSPORT:1 EMSBAUDRATE:115200
}
Write-Host ($writeEmptyLine + "BCD settings - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
Export-ModuleMember BCD

#The dump log can be helpful in troubleshooting Windows crash issues. Enable the dump log collection:

function Dump () {
#Set up the guest OS to collect a kernel dump on an OS crash event
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name CrashDumpEnabled -Type DWord -Force -Value 2
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name DumpFile -Type ExpandString -Force -Value "%SystemRoot%\MEMORY.DMP"
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name NMICrashDump -Type DWord -Force -Value 1
}
Write-Host ($writeEmptyLine + "Enable the dump log collection - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
Export-ModuleMember -Function Dump

# Set up the guest OS to collect user mode dumps on a service crash event
function GuestOSDump () {
$key = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps'
if ((Test-Path -Path $key) -eq $false) {(New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' -Name LocalDumps)}
New-ItemProperty -Path $key -Name DumpFolder -Type ExpandString -Force -Value 'C:\CrashDumps'
New-ItemProperty -Path $key -Name CrashCount -Type DWord -Force -Value 10
New-ItemProperty -Path $key -Name DumpType -Type DWord -Force -Value 2
Set-Service -Name WerSvc -StartupType Manual
}
Write-Host ($writeEmptyLine + "Windows Error Reporting - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
Export-ModuleMember -Function GuestOSDump

#Verify that the Windows Management Instrumentation (WMI) repository is consistent:
function RepoCheck () {
    winmgmt.exe /verifyrepository
}

Write-Host ($writeEmptyLine + "Repocheck - Done." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
Export-ModuleMember -Function RepoCheck
