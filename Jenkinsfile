#!groovy
@Library(['PSL@LKG', 'SG-PSL@master']) _ 

// Files regex that indicate if we need to publish a new version of the gem
def match = /VERSION|after_commit\.gemspec$/

// gemspec file name to build a gem for
def gemspecFile = 'after_commit.gemspec'

// built gem to push up
def gemToPublish = '*.gem'

// master branch flag
def isMasterBranch = env.BRANCH_NAME.equals('master')

// Jenkins Agent Label
def buildAgentLabel = 'aws-centos'

// We don't want to publish gem package unless a new version is defined
// Please refer to the match regex definition
newGemVersion = false

sg_utils_jenkins = new sg.utils.Jenkins(steps, env)
sg_utils_git = new sg.utils.Git(steps, env)
sg_utils_ruby = new sg.utils.Ruby(steps, env, docker)

//------------------------------------------------------------------------
//    d8888b. d888888b d8888b. d88888b db      d888888b d8b   db d88888b 
//    88  `8D   `88'   88  `8D 88'     88        `88'   888o  88 88'     
//    88oodD'    88    88oodD' 88ooooo 88         88    88V8o 88 88ooooo 
//    88~~~      88    88~~~   88~~~~~ 88         88    88 V8o88 88~~~~~ 
//    88        .88.   88      88.     88booo.   .88.   88  V888 88.     
//    88      Y888888P 88      Y88888P Y88888P Y888888P VP   V8P Y88888P 
//------------------------------------------------------------------------
pipeline {
    agent {
        label buildAgentLabel
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '30'))
    }

    stages {
        stage('Build') {
            steps {
                script {
                    sg_utils_ruby.buildGem( gemspecFile )
                }
            }
        }
        stage('Analyze') {
            steps {
                script {
                    // Getting changed files since the last successful build
                    def lastSuccessfulCommit = sg_utils_jenkins.getLastSuccessfulCommit(currentBuild)
                    if ( lastSuccessfulCommit ) {
                        def changedFiles = sg_utils_git.getChangedFiles( lastSuccessfulCommit )

                        // Looking for changed files that indicate we need to publish a new version of the gem
                        if (changedFiles.any { it =~ match }) {
                            newGemVersion = true
                        }
                    }
                    // lastSuccessfulCommit not found
                    else {
                        echo "Can't find any lastSuccessfulCommit! We assume that we need to build a new version of the gem."
                        newGemVersion = true
                    }
                }
            }
            post {
                always {
                    script {
                        // Setting the build result to 'NOT_BUILT' when the build occur on the master
                        // branch and when we don't have a new gem versions to built.
                        // This way, the changed files since the last successful build work like a charm
                        if ( isMasterBranch && !newGemVersion ) {
                            currentBuild.result = 'NOT_BUILT'
                        }
                    }
                }
            }
        }
        stage('Publish') {
            environment {
                ARTIFACTORY_APIKEY = credentials('svc_d_sgtools_artifactory_apikey')
            }
            when {
                allOf {
                    expression { isMasterBranch }
                    expression { newGemVersion }
                }
            }
            steps {
                script {
                    sg_utils_ruby.pushGem( gemToPublish, ARTIFACTORY_APIKEY)
                }
            }
        }
    }
}
