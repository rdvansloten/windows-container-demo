param (
  # Your Azure account email
  [Parameter(Mandatory=$true)]
  [string]$AZUREUSER,

  # Has to be globally unique
  [string]$CLUSTERNAME = "myaks$(Get-Random -Minimum -100000 -Maximum 999999)",

  # Max 6 characters
  [string]$NODEPOOLNAME = "win",

  # The region you prefer
  [string]$LOCATION = "westeurope",

  # Name of your Resource Group
  [string]$RESOURCEGROUP = "rg-aks",

  # Name of your Subscription
  [Parameter(Mandatory=$true)]
  [string]$SUBSCRIPTIONID
)

# Login to Azure
az login

# List and select the right Subscription
az account show
az account set --subscription "$SUBSCRIPTIONID"

# Create Resource Group
az group create `
  --name $RESOURCEGROUP `
  --location $LOCATION
  
# Create Managed Identity
az identity create `
  --name $CLUSTERNAME-id `
  --resource-group $RESOURCEGROUP `
  --location $LOCATION
  
# Store Managed Identity ID in variable for AKS creation
$AKSIDENTITY = $(
  az identity show `
    --name $CLUSTERNAME-id `
    --resource-group $RESOURCEGROUP `
    --query id
)

# Create VNET and subnet
az network vnet create `
  --name $CLUSTERNAME-vnet `
  --resource-group $RESOURCEGROUP `
  --location $LOCATION `
  --address-prefixes 172.10.0.0/16 `
  --subnet-name kubernetes `
  --subnet-prefixes 172.10.128.0/17
  
# Store subnet ID in variable for AKS creation
$SUBNETID = $(
  az network vnet subnet list `
    --resource-group $RESOURCEGROUP `
    --vnet-name $CLUSTERNAME-vnet `
    --query "[0].id"
)

# Grant AKS identity VNET access for Azure CNI
az role assignment create `
  --assignee-object-id $(
    az identity show `
      --name $CLUSTERNAME-id `
      --resource-group $RESOURCEGROUP `
      --query principalId
    )`
  --scope $(
    az network vnet show `
      --resource-group $RESOURCEGROUP `
      --name $CLUSTERNAME-vnet `
      --query id
    )`
  --assignee-principal-type ServicePrincipal `
  --role "Network Contributor"

# Assign AKS Kubelet Identity permissions on the AKS Resource Group
az role assignment create `
  --assignee-object-id $(
    az identity show `
      --name $CLUSTERNAME-id `
      --resource-group $RESOURCEGROUP `
      --query principalId
  )`
  --scope $(
    az group show `
      --name $(
        az group show `
          --resource-group $RESOURCEGROUP `
          --query name
      ) `
      --query id
    )`
  --assignee-principal-type ServicePrincipal `
  --role "Contributor"

# Create AKS cluster
az aks create `
  --resource-group $RESOURCEGROUP `
  --name $CLUSTERNAME `
  --location $LOCATION `
  --assign-identity $AKSIDENTITY `
  --assign-kubelet-identity $AKSIDENTITY `
  --node-vm-size Standard_B2s `
  --node-count 1 `
  --enable-aad `
  --enable-azure-rbac `
  --network-plugin azure `
  --vnet-subnet-id $SUBNETID `
  --docker-bridge-address 172.17.0.1/16 `
  --dns-service-ip 10.2.0.10 `
  --service-cidr 10.2.0.0/24 `
  --enable-addons http_application_routing
  
# Add Windows node pool
az aks nodepool add `
  --name $NODEPOOLNAME `
  --resource-group $RESOURCEGROUP `
  --cluster-name $CLUSTERNAME `
  --node-vm-size Standard_D2s_v4 `
  --node-count 1 `
  --os-type Windows `
  --max-surge 33%

# Assign yourself Admin permissions on the AKS cluster
az role assignment create `
  --assignee $(
    az ad user show `
      --id $(
        az ad user list `
          --query "[?contains(@.otherMails,'$AZUREUSER')].userPrincipalName " -o tsv
      ) `
      --query userPrincipalName 
  ) `
  --scope $(
    az aks show `
      --name $CLUSTERNAME `
      --resource-group $RESOURCEGROUP `
      --query id
  )`
  --role "Azure Kubernetes Service RBAC Cluster Admin"

  az role assignment create `
  --assignee $(
    az ad user show `
      --id $(
        az ad user list `
          --query "[?contains(@.userPrincipalName,'$AZUREUSER')].userPrincipalName " -o tsv
      ) `
      --query userPrincipalName 
  ) `
  --scope $(
    az aks show `
      --name $CLUSTERNAME `
      --resource-group $RESOURCEGROUP `
      --query id
  )`
  --role "Azure Kubernetes Service RBAC Cluster Admin"
  
# Assign AKS identity permissions to node pool Resource Group
az role assignment create `
  --assignee-object-id $(
    az identity show `
      --name $CLUSTERNAME-id `
      --resource-group $RESOURCEGROUP `
      --query principalId
  )`
  --scope $(
    az group show `
      --name $(
        az aks show `
          --name $CLUSTERNAME `
          --resource-group $RESOURCEGROUP `
          --query nodeResourceGroup
      ) `
      --query id
    )`
  --assignee-principal-type ServicePrincipal `
  --role "Contributor"

# Create Container Registry
az acr create `
  --resource-group $RESOURCEGROUP `
  --name "$($CLUSTERNAME)acr" `
  --sku Basic
  
# Add AKS to Container Registry
az role assignment create `
  --assignee-object-id $(
    az identity show `
      --name $CLUSTERNAME-id `
      --resource-group $RESOURCEGROUP `
      --query principalId
    )`
  --scope $(
    az acr show `
      --name "$($CLUSTERNAME)acr" `
      --query id
    )`
  --assignee-principal-type ServicePrincipal `
  --role "AcrPull"

Write-Output "AZUREUSER: $AZUREUSER"
Write-Output "CLUSTERNAME: $CLUSTERNAME"
Write-Output "LOCATION: $LOCATION"
Write-Output "SUBSCRIPTION: $SUBSCRIPTION"