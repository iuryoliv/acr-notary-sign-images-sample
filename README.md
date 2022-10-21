# Project Name

(short, 1-3 sentenced, description of the project)

## Getting Started

### Prerequisites

- Azure subscription
- GitHub account
- Terraform

### Get started

1. Click the `Use this template` button at the top of the page
2. Select an **Owner** and enter a **repository name**, then click `Create repository from template`
3. Use `git clone` to pull the repository to your local development enviornment

### Set up your environment

1. Create a service principal

    ```bash
    az ad sp create-for-rbac --name <servicePrincipalName> --role contributor \
    --scopes /subscriptions/<subscriptionId> --sdk-auth
    ```

    > **TIP**
    > **Store the JSON object in a secure place**. You'll use it to create a credential to authenticate to Azure with the Azure Login GitHub Action.

2. Export Terraform environment variables

    ```bash
    export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
    export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
    export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
    export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000
    ``` 

    Replace the `00000000` values with your service principal information.

3. Initialize Terraform

    ```bash
    cd terraform
    
    terraform init
    ```

4. Apply the Terraform configuration

    ```bash
    terraform apply
    ```

    When prompted type `yes` into the terminal and hit **enter**.

5. Create an Azure Container Registry Token

    ```bash
    az acr token create \
        --name <tokenName> \
        --registry <registryName> \
        --scope-map _repositories_admin \
        --query 'credentials.passwords[0].value' \
        --only-show-errors \
        --output tsv
    ```

    > **TIP**
    > **Store the password value in a secure place**. You'll need to store it as a GitHub secret later in the demo.

### Create GitHub Action Secrets

Create a GitHub Action secret for authenticating to Azure.

1. Click the `Settings` on the repository
2. Select `Secrets`, then `Actions`, and Click `New repository secret`
3. Enter **AZURE_CREDENTIALS** as the secret name
4. Paste the JSON object from the `az ad sp` issued previously
5. Click **Add secret**

Create GitHub Action secrets for Notation username.

1. Click the `Settings` on the repository
2. Select `Secrets`, then `Actions`, and Click `New repository secret`
3. Enter `NOTATION_USERNAME` as the secret name
4. Enter the name of the Azure Container Registry token generated previously
5. Click **Add secret**

Create GitHub Action secrets for Notation password.

1. Click the `Settings` on the repository
2. Select `Secrets`, then `Actions`, and Click `New repository secret`
3. Enter `NOTATION_PASSWORD` as the secret name
4. Enter the password of the Azure Container Registry token generated previously
5. Click **Add secret**

### Update the GitHub Workflow

1. Open `.github/workflows/docker-image.yml`
2. Replace `<registry-name>` with the name of your Azure Container Registry
3. Replace `<image-name>` with the name of your Docker image
4. Replace `<key-name>` with the name of the signing key for notation
5. Replace `<certificate-key-id>` with the keyId of the certificate used for signing
6. Use git to add, commit, and push your changes.
7. Browse to the repository on GitHub, and click the **Actions** tab.


> **TIP**
> **To find the keyId of the certificate, run `az keyvault certificate show --name certName --vault-name <vaultName>  --query kid -o tsv`


## Resources

- [setup-notation](https://github.com/Duffney/setup-notation)
- [notary-sign-action](https://github.com/Duffney/notary-sign-action)
- [notation-azure-kv](https://github.com/Azure/notation-azure-kv)
- [Notary Project](https://github.com/notaryproject)
