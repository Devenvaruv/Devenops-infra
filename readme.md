added all three aws secret to 

1. Add Secrets to the Infra Repo

Go to your Infra repository on GitHub (the repo where you have this Nightly Build workflow).

Click on Settings → Secrets and variables → Actions → Secrets.

Click "New repository secret".

create ECR repo
auth-service
frontend

the code is flexible enought to run any env as long as we have valid images


for blue green, helm charts

frontend-green
helm upgrade --install frontend-green ./charts/frontend \
  --values ./charts/frontend/values-green.yaml \
  --namespace production

auth-service-green
helm upgrade --install auth-service-green ./charts/auth-service \
  --values ./charts/auth-service/values-green.yaml \
  --namespace production


