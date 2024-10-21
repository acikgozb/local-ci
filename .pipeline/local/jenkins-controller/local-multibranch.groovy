multibranchPipelineJob('ci-pipeline') {
        displayName("CI Pipeline")
        description("This is the local playground that indexes our Jenkinsfile and delegates the steps to our agent when a build is triggered.")

        factory {
          workflowBranchProjectFactory {
            scriptPath('.pipeline/Jenkinsfile')
          }
        }

        branchSources {
          git {
            id('local-git-repo') 
            remote('file:///var/jenkins_home/repo')
          }
        }

        orphanedItemStrategy {
          discardOldItems {
            numToKeep(1)
          }
        }
}
