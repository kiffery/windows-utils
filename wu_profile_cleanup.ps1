# Author: hjkipke
# Date Modifyed: 06/08/2017
# This script cleans up tempary files, cleans out windows updates downloads, and deletes profiles older than 30 days

# Grabs profiles that have RoamingConfigured set to True
$profiles = Get-WmiObject -Class Win32_UserProfile -Filter "RoamingConfigured='True'"
$Cutoff = (Get-Date).AddDays(-30)
$userpath = "C:\Users\"
$logpath = "C:\tmp\ProfileDel.log"

# Make sure services do not auto start up again automatically
Set-Service wuauserv -StartupType Disabled
Set-Service BITS -StartupType Disabled

# Stop services
Stop-Service wuauserv
Stop-Service BITS

# Delete everything recursivly in specified folders. Anything be used by a process remains
Get-ChildItem -Path "C:\tmp\", "C:\temp\", "C:\Windows\SoftwareDistribution\Download\", "C:\Windows\Temp\" -Recurse -Force -Verbose -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -Verbose -ErrorAction SilentlyContinue 

#create log file
New-Item $logpath -type File

# loop over profiles
foreach ($profile in $profiles) {
    
    # skips any special profiles, not sure if need if all profiles are roaming
    if ($profile.Special -notcontains "False") {
        
        # grabs username and last time somthing was written to user folder
        $name = $Profile.LocalPath.split("\", 2)[1].split("\", 2)[1]
        $lastused = Get-Item $userpath$name | Foreach-Object {$_.LastWriteTime}
        
        # deletes profile and user folder if older than 30 days
        if ($lastused -lt $Cutoff) {
             try {
                 # path deletion
                 Get-ChildItem -Path "$userpath$name\" -Recurse | Remove-Item -Force -Verbose
                 write-output "$lastused`t$name`t`tProfile Delete Successful" | Add-Content $logpath
             } catch {
                 write-output "$lastused`t$name`t`tProfile Delete Failed" | Add-Content $logpath
             }
             try {
                # Profile deletion
                $Profile.Delete()
                Write-Output "$lastused`t$userpath$name`t`tFolder Delete Successful" | Add-Content $logpath
             } catch {
                Write-Output "$lastused`t$userpath$name`t`tFolder Delete Failed" | Add-Content $logpath
             }
        }
    }
}

# Restarts services and sets them back to default. I think GP will override this anyways
Set-Service wuauserv -StartupType Manual
Set-Service BITS -StartupType Manual
Start-Service wuauserv
Start-Service BITS