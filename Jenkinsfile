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
    volumeMounts:
    - name: workspace
      mountPath: /workspace
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ['/busybox/sh','-c','sleep 3600']
    tty: true
    volumeMounts:
    - name: workspace
      mountPath: /workspace
    env:
    - name: DOCKER_CONFIG
      value: /kaniko/.docker/
  - name: trivy
    image: aquasec/trivy:latest
    command: ['sh','-c','sleep 3600']
    tty: true
    volumeMounts:
    - name: workspace
      mountPath: /workspace
  volumes:
  - name: workspace
    emptyDir: {}
"""
      defaultContainer 'tools'
    }
  }
  environment {
    AWS_REGION = 'us-east-1'
    ECR_REPO   = 'aw-bootcamp-app'
    ACCOUNT_ID = '' 
    BUILD_TAG  = '' 
    IMAGE      = ''
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
          # kubectl
          curl -sL https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
          # helm
          HELM_VER=$(curl -s https://get.helm.sh | grep -o 'helm-v3[^" ]*linux-amd64.tar.gz' | head -n1 || echo helm-v3.19.2-linux-amd64.tar.gz)
          curl -sL https://get.helm.sh/helm-v3.19.2-linux-amd64.tar.gz -o helm.tar.gz
          tar -xzf helm.tar.gz && mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64 helm.tar.gz
        '''
      }
    }
    stage('Validate IRSA') { steps { sh 'aws sts get-caller-identity' } }
    stage('Checkout') { steps { checkout scm } }
    stage('Prepare') {
      steps {
        script {
          def accountId = sh(returnStdout: true, script: 'aws sts get-caller-identity --query Account --output text').trim()
          echo "INFO: AWS Account ID capturado = ${accountId}"
          
          def buildTag = sh(returnStdout: true, script: 'date +%Y%m%d-%H%M%S').trim()
          echo "INFO: Build Tag capturado = ${buildTag}"

          if (accountId && buildTag) {
            env.IMAGE = "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO}:${buildTag}"
            echo "SUCCESS: Nombre de la imagen construido: ${env.IMAGE}"
          } else {
            error("Error crítico: No se pudo obtener el AWS Account ID o el Build Tag.")
          }
        }
        sh 'echo "Verificación final: La variable IMAGE es $IMAGE"'
      }
    }
    stage('Build') {
      steps {
        script {
          if (!env.IMAGE) {
            error("ERROR: La variable IMAGE no está definida")
          }
          echo "Building image: ${env.IMAGE}"
          
          container('tools') {
            sh """
              PASS=\$(aws ecr get-login-password --region ${env.AWS_REGION})
              REGISTRY="${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
              AUTH=\$(echo -n "AWS:\$PASS" | base64)
              cat > /workspace/docker-config.json <<EOF
    { "auths": { "\${REGISTRY}": { "auth": "\${AUTH}" } } }
    EOF
            """
          }
          
          container('kaniko') {
            sh """
              mkdir -p /kaniko/.docker
              cp /workspace/docker-config.json /kaniko/.docker/config.json
              /kaniko/executor \\
                --context app \\
                --dockerfile app/Dockerfile \\
                --snapshotMode=redo \\
                --use-new-run \\
                --destination ${env.IMAGE}
            """
          }
        }
      }
    }
    stage('Scan') {
      steps {
        container('trivy') { sh 'trivy image --severity HIGH,CRITICAL --exit-code 0 --skip-db-update $IMAGE || true' }
      }
    }
    stage('Push') { steps { echo 'Image already pushed by Kaniko' } }
    stage('Deploy') {
      steps {
        sh 'aws eks update-kubeconfig --name $EKS_CLUSTER --region $AWS_REGION'
        sh 'helm upgrade --install aw-app helm/aw-app --set image.repository=${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO} --set image.tag=$BUILD_TAG'
      }
    }
    stage('Grafana Update') {
      environment { GRAFANA_KEY = credentials('grafana-api-key') }
      steps { sh 'bash scripts/grafana_dashboard_upsert.sh "$GRAFANA_URL" "$GRAFANA_KEY" "$GRAFANA_DASHBOARD_UID" "$IMAGE"' }
    }
  }
  post {
    success { echo "Pipeline succeeded: $IMAGE" }
    failure { echo 'Pipeline failed.' }
    always  { echo 'Pipeline finished (images listed by Kaniko build logs).' }
  }
}