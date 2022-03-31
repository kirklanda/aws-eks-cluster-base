terraform init \
-backend-config="address=https://gitlab.com/api/v4/projects/<<your id goes here>>/terraform/state/" \
-backend-config="lock_address=https://gitlab.com/api/v4/projects/<<your id goes here>>/terraform/state/some_state/lock" \
-backend-config="unlock_address=https://gitlab.com/api/v4/projects/<<your id goes here>>/terraform/state/some_state/lock" \
-backend-config=username="Terraform_Backend" \
-backend-config=password="<<your gitlab PAT goes here>>" \
-backend-config=lock_method=POST \
-backend-config=unlock_method=DELETE \
-backend-config=retry_wait_min=5
