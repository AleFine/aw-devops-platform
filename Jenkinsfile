pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: tools
    image: alpine:3.20
    command: ['sh','-c','sleep 3600']
    tty: true
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ['/busybox/sh','-c','sleep 3600']
    tty: true
    env:
    - name: DOCKER_CONFIG
      value: /kaniko/.docker/
  - name: trivy
    image: aquasec/trivy:latest
    command: ['sh','-c','sleep 3600']
    tty: true
"""
      defaultContainer 'tools'
    }
  }
  
  environment {
    AWS_REGION = 'us-east-1'
    ECR_REPO   = 'aw-bootcamp-app'
    EKS_CLUSTER = 'aw-bootcamp-eks'
    GRAFANA_URL = 'http://grafana.observability.svc.cluster.local'
    GRAFANA_DASHBOARD_UID = 'bootcamp-app'
  }
  
  stages {
    stage('Bootstrap Tools') {
      steps {
        sh '''
          set -e
          apk add --no-cache curl bash git unzip tar gzip python3 py3-pip aws-cli
          curl -sL https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
          curl -sL https://get.helm.sh/helm-v3.19.2-linux-amd64.tar.gz -o helm.tar.gz
          tar -xzf helm.tar.gz && mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64 helm.tar.gz
        '''
      }
    }
    
    stage('Validate IRSA') { 
      steps { sh 'aws sts get-caller-identity' } 
    }
    
    stage('Checkout') { 
      steps { checkout scm } 
    }
    
    stage('Prepare') {
      steps {
        script {
          // Capturar valores en variables locales
          def accountId = sh(returnStdout: true, script: 'aws sts get-caller-identity --query Account --output text').trim()
          def buildTag = sh(returnStdout: true, script: 'date +%Y%m%d-%H%M%S').trim()
          
          echo "INFO: AWS Account ID = ${accountId}"
          echo "INFO: Build Tag = ${buildTag}"
          
          env.ACCOUNT_ID = accountId
          env.BUILD_TAG = buildTag
          env.IMAGE = "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO}:${buildTag}"
          
          echo "SUCCESS: IMAGE = ${env.IMAGE}"
        }
      }
    }
    
    stage('Build') {
      steps {
        script {
          if (!env.IMAGE || env.IMAGE == 'null') {
            error("ERROR: La variable IMAGE no está definida correctamente")
          }
          
          echo "Building image: ${env.IMAGE}"
          
          container('tools') {
            sh """
              PASS=\$(aws ecr get-login-password --region ${env.AWS_REGION})
              REGISTRY="${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
              AUTH=\$(echo -n "AWS:\$PASS" | base64 -w 0)
              cat > \${WORKSPACE}/docker-config.json <<EOF
    {"auths":{"\${REGISTRY}":{"auth":"\${AUTH}"}}}
    EOF
            """
          }
          
          container('kaniko') {
            sh """
              mkdir -p /kaniko/.docker
              cp \${WORKSPACE}/docker-config.json /kaniko/.docker/config.json
              /kaniko/executor \\
                --context \${WORKSPACE}/app \\
                --dockerfile \${WORKSPACE}/app/Dockerfile \\
                --snapshot-mode=redo \\
                --use-new-run \\
                --destination ${env.IMAGE}
            """
          }
        }
      }
    }
    
    stage('Scan') {
      steps {
        container('trivy') { 
          sh "trivy image --severity HIGH,CRITICAL --exit-code 0 ${env.IMAGE} || true" 
        }
      }
    }
    
    stage('Push') { 
      steps { echo 'Image already pushed by Kaniko' } 
    }
    
    stage('Deploy') {
      steps {
        sh """
          aws eks update-kubeconfig --name ${env.EKS_CLUSTER} --region ${env.AWS_REGION}
          helm upgrade --install aw-app helm/aw-app \\
            --set image.repository=${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO} \\
            --set image.tag=${env.BUILD_TAG}
        """
      }
    }
    
    stage('Grafana Update') {
      environment { 
        GRAFANA_KEY = credentials('grafana-api-key') 
      }
      steps { 
        sh """
          bash scripts/grafana_dashboard_upsert.sh \\
            "${env.GRAFANA_URL}" \\
            "${GRAFANA_KEY}" \\
            "${env.GRAFANA_DASHBOARD_UID}" \\
            "${env.IMAGE}"
        """
      }
    }
  }
  
  post {
    success { echo "Pipeline succeeded: ${env.IMAGE}" }
    failure { echo 'Pipeline failed.' }
    always  { echo 'Pipeline finished.' }
  }
}