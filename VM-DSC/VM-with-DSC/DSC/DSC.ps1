[DSCResource()]
Configuration InstallSonarQube {
   
    #Parameters
    param(
        [string] $nodeName = "localhost",

        [Parameter(Mandatory)]
        [string]$databaseServer,

        [Parameter(Mandatory)]
        [string] $databaseName,

        [Parameter(Mandatory)]
        [string]$dbAdminName,

        [Parameter(Mandatory)]
        [string]$dbPassword
    )


    #Imports 
    Import-DscResource -ModuleName cChoco
    Import-DscResource -ModuleName xDownloadFile


    #Variables

    #download
    $sqDownloadURL = "https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.7.zip"
    $archiveName = "sqarch.zip"
    $downloadPath = "C:\sonarqube"


    #modify sonarqube configuration
    $pdbAdmin = 'sonar.jdbc.username='+$dbAdminName
    $pdbPassword = 'sonar.jdbc.password='+$dbPassword
    $pWebPort = 'sonar.web.port=80'
    $pdbConnectionString = 'sonar.jdbc.url=jdbc:sqlserver://'+$databaseServer+'.database.windows.net:1433;database='+$databaseName+';user='+$dbAdminName+'@'+$databaseServer+';password='+$dbPassword +';encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;'
    
    $configurationFilePath = $downloadPath + "\sonarqube-6.7\conf\sonar.properties"
    $newConfig = $pdbAdmin+","+ $pdbPassword+","+ $pWebPort+","+ $pdbConnectionString

    #install and start service
    $serviceName = "sonarqube"
    $sqServiceInstaller = $downloadPath + "\sonarqube-6.7\bin\windows-x86-64\InstallNTService.bat"
    $sqStartService =   $downloadPath + "\sonarqube-6.7\bin\windows-x86-64\StartNTService.bat"
  

    Node $nodeName
    {
        #install chocolatey
        cChocoInstaller installChoco {
            InstallDir = "C:\ProgramData\chocolatey"
        }

        #install Java which is needed to run sonarqube
        cChocoPackageInstaller installJava {
          DependsOn = "[cChocoInstaller]installChoco"
          Name = "jre8"
        }

        #download sonarqube
        xDownloadFile downloadSonarQube {
            SourcePath = $sqDownloadURL
            FileName = $archiveName
            DestinationDirectoryPath = $downloadPath
        }

        #unarchive sonarqube
        Archive unarchiveSonarQube {
            DependsOn = '[xDownloadFile]downloadSonarQube'
            Ensure = "Present"
            Path = $downloadPath + "\" + $archiveName
            Destination = $downloadPath
        }

        #change sonarQube config file
        Script changeSonarQubeConfig {

            SetScript =
            {   $content = $using:newConfig
                $splitted = $content.Split(",")

                Set-Content -Path $using:configurationFilePath -Value ""

                foreach($element in $splitted){
                    Add-Content -Path $using:configurationFilePath -Value $element
                }
           }

            TestScript = { return $false }
            GetScript = { @{ Result = "" } }
        }

       #install and start sonarqube as a service
       Script installAndStartSonarQube {

            SetScript =
            {
                Try{
                    New-NetFirewallRule -DisplayName "Inbound 80" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow
                    powershell.exe $using:sqServiceInstaller
                    powershell.exe $using:sqStartService
                }
                Catch{
                    Write-EventLog -Logname $using:serviceName -Message $_.Exception.Message -Verbose
                }  
           }
            TestScript = { return $false }
            GetScript = { @{ Result = "" } }
        }
    }
}