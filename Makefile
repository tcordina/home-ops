.PHONY: tf-plan tf-apply tf-destroy
.PHONY: git-override
.PHONY: encrypt-secret encrypt-all
.PHONY: bootstrap-kubeconfig bootstrap-cluster bootstrap bootstrap-dir
.PHONY: shell
.PHONY: renovate-validate renovate-dryrun

INFRA_DIR = $(abspath ./infrastructure)
TF_DIR = $(INFRA_DIR)/terraform
K8S_DIR = $(abspath ./kubernetes)


# --- TERRAFORM --- #

# e.g. make tf-xxx dir=haproxy
tf-plan:
	cd $(TF_DIR)/$(dir) && terraform plan -var-file="$(TF_DIR)/$(dir)/secrets.auto.tfvars"

tf-apply:
	cd $(TF_DIR)/$(dir) && terraform apply -var-file="$(TF_DIR)/$(dir)/secrets.auto.tfvars" -auto-approve

tf-destroy:
	cd $(TF_DIR)/$(dir) && terraform destroy -var-file="$(TF_DIR)/$(dir)/secrets.auto.tfvars" -auto-approve


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
	git push origin main --force-with-lease
	@echo "🔄 Reconciling Flux..."
	@flux reconcile source git flux-system


# --- SOPS --- #

# e.g. make encrypt-secret path=./kubernetes/apps/{namespace}/{appname}/app/secret.yaml
encrypt-secret:
	sops --encrypt --output "$(path)/secret.secrets.yaml" --config $(K8S_DIR)/.sops.yaml "$(path)/secret.yaml";


# --- KUBERNETES BOOTSTRAP --- #

bootstrap-kubeconfig:
	@cd $(K8S_DIR)/.bootstrap && bash grab-kubeconfig.sh

bootstrap-cluster:
	@cd $(K8S_DIR)/.bootstrap && bash bootstrap.sh

bootstrap:
	bootstrap-kubeconfig bootstrap-cluster

# e.g. make bootstrap-dir ns=namespace app=newapp
bootstrap-dir:
	mkdir -p $(K8S_DIR)/apps/$(ns)/$(app)/app
	touch -a $(K8S_DIR)/apps/$(ns)/namespace.yaml
	touch -a $(K8S_DIR)/apps/$(ns)/kustomization.yaml
	touch -a $(K8S_DIR)/apps/$(ns)/$(app)/ks.yaml
	touch -a $(K8S_DIR)/apps/$(ns)/$(app)/app/helm-release.yaml


# --- SSH --- #

# e.g. make shell node=1
shell:
	@ssh -o ProxyJump=root@192.168.1.21 ubuntu@10.0.1.1$(node)


# --- RENOVATE --- #
renovate-validate:
	@npx --yes --package renovate@43 -- renovate-config-validator

renovate-dryrun:
	@npx --yes renovate@43 --platform=local --onboarding=false --dry-run=full