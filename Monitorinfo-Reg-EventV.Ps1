$DCRegParentPath = 'HKLM:SYSTEM\CurrentControlSet\Control\DeviceContainers'
$DisplayValueObj = @()
$FinalObj = @()
$DevContainersRegDetails = Get-ChildItem -Path $DCRegParentPath
$DevContainersRegDetails | ForEach-Object {
    $DevContainersReg = $_.PSChildName
    $DisplayDetails = Get-Item -Path "$DCRegParentPath\$DevContainersReg\BaseContainers\$DevContainersReg" | Where-Object {$_.Property -like '*Display*'}
    $DisplayDetails | ForEach-Object {
        $DisplayDetail = $_
        $DisplayValues = [PSCustomObject]@{
            GUID = (($DisplayDetail.Name).Split("\"))[-1]
            Model = (($DisplayDetail.Property | Where-Object {$_ -like 'Display*'}).Split("\"))[1]
        }
        $DisplayValueObj += $DisplayValues
    }
}
$DisplayValueObj | ForEach-Object {
    $CurrentValue = $_
    $EventVwrLogs = $null
    $EventVwrLogs = Get-WinEvent -LogName Microsoft-Windows-DeviceSetupManager/Admin | Where-Object {$_.ID -eq 112 -and $_.Message -like "*$($CurrentValue.GUID)*"}
    if ($EventVwrLogs){
        $FinalOutput = [PSCustomObject]@{
            Registry_GUID = $CurrentValue.GUID
            Registry_Model = $CurrentValue.Model
            EventViewer_Message =  $EventVwrLogs.Message
            EventViewer_Date = $EventVwrLogs.TimeCreated
        
        }
        $FinalObj += $FinalOutput
    }
}
$FinalObj | Select-Object Registry_GUID,Registry_Model, @{n="EventViewer_Message";e={$_.EventViewer_Message -join ";"}}, @{n="EventViewer_Date";e={$_.EventViewer_Date -join ";"}}
#| Export-Csv -Path "C:\Users\hkaka\Desktop\Tasks\Output.csv" -NoTypeInformation -Force
