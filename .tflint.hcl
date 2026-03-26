# AWS固有のチェック
plugin "aws" {
  enabled = true
  version = "0.35.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# 命名規則: スネークケース（my_resource）を強制
rule "terraform_naming_convention" {
  enabled = true
}

# variableにdescriptionがあるかチェック
rule "terraform_documented_variables" {
  enabled = true
}

# outputにdescriptionがあるかチェック
rule "terraform_documented_outputs" {
  enabled = true
}

# variableにtypeが指定されているかチェック
rule "terraform_typed_variables" {
  enabled = true
}

# 未使用のvariable/data/localsを検出
rule "terraform_unused_declarations" {
  enabled = true
}

# モジュールの標準構成（main.tf / variables.tf / outputs.tf）を強制
rule "terraform_standard_module_structure" {
  enabled = true
}
