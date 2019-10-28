# Getting Ready for Liftoff Using Modern Application Delivery


# Preparation
You can make use of existing Automate, Jenkins, and Vault instances, for the sake of these examples. Skip forward to "<tool> Setup", otherwise, follow the infrastructure guide below.

## Infrastructure Provisioning

To prepare the environment for the example, terraform is provided in `terraform/infrastructure` folder to spin up required tools and infrastructure. The SSH keys for the tools will be made available through the output for each of the nodes.

- For Automate the credentials will be available post-deploy in `/root/automate-credentials.toml`.
- For Jenkins a randomized password is created that is included in the Terraform output
- For Vault, the token is available on the machine through the Supervisor API. This can be queries using `curl` & `jq` (you can install `jq` using `hab pkg install -b core/jq-static`) from the machine: `curl localhost:9631/services/vault/default/config | jq -r .token`

### 0. Setup Azure Credentials
Create a Service Principal using the documentation available for the [Terraform Provider](https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html#creating-a-service-principal-using-the-azure-cli) and export the environment variables in the shell session in which you plan to run the Terraform.   

### 1. Backend
Create a "backend" for the infrastructure using the terraform in the [backend folder](infrastructure-terraform/backend). Run a `terraform init` and `terraform apply`. This will create a [Resource Group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview), Storage Account and Storage Container in Azure for Terraform [remote states](https://www.terraform.io/docs/state/remote.html). The states for the rest of the infrastructure an examples will exist in containers in this storage container.

### 2. Networking
Create a Virtual Private Network, Public Subnet, and DNS Zone by running Terraform in the [networking folder](infrastructure-terraform/networking). Note the remote state for this Terraform is reference in almost every other set of Terraform for the sake of specifying the network and subnet.

### 3. Bastion
Create the Bastion for the infrastructure, which acts as the [Permanent Peer](https://www.habitat.sh/docs/best-practices/#permanent-peers) for this Habitat deployment. This is where we will peer all our other nodes to, as well as apply configurations

### Jenkins Setup

#### Credentials
The included Jenkinsfiles rely on credentials for Terraform, Vault and Habitat Builder authentication. The names of these can be found in the Jenkinsfiles and can be added to existing Jenkins installations. When using the included Jenkins terraform these are pre-provisioned by providing the values for the Terraform variables.

These variables include
- Habitat Personal Access Token (**HAB_AUTH_TOKEN** environment variable)
- Azure Credentials (**ARM_CLIENT_ID**, **ARM_CLIENT_SECRET**, **ARM_TENANT_ID**, **ARM_SUBSCRIPTION_ID**)
  These values represent an Azure Service Principal which allow applications such as Terraform and Packer to execute a limited set of commands instead of making use of fully privileged user credentials. See the [Microsoft Azure Documentation](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2Fazure%2Fazure-resource-manager%2Ftoc.json&view=azure-cli-latest) for more information.  
- Vault Token (**VAULT_TOKEN**)
  This value is used to read/write data from Vault, and is used by the Vault Terraform Provider when run through Jenkins. See the [Vault Documentation](https://www.vaultproject.io/docs/concepts/tokens.html) for more details.

#### Environment Variables 
Once these are added, we will make use of Global Environment Variables (Manage Jenkins > Configure System) which will export these variables for every pipeline run on this Jenkins. Note that this can be overriden by an `environment` block within a Jenkinsfile, and serves as *default* values only.
![Jenkins Environment Variables](doc/jenkins-environment-variables.png)

Make use of this to add the following environment variables:
- **HAB_ORIGIN**
  When **HAB_ORIGIN** is exported, the Habitat build process will override the value of `pkg_origin`, allowing these examples to work without having to modify the `plan.sh`
- **VAULT_TOKEN**
  This token should have permission to create a Secret ID for the AppRole created for Grafana (see details in Vault Setup) to allow a role-id and secret-id to be correctly provisioned.
- **PATH**
  Update the path to begin with `/bin`, this allows us to use bin-linked Habitat packages over System-specific executables and allows us to install dependencies for a pipeline within the pipeline itself, without effecting the rest of the system. **NOTE You cannot simply override $PATH! The correct syntax is to set Variable Name to `PATH+PATH` and value to `/bin`**!
  
![Jenkins PATH Environment Variable](doc/jenkins-path-environment-variable.png)
  
#### Jobs
The Jobs must be added to Jenkins, and can be done through the provided [Job DSL](infrastructure-terraform/jenkins/add-all-jobs.groovy). To use this file, create a new Freestyle project, adding a build step "Process Job DSLs" (note this requires the job-dsl plugin, which is included in the Jenkins package in this repository). Select "Use the provided DSL script" within the action, and paste the contents of the script within it. Run the job and the folders and jobs for each fo the examples should be created. 
  
### Vault Setup
These examples require the following:
- A kv secrets engine be mounted at `secret/`
- A password for Grafana be provisioned somewhere in the `secret/` mount.
- AppRole Authentication enabled
- A Policy and Role created for Grafana
- A Token Created for Jenkins that allows creating a Secret ID for the Grafana Role

This can be easily done by making use of the included [setup-vault.sh script](infrastructure-terraform/vault/setup-vault.sh). This script takes as an argument the password, the field name, path, policyname and rolename, though only the password is a required argument with the rest having reasonable defaults. Making use of the defaults allows the examples to be used without modification. Note the script makes use of the default environment variables `VAULT_ADDR` and `VAULT_TOKEN` recognized by Vault to run the Vault commands.

Note the required policies:
```hcl
path "secret/data/grafana" {
  capabilities = [ "read" ]
}
```

The Role creation:
```bash
vault write auth/approle/role/grafana policies=grafana
```

And the Role for Jenkins:
```hcl
path "auth/approle/role/grafana/role-id" {
  capabilities = [ "read" ]
}

path "auth/approle/role/grafana/secret-id" {
  capabilities = [ "create", "update" ]
}

path "auth/approle/role/grafana/secret-id-accessor/*" {
  capabilities = [ "read", "create", "update", "delete" ]
}

path "auth/token/create" {
  capabilities = [ "read", "create", "update", "delete" ]
}
```

Once the role for Jenkins is created, create a token that is inserted as a `vault-token` Credential:
```bash
vault token create -policy jenkins -format "json"
``` 

### Automate Setup
The examples require that you create a token (Settings > API Tokens) that you may put in `default.toml` for the effortless applications, at a minimum
- habitat-plans/infra-linux-base-applications
- habitat-plans/infra-linux-base-applications-with-hardening

You may also put this in the `infra-linux-hardening` package to have Chef Client runs for hardening report back to Automate. This token can also be applied through [configuration updates](https://www.habitat.sh/docs/using-habitat/#config-updates) through Habitat, the details of which are not covered in detail as part of these examples.
