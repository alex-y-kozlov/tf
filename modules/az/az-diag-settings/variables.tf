variable "rg_name" {
    type = string
    description = "RG where all resources to be instrumented with diagnostics reside"
}

variable "rm_types" { 
    type = list(string)
    description = "List of resource types to instrument"
    default = [
        "Microsoft.Web/sites",
        "Microsoft.Storage/storageAccounts",
        "Microsoft.Sql/servers",
        "Microsoft.Sql/servers/databases",
        "Microsoft.ServiceBus/namespaces",
        "Microsoft.Network/trafficmanagerprofiles",
        "Microsoft.Network/virtualNetworkGateways",
        "Microsoft.Network/frontdoors"
    ]
}

variable "la_id" {
    type = string
    description = "LA Workspace Id"
}

variable "diag_name" {
    type = string
    description = "Name of diag setting"
    default="diag-settings"
}
