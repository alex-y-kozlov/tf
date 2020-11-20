
# create res_ids[] of { type, resources[] } 
# - id - The ID of the Resource.
data "azurerm_resources" "res_ids" {
  count = length(var.rm_types)
  resource_group_name = var.rg_name
  type=var.rm_types[count.index]
}

locals {
  type_2_ids = { for ele in data.azurerm_resources.res_ids : ele.type => [for r in ele.resources: r.id] if length(ele.resources) > 0 }
  website_id_list = local.type_2_ids[ "Microsoft.Web/sites" ]
}

##########################################################################
# Process all website reaources

data "azurerm_monitor_diagnostic_categories" "website_diag_cat" {
  count = length(local.website_id_list)
  resource_id = local.website_id_list[count.index]
}

resource "azurerm_monitor_diagnostic_setting" "website_diag" {
  count = length(data.azurerm_monitor_diagnostic_categories.website_diag_cat)

  name = var.diag_name
  log_analytics_workspace_id = var.la_id
  target_resource_id = data.azurerm_monitor_diagnostic_categories.website_diag_cat[count.index].resource_id

  dynamic log {
    for_each = data.azurerm_monitor_diagnostic_categories.website_diag_cat[count.index].logs
    content {
        category = log.value
        enabled  = true
        retention_policy {
          enabled = true
          days    = 30
        }
    }
  }
  dynamic metric {
    for_each = data.azurerm_monitor_diagnostic_categories.website_diag_cat[count.index].metrics
    content {
        category = metric.value
        enabled  = true
        retention_policy {
          enabled = true
          days    = 360
        }
    }
  }
}

##########################################################################
# Process all except website reaources : all resource of the same type share diag-categories

locals {
  # create   non_website_list[] of { type, rm_id0, rm_ids[] } for all non-"Microsoft.Web/sites"
  non_website_list = [ for k,v in local.type_2_ids : { type_name = k, rm_id0 = v[0], rm_ids = v } if k != "Microsoft.Web/sites" ]
}

##########################################################################
# Process all non website reaources

data "azurerm_monitor_diagnostic_categories" "non_website_diag_cat" {
  count = length(local.non_website_list)
  resource_id = local.non_website_list[count.index].rm_id0
}

locals {
  id0_2_diag_cat = { for ele in data.azurerm_monitor_diagnostic_categories.non_website_diag_cat : ele.resource_id => ele }

  non_website_2_instrument = flatten([
    for x in local.non_website_list : [
      for y in x.rm_ids : { res_id = y, diag_cat = local.id0_2_diag_cat[ x.rm_id0 ]}
    ]
  ])
}

resource "azurerm_monitor_diagnostic_setting" "non_website_diag" {
  count = length(local.non_website_2_instrument)

  name               = var.diag_name
  log_analytics_workspace_id = var.la_id
  target_resource_id = local.non_website_2_instrument[count.index].res_id

  dynamic log {
    for_each = sort(local.non_website_2_instrument[count.index].diag_cat.logs)
    content {
        category = log.value
        enabled  = true

        retention_policy {
          enabled = true
          days    = 30
        }
    }
  }
  dynamic metric {
    for_each = sort(local.non_website_2_instrument[count.index].diag_cat.metrics)
    content {
        category = metric.value
        enabled  = true

        retention_policy {
          enabled = true
          days    = 360
        }
    }
  }
}
