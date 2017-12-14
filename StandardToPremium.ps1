$ResourceGroupName = "PremCpyTestRG"
$VirtualMachineName = "PremCpyTest"
$PremiumStorageAcctName = "premstrgdest3"
$PremiumStorageAcctLocation = "East US"
$PremiumStorageAcctType = "Premium_LRS"

#Azure Login
Login-AzureRMAccount

#Stop VM
Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName

#Get VM
$VM = Get-AzureRMVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName

#Create Destination Premium Storage Account
New-AzureRMStorageAccount -ResourceGroupName $ResourceGroupName -Name $PremiumStorageAcctName -Location $PremiumStorageAcctLocation -Type $PremiumStorageAcctType

#Get Source Storage Account Info
$SAsubstring = $VM.StorageProfile.DataDisks[0].Vhd.Uri.Split('.')[0]
$SourceStorageAccountName = $SAsubstring.Substring(8,$SAsubstring.Length-8)
$SourceStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $SourceStorageAccountName).Key1
$SourceStorageAccountURI = "https://" + $SourceStorageAccountName + ".blob.core.windows.net/vhds/"

#Get Destination Storage Account
$DestSA = Get-AzureRMStorageAccount -Name $PremiumStorageAcctName -ResourceGroupName $ResourceGroupName
$DestSAKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $PremiumStorageAcctName).Key1
$DestSAURI = "https://" + $DestSA.StorageAccountName + ".blob.core.windows.net/vhds/"

#Create an array to store the disk names
$DiskNames = New-Object System.Collections.ArrayList
$DiskCacheType = New-Object System.Collections.ArrayList

#Copy each disk from the source account to the destination account and then add to the disk name array
foreach($disk in $VM.StorageProfile.DataDisks)
{
    "Copying Disk: " + $disk.Name
    $command = "AzCopy /Source:" + $SourceStorageAccountURI + " /SourceKey:" + $SourceStorageAccountKey + " /Dest:" +
    $DestSAURI + " /DestKey:" + $DestSAKey + " /Pattern:" + $disk.Name
    Invoke-Expression -Command:$command

    $DiskNames.Add($disk.Name)
    $DiskCacheType.Add($disk.Caching)
}

#Detach Existing Disks
Remove-AzureRMVMDataDisk -VM $VM -DataDiskNames $DiskNames
Update-AzureRmVM -VM $VM -ResourceGroupName $ResourceGroupName

#Attach New Premium Disks
for($i=0; $i -le $DiskNames.Count-1;$i++)
{
    Add-AzureRmVMDataDisk -VM $VM -Name $DiskNames[$i] -Caching $DiskCacheType[$i] -DiskSizeInGB 1023 -Lun $i -VhdUri ($DestSAURI + $DiskNames[$i]) -CreateOption Attach -Verbose
}
Update-AzureRmVM -VM $VM -ResourceGroupName $ResourceGroupName

#Start the VM
Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName

