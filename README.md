![GitHub](https://img.shields.io/github/license/microsoft/ARI)  [![Azure](https://badgen.net/badge/icon/azure?icon=azure&label)](https://azure.microsoft.com)

<br/>


# Prepare VHD for Windows Azure VM

Set Windows configurations for Azure to prepare a Windows VHD from on-prem to create Azure Windows VM.

This project is intend to help Cloud Admins and anyone that might need an easy and fast way to prepare a VHD to create a Windows Azure VM.

<br/>

# Description 

Before you upload a Windows virtual machine (VM) from on-premises to Azure, you must prepare the virtual hard disk (VHD or VHDX). Azure supports both generation 1 and generation 2 VMs that are in VHD file format and that have a fixed-size disk. The script must run before you are going to start the Sysprep. The maximum size allowed for the OS VHD on a generation 1 VM is 2 TB.

You can convert a VHDX file to VHD, convert a dynamically expanding disk to a fixed-size disk, but you can't change a VM's generation. For more information, see https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/Should-I-create-a-generation-1-or-2-virtual-machine-in-Hyper-V and https://docs.microsoft.com/en-us/azure/virtual-machines/generation-2

For information about the support policy for Azure VMs, see https://docs.microsoft.com/en-US/troubleshoot/azure/virtual-machines/server-software-support

The instructions in this article apply to:

The 64-bit version of Windows Server 2008 R2 and later Windows Server operating systems. For information about running a 32-bit operating system in Azure, https://docs.microsoft.com/en-US/troubleshoot/azure/virtual-machines/support-32-bit-operating-systems-virtual-machines 
If any Disaster Recovery tool will be used to migrate the workload, like Azure Site Recovery or Azure Migrate, this process is still required on the Guest OS to prepare the image before the migration.

Before you will run the script, install the Azure Virtual Machine Agent https://go.microsoft.com/fwlink/?LinkID=394789  Then you can enable VM extensions. The VM extensions implement most of the critical functionality that you might want to use with your VMs. 


🔧 Technologies & Tools
 
![](https://img.shields.io/badge/OS-Windows-informational?style=flat&logo=Microsoft&logoColor=white&color=2bbc8a) ![](https://img.shields.io/badge/Code-VisualStudioCode-informational?style=flat&logo=VisualStudioCode&logoColor=white&color=2bbc8a)  ![](https://img.shields.io/badge/Code-PowerShell-informational?style=flat&logo=PowerShell&logoColor=white&color=2bbc8a) ![](https://img.shields.io/badge/Cloud-MicrosoftAzure-informational?style=flat&logo=MicrosoftAzure&logoColor=white&color=2bbc8a) ![](https://img.shields.io/badge/platform-windows%20%-lightgrey)


# Author

- [Twitter @AndreiPintica](https://twitter.com/AndreiPintica)
- [Linkedin](https://linkedin.com/in/andreipintica)

