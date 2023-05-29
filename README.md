https://learn.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-custom-images
https://learn.microsoft.com/en-us/azure/developer/terraform/create-resource-group?tabs=azure-cli
https://learn.microsoft.com/en-us/cli/azure/azure-cli-learn-bash#code-try-0
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret.html#configuring-the-service-principal-in-terraform

az account list | jq -r '.[].tenantId'
az ad sp create-for-rbac --display-name="rmordasiewicz-sp" --role="Contributor" --scopes="/subscriptions/cf72478e-c3b0-4072-8f60-41d037c1d9e9"


# Create Azure Resource Group
az group create -l eastus -n app1-tfstate-rg
# Create Azure Storage Account
az storage account create -l eastus -n app1tfstatesa -g app1-tfstate-rg
# Create Storage Account Container
az storage container create --name tfstate --account-name app1tfstatesa
