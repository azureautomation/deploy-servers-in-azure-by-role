<#
.Synopsis
   Deploys servers to Azure.
.DESCRIPTION
   The purpose of this script is to deploy servers to Azure based on pre-designated roles.  With this command, 
   you can deploy multiple servers of a role-type to their designated network segments, and (if so desired) add them to an
   Availability Group.

.EXAMPLE
   
   The following command will deploy 3 VMs to be configured as print (PRT) servers to the subnet designated for print servers
   and add them to an availability group so printing is not interrupted during Azure maintenance windows.

   New-Deployment -Purpose PRT -Quantity 3 -Availability -Verbose

.NOTES
   Created by Will Anderson
   Dated 6-April-2015
   http://lastwordinnerd.com

   This script is provided as-is, no warrenty is provided or implied.
#>

Function New-AzureRoleDeployment{
    [cmdletbinding(SupportsShouldProcess=$true)]
    Param (

        [Parameter(Mandatory=$True)]
        [ValidateSet('IIS','PSWA','PRT','DC')]
        [string]$Purpose,

        [Parameter(Mandatory=$True)]
        [int]$Quantity,

        [switch]$Availability
        )#EndParam

    BEGIN {
        Write-Verbose "Verifying Azure account is logged in."
        Try{
            Get-AzureService -ErrorAction Stop
            }#EndTry

        Catch [System.Exception]{
            Add-AzureAccount
            }#EndCatch
    }#EndBEGIN

    PROCESS {

        Switch ($Purpose){
        'IIS' {$_Purpose = 'IIS'};
        'PSWA' {$_Purpose = 'PSWA'};
        'PRT' {$_Purpose = 'PRT'};
        'DC' {$_Purpose = 'DC'}
        }#Switch

        Switch ($Purpose){
        'IIS' {$VNet = '10.0.0.32'};
        'PSWA' {$VNet = '10.0.0.16'};
        'PRT' {$VNet = '10.0.0.48'};
        'DC' {$VNet = '10.0.0.64'}            

        }#Switch
            
        #Location required for Service Validation.  Configure as a switch at a later date.
        $RootName = "LWIN"
        $ConvServerName = ($RootName + $_Purpose)
        $Location = "West US"

        Write-Verbose "Environment is $_Purpose"
        Write-Verbose "Root name is $RootName"
        Write-Verbose "Service will be $ConvServerName"
        Write-Verbose "Datacenter location will be $Location"
        If($Availability.IsPresent){Write-Verbose "Server will be assigned to $ConvServerName availability group."}

            Try {
            
                Write-Verbose "Checking to see if cloud service $ConvServerName exists."
                Get-AzureService -ServiceName $ConvServerName -ErrorAction Stop 
            
            }#EndTry

            Catch [System.Exception]{
                
                Write-Verbose "Cloud service $ConvServerName does not exist.  Creating new cloud service."
                New-AzureService $ConvServerName -Location $Location
                
            }#EndCatch

            $CountInstance = (Get-AzureVM -ServiceName $ConvServerName).where({$PSItem.InstanceName -like "*$ConvServerName*"}) | Measure-Object
            $FirstServer = ($CountInstance.Count + 1)
            $LastServer = $FirstServer + ($Quantity - 1)
            $Range = $FirstServer..$LastServer

            ForEach ($System in $Range){

                $NewServer = ($ConvServerName + ("{00:00}" -f $System))

                Write-Verbose "Server name $NewServer generated.  Executing VM creation."

                $BaseImage = (Get-AzureVMImage).where({$PSItem.Label -like "*Windows Server 2012 R2 Datacenter*" -and $PSItem.PublishedDate -eq "2/11/2015 8:00:00 AM" })

                #Standard arguments to build the VM  
                $InstanceSize = 'Basic_A1'
                $VNetName = 'YourVNetName'
                $ImageName = $BaseImage.ImageName
                $AdminUserName = 'YourAdminName'
                $Password = 'b0b$yerUncl3'

                $AvailableIP = Test-AzureStaticVNetIP -VNetName $VNetName -IPAddress $VNet
                $IPAddress = $AvailableIP.AvailableAddresses | Select-Object -First 1

                Write-Verbose "Subnet is $VNet"
                Write-Verbose "Image used will be $ImageName"
                Write-Verbose "IPAddress will be $IPAddress"

                If($Availability.IsPresent){
                    
                    Write-Verbose "Availability set requested.  Building VM with availability set configured."
                    
                    Try{
                        
                        Write-Verbose "Verifying if server name $NewServer exists in service $ConvServerName"
                        $AzureService = Get-AzureVM -ServiceName $ConvServerName -Name $NewServer
                            
                            If (($AzureService.InstanceName) -ne $NewServer){

                                New-AzureVMConfig -Name $NewServer -InstanceSize $InstanceSize -ImageName $ImageName -AvailabilitySetName $ConvServerName | 
                                Add-AzureProvisioningConfig -Windows -AdminUsername $AdminUserName -Password $Password | 
                                Set-AzureSubnet -SubnetNames $_Purpose | 
                                Set-AzureStaticVNetIP -IPAddress $IPAddress | 
                                New-AzureVM -ServiceName $ConvServerName -VNetName $VNetName
                            
                            }#EndIf

                            Else {
                            
                                Write-Output "$NewServer already exists in the Azure service $ConvServerName"
                
                            }#EndElse

                    }#EndTry

                    Catch [System.Exception]{
                    
                        $ErrorMsg = $Error | Select-Object -First 1
                        Write-Verbose "VM Creation failed.  The error was $ErrorMsg"
                    
                    }#EndCatch

                }#EndIf

                Else{
                    
                    Write-Verbose "No availability set requested.  Building VM."
                    
                    Try{
                        
                        Write-Verbose "Verifying if server name $NewServer exists in service $ConvServerName"
                        $AzureService = Get-AzureVM -ServiceName $ConvServerName -Name $NewServer
                        
                        If (($AzureService.InstanceName) -ne $NewServer){
                            New-AzureVMConfig -Name $NewServer -InstanceSize $InstanceSize -ImageName $ImageName | 
                            Add-AzureProvisioningConfig -Windows -AdminUsername $AdminUserName -Password $Password | 
                            Set-AzureSubnet -SubnetNames $_Purpose | 
                            Set-AzureStaticVNetIP -IPAddress $IPAddress | 
                            New-AzureVM -ServiceName $ConvServerName -VNetName $VNetName
                        }#EndIf

                        Else {
                        
                            Write-Output "$NewServer already exists in the Azure service $ConvServerName"
                        
                        }#EndElse

                    }#EndTry

                    Catch [System.Exception]{
                    
                        $ErrorMsg = $Error | Select-Object -First 1
                        Write-Verbose "VM Creation failed.  The error was $ErrorMsg"
                    
                    }#EndCatch
                }#EndElse
            
            }#EndForEach
    
    }#EndPROCESS
    
    END {
        Write-Verbose "New-Deployment tasks completed."    
            }#EndEND

}#EndFunctionNew-AzureRoleDeployment