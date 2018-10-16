Function ParseOSInfo($sysinfo) {
    #Parse Server Name
    $serverstring = ($sysinfo | Select-String "Output of Server: ").ToString(); $parserpos = $serverstring.IndexOf(":")
    $servername = ($serverstring.Substring($parserpos+1)).TrimStart()

    #Parse OS Family
    $osfamilystring = ($sysinfo | Select-String "Distributor ID: ").ToString(); $parserpos = $osfamilystring.IndexOf(":")
    $osfamily = ($osfamilystring.Substring($parserpos+1)).TrimStart(); $osfamily = $osfamily.Replace('"','')


    #Parse OS version
    if ($osfamily -like "Ubuntu*") {
        $osname = $osfamily
    }
    else {
        $osnamestring = ($sysinfo | Select-String "Description: ").ToString(); $parserpos = $osnamestring.IndexOf(":")
        $osname = ($osnamestring.Substring($parserpos+1)).TrimStart(); $osname = $osname.Replace('"','')
    }

    #Parse current functional level
    $patchlvlstr = ($sysinfo | Select-String "Current Patch Level: ").ToString(); $parserpos = $patchlvlstr.IndexOf(":")
    $patchlvl = ($patchlvlstr.Substring($parserpos+1)).TrimStart(); $patchlvl = $patchlvl.Replace('"','')

    #Parse OS Arch
    if ($patchlvl -like "*64") {$osarch = "64 bit"}
    elseif ($patchlvl -like "*86") {$osarch = "32 bit"}
    else {$osarch = "NA"}

    #Parse current release version
    $releaseinfostr  = ($sysinfo | Select-String "Release: ").ToString(); $parserpos = $releaseinfostr.IndexOf(":")
    $releaseinfo = ($releaseinfostr.Substring($parserpos+1)).TrimStart(); $releaseinfo = $releaseinfo.Replace('"','')

    #Parse Computer Model
    $modelstr  = ($sysinfo | Select-String "Product Name: ").ToString(); $parserpos = $modelstr.IndexOf(":")
    $model = ($modelstr.Substring($parserpos+1)).TrimStart(); $model = $model.Replace('"','')

    #Parse Domain
    $domainnamestr  = ($sysinfo | Select-String "System Domain Name: ").ToString(); $parserpos = $domainnamestr.IndexOf(":")
    $domainname = ($domainnamestr.Substring($parserpos+1)).TrimStart(); $domainname = $domainname.Replace('"','')

    #Parse CPU
    $cpucount = ([regex]::Matches($sysinfo,"processor	: ")).Count
    $cpumodelarr  = $sysinfo | Select-String "model name	: "
    $cpumodelstr = $cpumodelarr[0].Line; $parserpos = $cpumodelstr.IndexOf(":")
    $cpumodel = ($cpumodelstr.Substring($parserpos+1)).TrimStart(); $cpumodel = $cpumodel.Replace('"','')
    $cpuhzarr  = $sysinfo | Select-String "cpu MHz		: "
    $cpuhzstr = $cpuhzarr[0].Line; $parserpos = $cpuhzstr.IndexOf(":")
    $cpuhz = ($cpuhzstr.Substring($parserpos+1)).TrimStart(); $cpuhz = $cpuhz.Replace('"','') ; $cpuhz = [int]$cpuhz
    $cpuarcharr  = $sysinfo | Select-String "address width	: "
    $cpuarchstr = $cpuarcharr[0].Line; $parserpos = $cpuarchstr.IndexOf(":")
    $cpuarch = ($cpuarchstr.Substring($parserpos+1)).TrimStart(); $cpuarch = $cpuarch.Replace('"','') ; $cpuarch = $cpuarch + " bit"

    #Parse memory
    $memorystr  = ($sysinfo | Select-String "MemTotal:        ").ToString(); $parserpos = $memorystr.IndexOf(":")
    $totalmem = ($memorystr.Substring($parserpos+1)).TrimStart(); $totalmem = $totalmem.Replace('"',''); $totalmem = $totalmem.Replace(" kB","")
    $totalmem = [int]$totalmem ; $totalmem = [math]::Round($totalmem/1024,0)

    #Parse Disks
    $diskcount = ([regex]::Matches($sysinfo,"filesystem: ")).count
    $diskarr = $sysinfo | Select-String "1kb_blocks: "
    foreach ($diskline in $diskarr) {
        $diskstr = $diskline.Line; $parserpos = $diskstr.IndexOf(":")
        $disksize = ($diskstr.Substring($parserpos+1)).TrimStart()
        [int]$totaldisksize += $disksize
    }
    $totaldisksize = [math]::Round($totaldisksize/1024/1024,0)

    #Parse Network Cards
    $nicarr = $sysinfo | Select-String "Adapter Name: "
    $niccount = ($nicarr | Where-Object {$_ -notlike "*lo*"}).Count
    if ($niccount -eq "0") {$niccount = "NA"}

    Write-Sysinfocsv $servername $model $osfamily $osname $patchlvl $domainname $osarch $cpuarch $cpucount $cpuhz $cpumodel $totalmem $diskcount $totaldisksize $niccount
}

Function ParsePkgInfo($OutputPath) {
    $pkgoutputfiles = (Get-ChildItem -Path $OutputPath -Include cloudmo*.packages.csv -Recurse).FullName
    $pathlength = $OutputPath.Length
    foreach ($file in $pkgoutputfiles) {
    $servername = $file.Substring($pathlength) ; $servername = $servername.Replace(".packages.csv","") ; $servername = $servername.Replace("\","")
        Import-Csv $file | ForEach-Object {
            Write-Packagecsv $servername $_.name $_.version
        }
    }
}

Function Write-Sysinfocsv($servername,$model,$osfamily,$osname,$patchlvl,$domainname,$osarch,$cpuarch,$cpucount,$cpuhz,$cpumodel,$totalmem,$diskcount,$totaldisksize,$niccount) {
    #Building Object for system information
    $configentry = New-Object Object;
    $configentry | Add-Member -MemberType:NoteProperty -Name:"Name" -Value $servername
    $configentry | Add-Member -MemberType:NoteProperty -Name:"Computer Model" -Value $model
    $configentry | Add-Member -MemberType:NoteProperty -Name:"OS Family" -Value $osfamily
    $configentry | Add-Member -MemberType:NoteProperty -Name:"Operating System (OS)" -Value $osname
    $configentry | Add-Member -MemberType:NoteProperty -Name:"Service Pack" -Value $patchlvl
    $configentry | Add-Member -MemberType:NoteProperty -Name:"Domain/Workgroup" -Value $domainname
    $configentry | Add-Member -MemberType:NoteProperty -Name:"OS Arch" -Value $osarch
    $configentry | Add-Member -MemberType:NoteProperty -Name:"CPU Arch" -Value $cpuarch
    $configentry | Add-Member -MemberType:NoteProperty -Name:"# CPUs" -Value $cpucount
    $configentry | Add-Member -MemberType:NoteProperty -Name:"CPU (MHz)" -Value $cpuhz
    $configentry | Add-Member -MemberType:NoteProperty -Name:"CPU Type" -Value $cpumodel
    $configentry | Add-Member -MemberType:NoteProperty -Name:"Mem (MB)" -Value $totalmem
    $configentry | Add-Member -MemberType:NoteProperty -Name:"# Disks" -Value $diskcount
    $configentry | Add-Member -MemberType:NoteProperty -Name:"Total Disk Size (GB)" -Value $totaldisksize
    $configentry | Add-Member -MemberType:NoteProperty -Name:"# NICs" -Value $niccount
    $global:sysinforesults += $configentry
}

Function Write-Packagecsv ($servername,$name,$version) {
    $configentry = New-Object Object;
    $configentry | Add-Member -MemberType:NoteProperty -Name:"Server Name" -Value $servername
    $configentry | Add-Member -MemberType:NoteProperty -Name:"Application Name" -Value $name
    $configentry | Add-Member -MemberType:NoteProperty -Name:"Application Version" -Value $version
    $global:pkginforesults += $configentry
}

#Initiating Variables
$global:sysinforesults = @();
$global:pkginforesults = @();
$OutputPath = "D:\ajkundna\Downloads\LabKeys"
$outputsyscsv = $OutputPath + "\LinuxSysOutput.csv"
$outputpkgcsv = $OutputPath + "\LinuxPkgOutput.csv"
$sysoutputfiles = (Get-ChildItem -Path $OutputPath -Include cloudmo*.sysinfo.txt -Recurse).FullName

foreach ($file in $sysoutputfiles) {
    $sysinfo = Get-Content $file
    ParseOSInfo $sysinfo
}

ParsePkgInfo $OutputPath

$global:sysinforesults | Export-Csv $outputsyscsv -NoTypeInformation
$global:pkginforesults | Export-Csv $outputpkgcsv -NoTypeInformation