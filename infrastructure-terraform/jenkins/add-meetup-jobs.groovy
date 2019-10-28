folder("meetup") {
    displayName("Meetup Examples")
    description("Jobs used for Meetup Talk")
}

def folders = [
    [
        id:          'example-2-application-automation',
        name:        'Example 1: Application Automation',
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
        name:        'Example 2: Pull-Based Updating',
        description: 'Folder containing Secrets Management Pipelines',
        jobs: [
            [
                id:          "example-3-build",
                name:        "Build Grafana with Vault Integration",
                description: "Build Grafana Habitat Package with Vault Integration",
                scriptPath:  "habitat-package-pipeline/Jenkinsfile"
            ]
        ]
    ],[
        id:          'example-4-compliance',
        name:        'Example 3: Compliance',
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
        id:          'destroy-all-infrastructure',
        name:        'Destroy Infrastructure Jobs',
        description: 'Jobs to destroy infrastructure provisioned by the Example Jobs',
        jobs: [
            [
                    id:          "destroy-infrastructure",
                name:        "Destroy All Example Infrastructure",
                description: "Destroy All Example Infrastructure",
                scriptPath:  "Jenkinsfile"
            ]
        ]
    ]
]

folders.each { folderObject ->
    folder("meetup/${folderObject.id}") {
        displayName(folderObject.name)
        description(folderObject.description)
    }

    folderObject.jobs.each { jobObject ->
        multibranchPipelineJob("meetup/${folderObject.id}/${jobObject.id}") {
            displayName(jobObject.name)
            description(jobObject.description)
            branchSources {
                github {
                    id(jobObject.id)
                    includes("meetup")
                    repoOwner("Indellient")
                    repository("liftoff-modern-application-automation")

                    buildForkPRHead(false)
                    buildForkPRMerge(false)
                    buildOriginBranch(true)
                    buildOriginBranchWithPR(true)
                    buildOriginPRHead(false)
                    buildOriginPRMerge(false)

                    // Required for private repositories OR to not be rate-limited
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
