# Getting Ready for Liftoff Using Modern Application Delivery

This repository contains code with various examples of the following:

- Operating System Image Pipeline using **HashiCorp Packer**
- Infrastructure Pipeline using **HashiCorp Terraform**
- Application Pipeline using **Chef Habitat**
- Application Automation integration with Secrets Management using **Vault Terraform**
- Continuous Compliance, Hardening and Reporting using **Chef Inspec**, **Chef Infra** and **Chef Automate**

Note that the examples as well as the code used to provision the necessary infrastructure to run the examples are meant to be used in conjunction with a Powerpoint Presentation and recorded walk through that is made available with this resource.

# Preparation
You can make use of existing Automate, Jenkins, and Vault instances, for the sake of these examples. Skip forward to "\<tool\> Setup", otherwise, follow the infrastructure guide below.

## 0. Credentials

### 0.1 Setup Azure Credentials
To run the Terraform to create the infrastructure as well as run the Terraform examples in Jenkins, a [Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal) is required. Create a Service Principal using the documentation available for the [Terraform Provider](https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html#creating-a-service-principal-using-the-azure-cli) and export the environment variables in the shell session in which you plan to run the Terraform. Note the variables:
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_TENANT_ID`
- `ARM_SUBSCRIPTION_ID`

### 0.2 Github Credentials
This is used to prevent rate limiting when scanning repositories form Jenkins. Note, you may use a [token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) with `repo` access instead of a password

### 0.3 Habitat Authentication Token
This is used to authenticate with the Habitat Public Builder. Create this using the [documentation](https://www.habitat.sh/docs/using-builder/#builder-token)

## 1. Infrastructure Provisioning

To prepare the environment for the example, terraform is provided in `terraform/infrastructure` folder to spin up required tools and infrastructure. The SSH keys for the tools will be made available through the output for each of the nodes.

- For Automate the credentials will be available post-deploy in **/root/automate-credentials.toml**.
- For Jenkins a randomized password is created that is included in the Terraform output (this can be run at anytime using `terraform output` after this is initially run)
- For Vault, the token is available through the Supervisor API, see "2. Vault Setup" for more information.

Keep note of these credentials, as they will also be used to provision Jenkins with the necessary access to run the examples.

### 1.2 Backend
First the terraform in the [backend folder](infrastructure-terraform/backend) must be used to create an [Azure Resource Group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview), Storage Account, and Storage Container used to group the infrastructure/examples resources and [Terraform Remote States](https://www.terraform.io/docs/state/remote.html). Run a `terraform init` and `terraform apply` inside this folder in a session with the Service Provider credentials exported (see 0.1).

### 1.3 Networking
Create a Virtual Private Network, Public Subnet, and DNS Zone by running the Terraform (`terraform init` & `terraform apply`) in the [networking folder](infrastructure-terraform/networking). Note the remote state for this Terraform is referenced in most other modules to specify the network and subnet.

### 1.4 Bastion
Create the Bastion for the infrastructure, which acts as the [Permanent Peer](https://www.habitat.sh/docs/best-practices/#permanent-peers) for this Habitat deployment.

### 1.5 Applications (Automate, Jenkins, Vault)
Run a `terraform init` & `terraform apply` in each of the application folders, as order is no longer important. Note the following per-application requirements:
- **Automate** - An existing license may be used through the available **example.tfvars** file inside the folder by filling in the value of `automate_license` and using the `-var-file` argument (e.g. `terraform apply -var-file=example.tfvars` or modifying the default value in **variables.tf**. If a license is not used a trial license can be set up once this application is launched.
- **Jenkins** - This terraform requires a few variables which will create credentials inside Jenkins, with an example of these given in **terraform.tfvars** (see section 0 for how to create these):
  - Azure Credentials
  - Github username/password
  - Habitat Authentication Token
- **Vault** - N/A

### 2. Vault Setup
These examples require the following:
- A kv secrets engine be mounted at `secret/`
- A password for Grafana be provisioned somewhere in the `secret/` mount.
- AppRole Authentication enabled
- A Policy and Role created for Grafana
- A Token Created for Jenkins that allows creating a Secret ID for the Grafana Role

#### 2.1 Vault Authentication
To enable these, we must have access to the [vault binary](https://www.vaultproject.io/downloads.html) and correctly set up our environment variables (`VAULT_ADDR`/`VAULT_TOKEN`) to authenticate with the remote Vault instance. First export `VAULT_ADDR` to the fqdn output of the vault terraform, or a Vault endpoint if you are re-using an existing Vault instance (note, a port may be required: `export VAULT_ADDR=https://vault.test.io:8200`). Export `VAULT_TOKEN` used to authenticate with Vault; if using the included terraform this can be acquired through the use of `curl` on the command line: `curl <vault-fqdn>:9631/services/vault/default/config` in property `token`:
```json
{
  "backend": {
    "path": "vault",
    "storage": "consul"
  },
  "dev": {
    "mode": false
  },
  "listener": {
    "cluster_location": "0.0.0.0",
    "cluster_port": 8201,
    "location": "0.0.0.0",
    "port": 8200,
    "tls_disable": true,
    "type": "tcp"
  },
  "token": "<token>",
  "ui": true,
  "unseal_keys": [
    "<unseal-key-1>",
    "<unseal-key-2>",
    "<unseal-key-3>",
    "<unseal-key-4>",
    "<unseal-key-5>"
  ]
}
```
This can be done in a one-liner using [`jq`](https://stedolan.github.io/jq/):
```bash
$ export VAULT_TOKEN=$(curl --silent <vault-fqdn>:9631/services/vault/default/config | jq -r .token)
```

Now we can set up the required secrets/engines/policies.

#### 2.2 Secrets and Access

Note these steps can be skipped by making use of the included [setup-vault.sh script](infrastructure-terraform/vault/setup-vault.sh), which takes as an argument a password, uses environment variables `VAULT_ADDR` and `VAULT_TOKEN`, and requires the `vault` and `jq` binaries. Note this script may have to be adjusted if the packages or example files are modified (i.e. to read the secret at a different path), and will output a Token to be put into Jenkins (see 3.1 for more information) as a credential.

To do this manually, run the following commands.

First, enable the [Key-Value Secrets engine, version 2]( https://www.vaultproject.io/docs/secrets/kv/kv-v2.html):
```bash
$ vault secrets enable --path secret kv-v2
Success! Enabled the kv-v2 secrets engine at: secret/
```

Followed by enabling [Application Role Authentication Method)[https://www.vaultproject.io/docs/auth/approle.html]:
```bash
$ vault auth enable approle
Success! Enabled approle auth method at: approle/
```

Now, create the actual secret (make sure to replace `<password>` with a real value!) 
```bash
$ vault kv put secret/grafana password=<password>
Key              Value
---              -----
created_time     2019-10-31T12:59:59.391476391Z
deletion_time    n/a
destroyed        false
version          1
```

To make use of this secret, create a Policy for Grafana allowing read access, as well as creating a Role associated with this policy: 
```bash
$ vault policy write grafana - <<EOF
path "secret/data/grafana" {
  capabilities = [ "read" ]
}
EOF
Success! Uploaded policy: grafana

$ vault write auth/approle/role/grafana policies=grafana
Success! Data written to: auth/approle/role/grafana
```

Finally, create a policy for Terraform/Jenkins. This will allow the infrastructure pipeline to create a password and provision the example node with credentials to be able to log in as the Grafana role. Note that this *does not* have access to read the secret!
```bash
# Create Jenkins Role
$ vault policy write jenkins - <<EOF
path "auth/approle/role/grafana/role-id" {
  capabilities = [ "read" ]
}

path "auth/approle/role/grafana/secret-id" {
  capabilities = [ "create", "update" ]
}

path "auth/approle/role/grafana/secret-id-accessor/*" {
  capabilities = [ "create", "read", "update", "list" ]
}

path "auth/token/create" {
  capabilities = [ "read", "create", "update", "delete" ]
}
EOF
Success! Uploaded policy: jenkins
```

Finally, create a token associated with this Jenkins policy:
```bash
$ vault token create -policy jenkins
Key                  Value
---                  -----
token                <token>
token_accessor       DiV0JwTP6M6wy0e4tJvIaVO2
token_duration       768h
token_renewable      true
token_policies       ["default" "jenkins"]
identity_policies    []
policies             ["default" "jenkins"]
```

Note, keep track of this token as this will be used to provision Jenkins in the following section!

### 3. Jenkins Setup

#### 3.1 Credentials
The included Jenkinsfiles rely on the Credentials plugin for Terraform, Vault and Habitat Builder authentication. See Sectoin 0 for how to create these, then insert these into Jenkins (Credentials > System. Select "Global Credentials" domain > Add Credentials):
- Habitat Personal Access Token (**habitat-depot-token**) of type secret-text. *Note this will have been created if you made use of the included terraform*
- Azure Credentials (**arm-client-id**, **arm-client-secret**, **arm-tenant-id**, **arm-subscription-id**), each of type secret text. See section 0 for more information. *this will have been created if you made use of the included terraform*
- Vault Token (**vault-token**) This value is used to read/write data from Vault, and is used by the Vault Terraform Provider when run through Jenkins. See the [Vault Documentation](https://www.vaultproject.io/docs/concepts/tokens.html) for more details on Tokens, and see section 2.2 for creation of this token.

#### 3.2 Environment Variables 
Once these are added, we will make use of Global Environment Variables (Manage Jenkins > Configure System) which will export these variables for every pipeline run on this Jenkins. Note that this can be overriden by an `environment` block within a Jenkinsfile, and serves as *default* values only.
![Jenkins Environment Variables](doc/jenkins-environment-variables.png)

Make use of this to add the following environment variables:
- **HAB_ORIGIN**
  When **HAB_ORIGIN** is exported, the Habitat build process will override the value of `pkg_origin`, allowing these examples to work without having to modify the `plan.sh` of any of the packages. Set this variable to the name of a pre-existing Origin you have access to, or [create an Origin](https://www.habitat.sh/docs/using-builder/#builder-origin) for these examples. **Note that this variable was defined in the Jenkinsfile for the Habitat package pipelines during the event, but was commented to allow for this repository to be used without having to be forked**.
- **PATH**
  Update the path to begin with `/bin`, this allows us to use bin-linked Habitat packages over System-specific executables and allows us to install dependencies for a pipeline within the pipeline itself, without effecting the rest of the system. **NOTE You cannot simply override $PATH! The correct syntax is to set Variable Name to `PATH+PATH` and value to `/bin`**!
  
![Jenkins PATH Environment Variable](doc/jenkins-path-environment-variable.png)
  
#### 3.3 Jobs
The Jobs must be added to Jenkins, and can be done through the provided [Job DSL](infrastructure-terraform/jenkins/add-all-jobs.groovy). To use this file, create a new Freestyle project adding a build step "Process Job DSLs" (note this requires the job-dsl plugin, which is included in the Jenkins package in this repository). Select "Use the provided DSL script" within the action, and paste the contents of the script within it. Run the job and the folders/jobs for the examples should be created. 

### 4. Automate Setup
Log in. If using the included terraform, this requires you SSH to the machine with the private-key provided in the terraform output and use the credentials in **/root/automate-credentials.toml**.

# Examples
//TODO
