added all three aws secret to 

1. Add Secrets to the Infra Repo

Go to your Infra repository on GitHub (the repo where you have this Nightly Build workflow).

Click on Settings → Secrets and variables → Actions → Secrets.

Click "New repository secret".

the code is flexible enought to run any env as long as we have valid images


kubectl get pod <pod-name> -n <namespace> -o jsonpath="{.spec.containers[*].image}"
to get the pod image version
>kubectl get pod frontend-7f69dd57d4-67t8x -n blue -o jsonpath="{.spec.containers[*].image}"
179235553979.dkr.ecr.us-east-1.amazonaws.com/frontend:v1

we need to update hostinger nameserver to route53 values one.
get the HOSTED_ZONE_ID and update it in secrets.

