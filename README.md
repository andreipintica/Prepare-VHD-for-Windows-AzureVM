![GitHub](https://img.shields.io/github/license/microsoft/ARI)  [![Azure](https://badgen.net/badge/icon/azure?icon=azure&label)](https://azure.microsoft.com) [![Windows Server 2008 R2 | 2012 R2 | 2016 | 2019 | 2022](https://img.shields.io/badge/Windows%20Server-2008%20R2%20|%202012%20R2%20|%202016%20|%202019%20|%202022-007bb8.svg?logo=Windows)](#)
![PowerShell 7](https://img.shields.io/badge/PowerShell-7-blue)

<br/>

# Prepare VHD for Windows Azure VM

Set Windows configurations for Azure to prepare a Windows VHD from on-prem to create Azure Windows VM. If you are loading the powershell module file with elevated permissions from PowerShell, you will see that the script will perform those tasks for you, without running manually all the functions. If you don't run the script with priviliged rights, the script will exit.

# Description 

Before you upload a Windows virtual machine (VM) from on-premises to Azure, you must prepare the virtual hard disk (VHD or VHDX). Azure supports both generation 1 and generation 2 VMs that are in VHD file format and that have a fixed-size disk. The script must run before you are going to start the Sysprep. The maximum size allowed for the OS VHD on a generation 1 VM is 2 TB.

You can convert a VHDX file to VHD, convert a dynamically expanding disk to a fixed-size disk, but you can't change a VM's generation. For more information, see https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/Should-I-create-a-generation-1-or-2-virtual-machine-in-Hyper-V and https://docs.microsoft.com/en-us/azure/virtual-machines/generation-2

For information about the support policy for Azure VMs, see https://docs.microsoft.com/en-US/troubleshoot/azure/virtual-machines/server-software-support

The instructions in this article apply to:

The 64-bit version of Windows Server 2008 R2 and later Windows Server operating systems. For information about running a 32-bit operating system in Azure, https://docs.microsoft.com/en-US/troubleshoot/azure/virtual-machines/support-32-bit-operating-systems-virtual-machines 
If any Disaster Recovery tool will be used to migrate the workload, like Azure Site Recovery or Azure Migrate, this process is still required on the Guest OS to prepare the image before the migration.

Before you will run the script, install the Azure Virtual Machine Agent https://go.microsoft.com/fwlink/?LinkID=394789  Then you can enable VM extensions. The VM extensions implement most of the critical functionality that you might want to use with your VMs. 

# What is this automated process
This automated process is actually a powershell module.

# Why this automated process was created
This project is intend to help Cloud Admins and anyone that might need an easy and fast way to prepare a VHD to create a Windows Azure VM.

# How to run it?
Example of how to run the module: .\Prepare-VHD-for-Windows-AzureVM.psm1 

# How to import-module
Copy the folder to C:\localuser\documents\PowerShell\Modules

``Import-Module -Name c:\temp\Prepare-VHD-for-Windows-AzureVM -Verbose`` 

**Note:** Using the Verbose parameter causes Import-Module to report progress as it loads the module. Without the Verbose, PassThru, or AsCustomObject parameter, Import-Module does not generate any output when it imports a module.

# PowerShell module functions explained

1. Set Windows configurations for Azure


- **function SfcFix** - The System File Checker (SFC) is used to verify and replace Windows system files.
- **RemovePersistentRoutes** - Remove all persistent routes.
- **RemoveProxy** - Remove the WinHTTP proxy.
- **SetSanPolicy** - Set the disk SAN policy to [**Onlineall**](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/gg252636(v=ws.11)#parameters). 
- **UTC** - Set Coordinated Universal Time (UTC).
- **PowerProfile** - Set power profile to high performance.
- **Temp** - Set TMP and TEMP to default values.

2. Check the Windows Services 

- **WindowsServices** - Check Windows Services

3. Update remote desktop registry settings

- **EnableRDP** - Enable Remote Desktop Protocol.
- **DefaultRDP** - The RDP port is set up correctly using the default port of 3389. 
- **RDPListener** - The listener is listening on every network interface.
- **NLA** - Configure network-level authentication (NLA) mode for the RDP connections.
- **KeepAlive** - Set the keep-alive value.
- **Reconnect** - Set the reconnect options.
- **LimitConnections** - Limit the number of concurrent connections.
- **RDPCert** - Remove any self-signed certificates tied to the RDP listener.

4. Configure Windows Firewall rules

- **Firewall** - Turn on Windows Firell an the three profiles (domain,standard and public).
- **PSRemoteWinrm** - Allow WindowsRM through firewall profiles and enable the PowerShell remote service.
- **allowRDP** - Enable firewall rule to allow the RDP traffic.
- **ICMP4** - Enable the rule for file and printer sharing so the VM can respond to ping requests inside the virtual network.
- **AzurePlatform** - Create a rule for Azure Platform network to accept the Wire IP Server.

5. Verify the VM

- **Chdsk** - To make sure the disk is healthy and consistent, check the disk at the next VM restart. You will need to perform manually the restart operation.
- **BCD** - Set the Boot Configuration Data (BCD) settings and enable the serial console feature.
- **Dump** - The dump log can be helpful in troubleshooting Windows crash issues. Enable the dump log collection.
- **GuestOSDump** - Set up the guest OS to collect user mode dumps on a service crash event.
- **RepoCheck** - Verify that the Windows Management Instrumentation (WMI) repository is consistent. If the repository is corrupted, see WMI: [Repository corruption or not](https://techcommunity.microsoft.com/t5/ask-the-performance-team/wmi-repository-corruption-or-not/ba-p/375484)

To upload a Windows VHD that's a domain controller:

Follow [these extra steps](https://support.microsoft.com/kb/2904015) to prepare the disk.

Make sure you know the Directory Services Restore Mode (DSRM) password in case you ever have to start the VM in DSRM. For more information, see [Set a DSRM password](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc754363(v=ws.11)).

<br/>


🔧 Technologies & Tools
 
![](https://img.shields.io/badge/OS-Windows-informational?style=flat&logo=Microsoft&logoColor=white&color=2bbc8a) ![](https://img.shields.io/badge/Code-VisualStudioCode-informational?style=flat&logo=VisualStudioCode&logoColor=white&color=2bbc8a)  ![](https://img.shields.io/badge/Code-PowerShell-informational?style=flat&logo=PowerShell&logoColor=white&color=2bbc8a) ![](https://img.shields.io/badge/Cloud-MicrosoftAzure-informational?style=flat&logo=MicrosoftAzure&logoColor=white&color=2bbc8a) ![](https://img.shields.io/badge/platform-windows%20%-lightgrey)

The script is provided 'as is' and without warranty of any kind. 


## Author

- [Twitter @AndreiPintica](https://twitter.com/AndreiPintica)
- [Linkedin](https://linkedin.com/in/andreipintica)

