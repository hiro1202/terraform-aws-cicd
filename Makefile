.PHONY: init fmt validate test tflint trivy ci

ci: fmt validate test tflint trivy

init:
	terraform init -backend=false

fmt:
	terraform fmt -recursive -diff

validate: init
	terraform validate

test: init
	terraform test

tflint:
	tflint --init && tflint --recursive

trivy:
	trivy config .
