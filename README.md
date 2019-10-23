# hashicorp-chef-sales-event

### Running the Demo

#### Preparation
Make use of an existing Automate, Jenkins and Vault if possible, or use the Terraform in the `terraform/infrastructure` folder to spin these up. The SSH keys will be made available through the output for each of the nodes.

- For Automate the credentials will be available post-deploy in `/root/automate-credentials.toml`.
- For Jenkins a randomized password is created that is included in the Terraform output
- For Vault, the token is available on the machine through the Supervisor API. This can be queries using `curl` & `jq` (you can install `jq` using `hab pkg install -b core/jq-static`) from the machine: `curl localhost:9631/services/vault/default/config | jq -r .token`
