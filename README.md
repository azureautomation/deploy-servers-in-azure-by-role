Deploy Servers In Azure By Role
===============================

            

*This is an example script that I have used for my blog at [lastwordinnerd.com](http://lastwordinnerd.com/blog/).  It is part of an ongoing series as I build my Azure environment to deploy VMs based on my pre-determined
 scenario requirements.  Enjoy!*


Over the last couple of weeks, we’ve taken our simple Azure [VM creation script](http://lastwordinnerd.com/2015/03/25/powershell-automating-server-builds-in-azure-pt-1-basic-builds/) and [expanded its versatility](http://lastwordinnerd.com/2015/04/01/powershell-automating-server-builds-in-azure-pt-2-rolling-servers-based-on-role/) to support standardization in an automated fashion.  Now  we’re going to add some finishing touches to make this a function that includes some scalability and added functionality before we turn our eyes towards
 the DSC portion of our role-based deployments.


Of course, because of some of the functionality that we’ll be adding in the script, we’re going to be jettisoning that baby stuff that was New-AzureQuickVM in favor of New-AzureVM.  New-AzureVM offers us a lot more flexibility to build
 our VMs, including the ability to statically assign an IP address during the configuration.  So to wrap up this portion of our Azure exploration, we’ll be:


  *  Adding logic to verify that your Azure account token is valid. 
  *  Checking the predefined subnets’ address pools for available addresses and assigning them to the machine

  *  Adding logic to deploy multiple VMs for a given role simultaneously. 
  *  Adding in our comment-based help and building our script into a function. 

First step, let’s add in our comment-based help.  Aside from it being a [community best-practice](https://www.penflip.com/powershellorg/the-community-book-of-powershell-practices/blob/master/doc-01-write-comment-based-help.txt),
 it’s helpful to whomever you’re intending to use this script to understand what it is you’ve created and how it works.  So in it goes.


![Image](https://github.com/azureautomation/deploy-servers-in-azure-by-role/raw/master/AzurePt3-1.jpg)


We’ll go ahead and call this function New-AzureRoleDeployment.  Along with adding the block to set this as a function, we’re going to go ahead and leverage the Begin, Process, and End blocks as well.  The bulk of our previously existing
 script will reside in the Process block.  In the Begin block, I’m going to add some code to verify that there is an Azure Account configured for the PowerShell instance, and to execute the Add-AzureAccount cmdlet if no Azure account is signed in.
  I’m using Get-AzureService to verify that the account’s authentication token is current, because Get-AzureAccount doesn’t give up that information.  Get-AzureService will throw a list of exceptions if it’s not current.


***NOTE*** - I was previously using Get-AzureSubscription, but found that this didn't provide a consistent result.  I've updated the script to reflect the use of Get-AzureService instead.


 

 

We’ll also add in a quick Write-Verbose message in the End block to state that the function finished.  We could omit the End block altogether, or use it to clean up our login with the Remove-AzureAccount cmdlet,
 but depending on how you’ve set up your Azure account on the system, you could wind up creating more work for yourself after running this function.  I’d recommend doing some reading up on [how the Remove-AzureAccount cmdlet](https://msdn.microsoft.com/en-us/library/dn722529.aspx) works before deciding if it’s something you want to add.


Now let’s do some modifications to the script to allow us to add a number of systems instead of a single system at a time.  This is going to require us to work with one of my favorite PowerShell features –
 math!  First, let’s update our parameter block with a Quantity parameter to input.



Now, we’ll find our original code for creating the numbering portion of our server names.



We’re going to modify this code by changing the ServerNumber variable to FirstServer.  To make this easier, I use the Replace function in ISE (CTRL + H) to change all of the references to ServerNumber at once.  Next,
 we need to figure out the last server in the series.  Logically, you would think that this would just be the Quantity variable, plus the FirstServer.  However, this doesn’t work exactly as expected.  For example, if we create a CountInstance
 variable, craft it like so, and execute:



We get a return of 0, because the cloud service doesn’t currently exist.  Now, so we don’t start at 0 or the highest allocated number for our server number series, we have to do this:



And if we execute our two lines of code, then the FirstServer variable will equal 1.  Now, we’ll go ahead and create a Quantity variable with the value of 3 and add the FirstServer and Quantity together.



Now, if we check the LastServer variable, we get a value of 4.  Now the problem comes up when we array it:



We get the following array of values in the Range variable.


 


![Image](https://github.com/azureautomation/deploy-servers-in-azure-by-role/raw/master/AzurePt3-4.jpg)


So now, while we’ve requested 3 machines, our logic will tell PowerShell to build 4.  So we instead rectify it by subtracting a number from the Quantity like so:


 

![Image](https://github.com/azureautomation/deploy-servers-in-azure-by-role/raw/master/AzurePt3-5.jpg)

 


And now we have the appropriate range.  Next, we’re going to add a new switch block under our existing one to help set us up for assigning a static address in the subnet that the new systems will be assigned in.  So first let’s create
 the block with the output variable VNet:


 

Notice that I’m using the same purpose parameter.  No sense in requiring our user to enter information needlessly when we can pull it from a single source.

 


Because of how we need to craft our command to build a VM with the New-AzureVM cmdlet (you’ll see in a minute), we can no longer use a single argument list as before.  So instead we’re going to take what we had before…


 

…and we’re going to update it like so:


Now we’re going to use our VNet switch to test the subnet, check the available addresses, and get the first one available to assign.  Also, I’m adding in some Write-Verbose statements so I can verify that the variables
 that I need to have created are actually being generated by my script.



As before, we’re going to use the presence of the Availability parameter to determine our path here.  The biggest change will be with our actual creation command.  Instead of a quick one-liner, we’ll instead
 be moving through the pipe, creating a new VM configuration object, adding the necessary information, assigning the static IP, and finally kicking off the build.



The process is repeated for the Else statement in the event that the Availability parameter is not selected.



Now we’ll go ahead and execute our new code to create three new VMs destined to be print servers.



![Image](https://github.com/azureautomation/deploy-servers-in-azure-by-role/raw/master/AzurePt3-6.jpg)


 


Success!  Now we can deploy any number of servers to our designated subnets, configure them with a statically assigned IP Address, and assign them to an availability group off of a simple one-liner!  Now I’m off to do some more reading and
 research on Desired State Configuration so we can continue our automated deployment track!


        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
