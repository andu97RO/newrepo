Param(
    [Parameter(Mandatory=$True)]
    [string]$subscription
)
Connect-AzureRmAccount -Subscription $subscription
Save-AzureRmContext -Path context.json -Force