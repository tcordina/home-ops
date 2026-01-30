.PHONY: tf-plan tf-apply tf-destroy git-override encrypt-secret encrypt-all bootstrap-kubeconfig bootstrap-cluster bootstrap

INFRA_DIR = $(abspath ./infrastructure)
TF_DIR = $(INFRA_DIR)/terraform
K8S_DIR = $(abspath ./kubernetes)


# --- TERRAFORM --- #
tf-plan:
	cd $(TF_DIR) && terraform plan -var-file="$(TF_DIR)/secrets.auto.tfvars"

tf-apply:
	cd $(TF_DIR) && terraform apply -var-file="$(TF_DIR)/secrets.auto.tfvars" -auto-approve

tf-destroy:
	cd $(TF_DIR) && terraform destroy -var-file="$(TF_DIR)/secrets.auto.tfvars" -auto-approve


# --- GIT --- #
git-override:
	if git diff --quiet && git diff --staged --quiet; then \
		echo "✅ No changes to commit"; \
	else \
		echo "📝 Committing changes..."; \
		git add -A; \
		git commit --amend --no-edit; \
	fi
	@echo "⬆️  Pushing to remote..."
	git push origin main --force
	@echo "🔄 Reconciling Flux..."
	@flux reconcile source git flux-system


# --- SOPS --- #
encrypt-secret:
	sops --encrypt --output "$(ns)/secret.secrets.yaml" --config $(K8S_DIR)/.sops.yaml "$(ns)/secret.yaml";

encrypt-all:
	@find $(K8S_DIR) -name "secret.yaml" -type f | while read file; do \
		dir=$$(dirname "$$file"); \
		sops --encrypt --output "$$dir/secret.secrets.yaml" --config $(K8S_DIR)/.sops.yaml "$$file"; \
		echo "✅ Encrypted $$file -> $$dir/secret.secrets.yaml"; \
	done


# --- KUBERNETES BOOTSTRAP --- #
bootstrap-kubeconfig:
	@cd $(K8S_DIR)/.bootstrap && bash grab-kubeconfig.sh

bootstrap-cluster:
	@cd $(K8S_DIR)/.bootstrap && bash bootstrap.sh

bootstrap:
	bootstrap-kubeconfig bootstrap-cluster
