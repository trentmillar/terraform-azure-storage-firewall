data "http" "action_cidrs" {
  url = "https://api.github.com/meta"
  request_headers = {
    Accept = "application/json"
  }
}

locals {
  max_cidrs_in_stg_act_fw = 200
  action_cidrs = [for ip in jsondecode(data.http.action_cidrs.body).actions :
    ip if length(regexall("(([0-9]{0,3})(\\.|(\\/[0-9]{0,2})$)){4}", ip)) == 1
  ]
}

output "action_cidrs" {
  value = local.action_cidrs
}

output "action_cidrs_count" {
  value = length(local.action_cidrs)
}

output "will_gh_cidrs_fit_in_fw" {
  value = length(local.action_cidrs) <= local.max_cidrs_in_stg_act_fw
}
