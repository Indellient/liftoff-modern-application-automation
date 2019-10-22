import jenkins.model.*

import hudson.security.*
import hudson.util.Secret

import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl;

import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def instance = Jenkins.get()

def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider').first().store
def globalDomain = Domain.global()

{{#each cfg.credentials as |creds|}}
  if (!store.getCredentials(globalDomain).find { it.id == "{{creds.id}}" }) {
    {{#if creds.private_key}}
    def secret = new BasicSSHUserPrivateKey(
      CredentialsScope.GLOBAL,
      // Credentional ID
      "{{creds.id}}",
      // Username
      "{{creds.user}}",
      // Private key
      new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource("{{creds.value}}"),
      // Passphrase
      "{{creds.passPhrase}}",
      // Description
      "{{creds.description}}"
    )
    {{/if}}

    {{#if creds.token}}
    def secret = new StringCredentialsImpl(
      CredentialsScope.GLOBAL,
      "{{creds.id}}",
      "{{creds.description}}" as String,
      Secret.fromString("{{creds.token}}")
    )
    {{/if}}

    {{#if creds.password}}
    def secret = new UsernamePasswordCredentialsImpl(
      CredentialsScope.GLOBAL,
      "{{creds.id}}",
      "{{creds.description}}" as String,
      "{{creds.user}}",
      "{{creds.password}}"
    )
    {{/if}}

    store.addCredentials(globalDomain, secret)
  }
{{/each}}

instance.save()
