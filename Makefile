.PHONY: tf-plan tf-apply tf-destroy flux-pull flux-push flux-update encrypt-secrets

TF_DIR := $(abspath ./infrastructure)
FLUX_DIR = $(abspath ./flux)


# --- TERRAFORM --- #
tf-plan:
	cd $(TF_DIR) && terraform plan -var-file="$(TF_DIR)/secrets.auto.tfvars"

tf-apply:
	cd $(TF_DIR) && terraform apply -var-file="$(TF_DIR)/secrets.auto.tfvars" -auto-approve

tf-destroy:
	cd $(TF_DIR) && terraform destroy -var-file="$(TF_DIR)/secrets.auto.tfvars" -auto-approve


# --- FLUX --- #
flux-pull:
	@echo "⬇️ Pulling latest changes..."
	@cd $(FLUX_DIR) && git pull origin main

flux-push:
	@cd $(FLUX_DIR) && \
	if git diff --quiet && git diff --staged --quiet; then \
		echo "✅ No changes to commit"; \
	else \
		echo "📝 Committing changes..."; \
		git add -A; \
		git commit -m "flux: update configuration [$(shell date '+%Y-%m-%d %H:%M')]"; \
	fi
	@echo "⬆️  Pushing to remote..."
	@cd $(FLUX_DIR) && git push origin main
	@echo "🔄 Reconciling Flux..."
	@flux reconcile source git flux-system

flux-update: flux-pull flux-push
	@echo "✨ Flux updated successfully!"

flux-override:
	@cd $(FLUX_DIR) && \
	if git diff --quiet && git diff --staged --quiet; then \
		echo "✅ No changes to commit"; \
	else \
		echo "📝 Committing changes..."; \
		git add -A; \
		git commit --amend --no-edit; \
	fi
	@echo "⬆️  Pushing to remote..."
	@cd $(FLUX_DIR) && git push origin main --force
	@echo "🔄 Reconciling Flux..."
	@flux reconcile source git flux-system

# --- SOPS --- #
encrypt-secrets:
	@find $(FLUX_DIR) -name "secret.yaml" -type f | while read file; do \
		dir=$$(dirname "$$file"); \
		sops --encrypt --output "$$dir/secret.secrets.yaml" --config $(FLUX_DIR)/.sops.yaml "$$file"; \
		echo "✅ Encrypted $$file -> $$dir/secret.secrets.yaml"; \
	done