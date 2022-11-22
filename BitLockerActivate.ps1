#Sets up logging with function to add desired timestamped text
mkdir #Put the location you'd like to store logs here, or delete this line if you already have a logging location set up.
New-Item #Use this to create the log itself with the full path. Ex: C:\Logs\BitLockerActivate.log
$Logfile = "PATH TO LOGFILE"
function Write-Log
    {
        Param ([string]$LogString)
        $Stamp = (Get-Date).toString("dd/MM/yyyy HH:mm:ss")
        $LogMessage = "$Stamp $LogString"
        Add-content $LogFile -value $LogMessage
    }

#Creates counting variables to track loops, successes and failures
$Count = 0
$Status = 0

#Creates an array for Get-TPM
$TPMStatus = Get-Tpm

#This section of the code tests to make sure that there is a tpm installed on the pc and whether it is initialized.
#If the TPM is not initialized the script will attempt to initialize it twice until it is either initialized succesfully or fails.
#The script checks to see how many times the script looped before moving on and determines whether or not to continue enabling BitLocker.
if ($TPMStatus.TpmPresent -ne "True")
    {
        Write-Log "There is no TPM installed on this computer, so BitLocker cannot be enabled."
    }
if (($TPMStatus.TPMReady -ne "true") -and ($TPMStatus.TpmPresent -eq "true") -and ($TPMStatus.TpmEnabled -ne "true") -and ($TPMStatus.TpmActivated -ne "true"))
    { do 
        {
        try 
            {
                Initialize-TPM            
            }
        catch 
            {
                $Count = $Count + 1
            }
        } until (
            ($TPMStatus.TPMReady -eq "true") -and ($TPMStatus.TpmPresent -eq "true") -and ($TPMStatus.TpmEnabled -eq "true") -and ($TPMStatus.TpmActivated -eq "true")  -or ($Count=2)
    )
    }
if ($Count -eq 2) 
    {
        Write-Log "Failed to Intialize TPM. BitLocker cannot be enabled on this computer."
    }
else 
    {
        try 
            {
                #This section can be altered/duplicated to encrypt different dirves
                #If encrypting more than one drive, I recommend putting each encryption in it's own try/catch block
                Write-Log "TPM initialized succesfully. Attempting to enable BitLocker..."
                Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -TpmProtector
            }
        catch 
            {
                $Status = 1
            }
    }
if ($Status -eq 1) 
    {
        Write-Log "BitLocker Failed to enable. Please run BitLocker setup manually"
    }
if ($Status = 0) 
    {
        Write-Log "BitLocker enabled succesfully."
    }