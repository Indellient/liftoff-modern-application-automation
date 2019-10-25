def folders = [
    [
        id:          'example-1-server-provisioning',
        name:        'Example 1: Server Provisioning',
        description: 'Folder containing Server Provisioning Pipelines',
        jobs: [
            [
                id:          "example-1-deploy",
                name:        "Deploy",
                description: "Deploy Server on Azure",
                scriptPath:  "terraform-pipeline/Jenkinsfile"
            ]
        ]
    ],[
        id:          'example-2-application-automation',
        name:        'Example 2: Application Automation',
        description: 'Folder containing Application Automation Pipelines',
        jobs: [
            [
                id:          "example-2-build",
                name:        "Build Grafana",
                description: "Build Grafana Habitat Package",
                scriptPath:  "habitat-package-pipeline/Jenkinsfile"
            ],[
                id:          "example-2-deploy",
                name:        "Deploy Grafana",
                description: "Deploy Grafana on Azure using Habitat",
                scriptPath:  "terraform-pipeline/Jenkinsfile"
            ]
        ]
    ],[
        id:          'example-3-secrets-management',
        name:        'Example 3: Secrets Management',
        description: 'Folder containing Secrets Management Pipelines',
        jobs: [
            [
                id:          "example-3-build",
                name:        "Build Grafana with Vault Integration",
                description: "Build Grafana Habitat Package with Vault Integration",
                scriptPath:  "habitat-package-pipeline/Jenkinsfile"
            ],[
                id:          "example-3-deploy",
                name:        "Deploy Grafana with Vault Integration",
                description: "Deploy Grafana on Azure using Habitat and Vault",
                scriptPath:  "terraform-pipeline/Jenkinsfile"
            ]
        ]
    ],[
        id:          'example-4-compliance',
        name:        'Example 4: Compliance',
        description: 'Folder containing Compliance Related Pipelines',
        jobs: [
            [
                id:          "example-4-build",
                name:        "Build Base OS Applications with Hardening",
                description: "Build Base OS Applications with Hardening",
                scriptPath:  "habitat-package-pipeline/Jenkinsfile"
            ]
        ]
    ],[
        id:          'extra-example-base-os',
        name:        'Extra Example: Operating System Pipelines',
        description: 'Folder containing Operating System Pipelines',
        jobs: [
            [
                id:          "extra-example-os-build",
                name:        "Build Base OS Image",
                description: "Build Base OS Image",
                scriptPath:  "packer-pipeline/Jenkinsfile"
            ]
        ]
    ]
]

folders.each { folderObject ->
    folder(folderObject.id) {
        displayName(folderObject.name)
        description(folderObject.description)
    }

    folderObject.jobs.each { jobObject ->
        multibranchPipelineJob("${folderObject.id}/${jobObject.id}") {
            displayName(jobObject.name)
            description(jobObject.description)
            branchSources {
                github {
                    id(jobObject.id)
                    includes("master")
                    repoOwner("Indellient")
                    repository("liftoff-modern-application-automation")

                    buildForkPRHead(false)
                    buildForkPRMerge(false)
                    buildOriginBranch(true)
                    buildOriginBranchWithPR(true)
                    buildOriginPRHead(false)
                    buildOriginPRMerge(false)

                    // Required for private repositories
                    checkoutCredentialsId("github-access-token")
                    scanCredentialsId("github-access-token")
                }
            }

            factory {
                workflowBranchProjectFactory {
                    scriptPath("examples/${folderObject.id}/${jobObject.scriptPath}")
                }
            }
        }
    }
}
