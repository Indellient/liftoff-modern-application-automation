import jenkins.model.Jenkins
import hudson.security.HudsonPrivateSecurityRealm
import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
import jenkins.AgentProtocol
import jenkins.security.s2m.AdminWhitelistRule

import hudson.security.csrf.DefaultCrumbIssuer

def instance = Jenkins.getInstance()

// Disable submitting usage statistics for privacy
println "Checking if usage statistics are collected: ${instance.isUsageStatisticsCollected()}"
if (instance.isUsageStatisticsCollected()) {
    println "Disable submitting anonymous usage statistics to jenkins-ci.org for privacy."
    instance.setNoUsageStatistics(true)
}

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("{{cfg.admin.username}}", "{{cfg.admin.password}}")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

println "Setting slave port to {{cfg.config.slavePort}}"
instance.setSlaveAgentPort({{cfg.config.slavePort}})

// Disable slave-to-master kill switch
instance.getInjector()
       .getInstance(AdminWhitelistRule.class)
       .setMasterKillSwitch(false)

println "Setting crumb issuer"
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

instance.save()
