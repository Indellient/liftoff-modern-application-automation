/**
 * Note this file is named specifically so it comes first in lexical order for
 * the init scripts, this is necessary to ensure the rest of the scripts are
 * able to use any configured plugins
 */

import jenkins.model.Jenkins
import java.util.concurrent.CompletableFuture

// Plugins to Install
final List<String> PLUGINS_TO_INSTALL = [
    {{#each cfg.config.plugins as |plugin| ~}}
    "{{plugin}}"{{#unless @last ~}},{{/unless}}
    {{/each}}
]

def instance = Jenkins.get()
def updateCenter = instance.updateCenter
def pluginManager = instance.pluginManager

// Update plugins
println "Updating plugins"
updateCenter.updateAllSites()
updateCenter.updates.each { it.deploy(false) }

println "Installing plugins..."
pluginManager.install(PLUGINS_TO_INSTALL, true).each { it.get() }
println "Done installing Plugins..."
