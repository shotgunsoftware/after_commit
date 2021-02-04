#!groovy
// @Library(['PSL@LKG', 'SG-PSL@master']) _ 
@Library(['PSL@LKG', 'SG-PSL@master']) _ 

// Jenkins Agent Label
def buildAgentLabel = 'aws-centos'

// Define which branches we want to publish from
def isPublishBranch = env.BRANCH_NAME.trim() ==~ /master/

// Files regex that indicate if we need to publish a new version of the gem
def versionFiles = /VERSION|after_commit\.gemspec$/

// gemspec file name to build a gem for
def gemspecFile = 'after_commit.gemspec'

// built gem to push up
def gemToPublish = '*.gem'

// Jenkins credentials id to use 
def artifactoryCredentialsId = 'svc_d_sgtools_artifactory_apikey'

// By default we don't publish
enablePublish = false

// 
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
                    def lastSuccessfulCommit = sg_utils_jenkins.getLastSuccessfulCommit( currentBuild )
                    if ( lastSuccessfulCommit ) {
                        enablePublish = sg_utils_git.searchChangedFiles( versionFiles, lastSuccessfulCommit )
                    }
                    else {
                        echo "Can't find lastSuccessfulCommit! Enable publishing stage."
                        enablePublish = true
                    }
                }
            }
            post {
                always {
                    script {
                        // Setting the build result to 'NOT_BUILT' when the build occur on a publish branch
                        // and when we don't have a new gem versions to publish. Using this mechanism make  
                        // the changed files since the last successful build work like a charm.
                        if ( isPublishBranch && !enablePublish ) {
                            currentBuild.result = 'NOT_BUILT'
                        }
                    }
                }
            }
        }
        stage('Publish') {
            when {
                allOf {
                    expression { isPublishBranch }
                    expression { enablePublish }
                }
            }
            steps {
                script {
                    sg_utils_ruby.pushGem( gemToPublish, artifactoryCredentialsId )
                }
            }
        }
    }
}
