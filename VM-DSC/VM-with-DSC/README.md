#OneClick deploy VM with SonarQube

- Creating a Virtual Machine on the Microsoft Azure Portal using an orchestrator script and an ARM with an extension (DSC)

##Creating context

    - run .\connect.ps1 with your desired Microsoft Azure subscription

##Content

    - azuredeploy.json (ARM template for the VM)
    - azureparameters.json (Parameters for the ARM template)
    - connect.ps1 (creating the current account context)
    - orchestrator.ps1 (deploying the ARM and running the Selenium script)
    - DSC folder
        - DSC.ps1 (the actual DSC script)
        - cChoco (chocolatey Powershell library)
        - xDownload (a Powershell library used to download files)
    - Selenium folder
        - scrie aici, Sebi

##Characteristics of the ARM

    - Windows Virtual Machine
    - SQL Database
    - SQL Server
    - sets a Network Interface
    - sets a Network Security Group with rules
    - creates a Load Balancer on the Port 80
    - loads an extension (DSC)

##Script Implementation

    - imports the current Account context
    - creates a new Resource Group (or uses an existing one)
    - creates a new Storage Account (or uses an existing one)
    - creates an archive with the DSC and uploads it on the Storage Account
    - creates a SASkey used for accesing the DSC archive for download
    - deploys the ARM

##DSC

- the DSC is loaded as an extension for the Virtual Machine
    - installs chocolatey and Java Runtime Environment (through chocolatey)
    - downloads an archive containing SonarQube from the official website
    - unarchives the downloaded file
    - creates an inbound rule to expose port 80 to the Internet
    - modifies the SonarQube config file, setting the necessary credentials to access the database created by the ARM and the port to 80
    - starts the SonarQube service

##Selenium

- the Selenium script is used to access the SonarQube Server
    - creates a new SonarQube project
    - generates a new access token for the "admin" user
    - appends exclusion rules to the project settings

##Running the Script

    - .\orchestrator resourceGroup resourceGroupLocation storageAccountName vmDNS

    where

    resourceGroup = new Resource Group Name (if none exists)
    resourceGroupLocation = location for the new ResourceGroup
    storageAccountName = new Storage Account Name (if none exists/ should be unique worldwide)
    vmDNS = the DNS of the newly deployed VM (should be unique worldwide)
