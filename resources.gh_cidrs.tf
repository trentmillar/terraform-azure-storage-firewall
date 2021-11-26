data "http" "action_cidrs" {
  url = "https://api.github.com/meta"
  request_headers = {
    Accept = "application/json"
  }
}

locals {
  # maximum ip networking rules allowed for a Storage Account
  max_cidrs_in_stg_act_fw = 200

  # all the possible GitHub action ranges 
  action_cidrs = [for ip in jsondecode(data.http.action_cidrs.body).actions :
    ip if length(regexall("(([0-9]{0,3})(\\.|(\\/[0-9]{0,2})$)){4}", ip)) == 1
  ]

  # class A's are too broad - using class B's instead
  class_As = { for k, v in {
    for cidr in distinct([for cidr in local.action_cidrs : regex("^\\d{1,3}", cidr)]) : cidr => []
    } : k => [
    for cidr in local.action_cidrs : cidr if regex("^\\d{1,3}", cidr) == k
  ] }

  # create all the class B's based on the GitHub Action CIDRs
  class_Bs = { for k, v in {
    for cidr in distinct([for cidr in local.action_cidrs : regex("(^(\\d{1,3}|\\.){3})", cidr)[0]]) : cidr => []
    } : k => [
    for cidr in local.action_cidrs : cidr if regex("(^(\\d{1,3}|\\.){3})", cidr)[0] == k
  ] }

  # if the offset is <=0 then we have room in the Stg.Act. FW to fit all the class B's  
  offset = length(local.class_Bs) - local.max_cidrs_in_stg_act_fw

  # find the class B's that can roll up to a class A to fit into the FW
  drops = local.offset >= 0 ? [for k, v in {
    for e in [for e in keys(local.class_Bs) : e] : regex("^\\d{1,3}", e) => regex("^\\d{1,3}", e)...
  } : k if length(v) > local.offset] : []

  # create the cidrs that will fit into the FW's allowed IPs
  cidrs = length(local.drops) == 0 ? {
    for k, v in local.class_Bs : format("%s.0.0/16", k) => 1
    } : (
    merge({
      for k, v in local.class_Bs : format("%s.0.0/16", k) => 1 if regex("^\\d{1,3}", k) != regex("^\\d{1,3}", element(local.drops, length(local.drops) - 1))
      }, {
      format("%s.0.0.0/8", regex("^\\d{1,3}", element(local.drops, length(local.drops) - 1))) = 1
    })
  )
}

output "action_cidrs" {
  value = local.cidrs
}
