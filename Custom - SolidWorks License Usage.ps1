param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Servername
)

$scriptblock = {
    function Get-FlexLMUsage {
        param(
            [Parameter(Mandatory=$true)]
            [string]$LogFile
        )
        $Log = Get-Content $LogFile -ErrorAction Stop
        $deDate = ""

        $Log | ForEach-Object {
            if ($_ -match '.* TIMESTAMP (.*)') {
                $Date = $matches[1]
                $dateParts = $Date -split "/"
                $deDate = "$($dateParts[1]).$($dateParts[0]).$($dateParts[2])"
            } elseif ($_ -match '(\d+:\d+:\d+)\s\((.*)\)\s(OUT|IN):\s"(.*)"\s(.*)@(.*)') {
                [PSCustomObject]@{
                    DateTime     = Get-Date ('{0} {1}' -f $deDate, $Matches[1])
                    Server       = $Matches[2]
                    Action       = $Matches[3]
                    License      = $Matches[4]
                    UserName     = $Matches[5].Trim()
                    ComputerName = $Matches[6].Trim()
                }
            }
        }
    }

    function Get-FlexLmServices {
        $FlexLMBaseKey = 'HKLM:\SOFTWARE\WOW6432Node\FLEXlm License Manager'
        
        if (Test-Path $FlexLMBaseKey) {
            Get-ChildItem $FlexLMBaseKey | ForEach-Object { 
                $RegProperties = Get-ItemProperty $_.PSPath
                $WMIService = Get-CimInstance -ClassName Win32_Service | Where-Object { $_.PathName -like '*lmgrd*' }

                [PSCustomObject]@{
                    ServiceName    = $_.Name
                    LicensePath    = $RegProperties.License
                    LicenseExists  = Test-Path $RegProperties.License
                    LogFilePath    = $RegProperties.lmgrd_log_file
                    ServicePath    = $RegProperties.lmgrd
                    Service        = {if ($WMIService.Name) { Get-Service -Name $WMIService.Name }}
                    ServiceProcess = {if ($WMIService.ProcessId) { Get-Process -Id $WMIService.ProcessId }}
                }
            }
        } else {
            Write-Error "No FLEXlm License Manager Found"
        }
    }

    $result = Get-FlexLMUsage -LogFile ((Get-FlexLmServices).LogFilePath) | Sort-Object -Property DateTime
	# If you aditionally want to export the license usage to a specific folder, just uncomment the following two lines.
	# $filename = "C:\LicenseUsage\lmgrd_log_analyze_" + (get-date).ToString("yyyyMMdd_HHmmss") + ".csv"
	# $result | Export-Csv -LiteralPath $filename -NoClobber -Encoding UTF8 -Delimiter ";"

    $ProductUsage = @{}
	# Initialize $ProductUsage
    $result.License | Sort-Object -Unique | ForEach-Object {
        $ProductUsage[$_] = 0
    }

	#  Some productUsage driven simple calculations
    $result | ForEach-Object {
        $ProductUsage[$_.License] += if ($_.Action -eq "OUT") { 1 } elseif ($_.Action -eq "IN") { -1 } else { 0 }
    }

	# Output the usage as an xml file for prtg
    "<prtg>"
    foreach ($key in $ProductUsage.Keys) {
        "<result>"
        "<channel>$key</channel>"
        "<value>$($ProductUsage[$key])</value>"
        "</result>"
    }
    "</prtg>"
}

Invoke-Command -ScriptBlock $scriptblock -ComputerName $Servername
