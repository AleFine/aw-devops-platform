pipeline {
  agent any
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
          if ! command -v aws >/dev/null; then curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && unzip -q awscliv2.zip && ./aws/install && rm -rf awscliv2.zip aws; fi
          if ! command -v kubectl >/dev/null; then curl -sL https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl; fi
          if ! command -v helm >/dev/null; then curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash; fi
          if ! command -v trivy >/dev/null; then curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin; fi
        '''
      }
    }
    stage('Validate IRSA') { steps { sh 'aws sts get-caller-identity' } }
    stage('Checkout') { steps { checkout scm } }
    stage('Prepare') {
      steps {
        script {
          ACCOUNT_ID = sh(returnStdout: true, script: 'aws sts get-caller-identity --query Account --output text').trim()
          BUILD_TAG  = sh(returnStdout: true, script: 'date +%Y%m%d-%H%M%S').trim()
          IMAGE      = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${BUILD_TAG}"
          env.ACCOUNT_ID = ACCOUNT_ID; env.BUILD_TAG = BUILD_TAG; env.IMAGE = IMAGE
        }
        sh 'echo IMAGE=$IMAGE'
        // IRSA provides permissions; no static credentials needed
        sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com'
      }
    }
    stage('Build') { steps { sh 'docker build -t $IMAGE app' } }
    stage('Scan') { steps { sh 'trivy image --severity HIGH,CRITICAL --exit-code 0 --skip-db-update $IMAGE || true' } }
    stage('Push') { steps { sh 'docker push $IMAGE' } }
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
    always  { sh 'docker images | grep $ECR_REPO || true' }
  }
}