# Deployment.ps1

## Options

| Argument        | Default                | Description                                                 |
| --------------- | ---------------------- | ----------------------------------------------------------- |
| -AZUREUSER      | -                      | Email address of the Azure subscription's Owner. (you)      |
| -CLUSTERNAME    | "myaks######"          | Name of the AKS Cluster. Should be globally unique.         |
| -NODEPOOLNAME   | "win"                  | Name of the Windows node pool. Max. 6 lowercase characters. |
| -LOCATION       | "westeurope"           | Geographical location of your resources.                    |
| -RESOURCEGROUP  | "rg-aks"               | Name of your Resource Group.                                |
| -SUBSCRIPTIONID | -                      | Name or ID of your Subscription. Use `az account show` to view.   |

## Example
To create an AKS cluster where your email is user@contoso.com, in East US in Azure Subscription "0000-0000-0000":
```powershell
powershell ./deployment.ps1 -AZUREUSER "user@contoso.com" -SUBSCRIPTIONID "0000-0000-0000" -LOCATION "eastus"
```

Please remember that -SUBSCRIPTIONID must match an existing Subscription's ID from the entry shown when running `az account show`, or nothing will be created. The default only works for newly created Azure free accounts.