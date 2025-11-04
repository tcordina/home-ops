tf_dir := $(abspath ./infrastructure)
flux_dir = $(abspath ./flux)


# --- TERRAFORM --- #
tf-plan:
	cd $(tf_dir)/$(ns) && terraform plan -var-file="$(tf_dir)/secrets.auto.tfvars"

tf-apply:
	cd $(tf_dir)/$(ns) && terraform apply -var-file="$(tf_dir)/secrets.auto.tfvars" -auto-approve

tf-destroy:
	cd $(tf_dir)/$(ns) && terraform destroy -var-file="$(tf_dir)/secrets.auto.tfvars" -auto-approve


# --- FLUX --- #
flux-update:
	cd $(flux_dir) && git add . && git commit -m "." && git push origin main && flux reconcile source git flux-system