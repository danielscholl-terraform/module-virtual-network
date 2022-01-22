# Module Azure Virtual Network

A terraform module that provisions networks with the following characteristics:

- Vnet and Subnets with DNS Prefix


## Usage

```
module "resource_group" {
  source = "git::https://github.com/danielscholl-terraform/module-resource-group?ref=v1.0.0"

  name     = "iac-terraform"
  location = "eastus2"
}


module "virtual-network" {
  source     = "git::https://github.com/danielscholl-terraform/module-virtual-network?ref=v1.0.0"
  depends_on = [module.resource_group]

  name                = "iac-terraform-vnet-${module.resource_group.random}"
  resource_group_name = module.resource_group.name

  dns_servers = ["8.8.8.8"]
  address_space = ["10.0.1.0/24"]
  subnets = {
    Web-Tier = {
      cidrs = ["10.0.1.0/26"]

      allow_vnet_inbound      = true
      allow_vnet_outbound     = true
      allow_internet_outbound = true
    }
    App-Tier = {
      cidrs = ["10.0.1.64/26"]

      allow_vnet_inbound  = true
      allow_vnet_outbound = true
    }
    Data-Tier = {
      cidrs = ["10.0.1.128/26"]

      allow_vnet_inbound = true
    }
    Mgmt-Tier = {
      cidrs = ["10.0.1.192/27"]

      create_network_security_group = true
    }
    GatewaySubnet = {
      cidrs = ["10.0.1.224/28"]

      create_network_security_group = false
    }
  }

  # Tags
  resource_tags = {
    iac = "terraform"
  }
}
```

<!--- BEGIN_TF_DOCS --->
## Providers

| Name | Version |
|------|---------|
| azurerm | >= 2.90.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| address\_space | CIDRs for virtual network | `list(string)` | n/a | yes |
| aks\_subnets | AKS subnets | <pre>map(object({<br>    private = any<br>    public  = any<br>    route_table = object({<br>      disable_bgp_route_propagation = bool<br>      routes                        = map(map(string))<br>      # keys are route names, value map is route properties (address_prefix, next_hop_type, next_hop_in_ip_address)<br>      # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table#route<br>    })<br>  }))</pre> | n/a | yes |
| dns\_servers | If applicable, a list of custom DNS servers to use inside your virtual network.  Unset will use default Azure-provided resolver | `list(string)` | n/a | yes |
| enforce\_subnet\_names | enforce subnet names based on naming\_rules variable | `bool` | `false` | no |
| name | The name of the Virtual Network. (Optional) - names override | `any` | n/a | yes |
| names | Names to be applied to resources (inclusive) | <pre>object({<br>    environment = string<br>    location    = string<br>    product     = string<br>  })</pre> | <pre>{<br>  "environment": "tf",<br>  "location": "eastus2",<br>  "product": "iac"<br>}</pre> | no |
| naming\_rules | naming conventions yaml file | `string` | `""` | no |
| peer\_defaults | Maps of peer arguments. | <pre>object({<br>    id                           = string<br>    allow_virtual_network_access = bool<br>    allow_forwarded_traffic      = bool<br>    allow_gateway_transit        = bool<br>    use_remote_gateways          = bool<br>  })</pre> | <pre>{<br>  "allow_forwarded_traffic": false,<br>  "allow_gateway_transit": false,<br>  "allow_virtual_network_access": true,<br>  "id": null,<br>  "use_remote_gateways": false<br>}</pre> | no |
| peers | Peer virtual networks.  Keys are names, allowed values are same as for peer\_defaults. Id value is required. | `any` | `{}` | no |
| resource\_group\_name | The name of an existing resource group. | `string` | n/a | yes |
| resource\_tags | Map of tags to apply to taggable resources in this module. By default the taggable resources are tagged with the name defined above and this map is merged in | `map(string)` | `{}` | no |
| route\_tables | Maps of route tables | <pre>map(object({<br>    disable_bgp_route_propagation = bool<br>    use_inline_routes             = bool # Setting to true will revert any external route additions.<br>    routes                        = map(map(string))<br>    # keys are route names, value map is route properties (address_prefix, next_hop_type, next_hop_in_ip_address)<br>    # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table#route<br>  }))</pre> | `{}` | no |
| subnet\_defaults | Maps of CIDRs, policies, endpoints and delegations | <pre>object({<br>    cidrs                                          = list(string)<br>    enforce_private_link_endpoint_network_policies = bool<br>    enforce_private_link_service_network_policies  = bool<br>    service_endpoints                              = list(string)<br>    delegations = map(object({<br>      name    = string<br>      actions = list(string)<br>    }))<br>    create_network_security_group = bool # create/associate network security group with subnet<br>    configure_nsg_rules           = bool # deny ingress/egress traffic and configure nsg rules based on below parameters<br>    allow_internet_outbound       = bool # allow outbound traffic to internet (configure_nsg_rules must be set to true)<br>    allow_lb_inbound              = bool # allow inbound traffic from Azure Load Balancer (configure_nsg_rules must be set to true)<br>    allow_vnet_inbound            = bool # allow all inbound from virtual network (configure_nsg_rules must be set to true)<br>    allow_vnet_outbound           = bool # allow all outbound from virtual network (configure_nsg_rules must be set to true)<br>    route_table_association       = string<br>  })</pre> | <pre>{<br>  "allow_internet_outbound": false,<br>  "allow_lb_inbound": false,<br>  "allow_vnet_inbound": false,<br>  "allow_vnet_outbound": false,<br>  "cidrs": [],<br>  "configure_nsg_rules": true,<br>  "create_network_security_group": true,<br>  "delegations": {},<br>  "enforce_private_link_endpoint_network_policies": false,<br>  "enforce_private_link_service_network_policies": false,<br>  "route_table_association": null,<br>  "service_endpoints": []<br>}</pre> | no |
| subnets | Map of subnets. Keys are subnet names, Allowed values are the same as for subnet\_defaults | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| aks | Virtual network information matching AKS module input. |
| route\_tables | Maps of custom route tables. |
| subnet | Map of subnet data objects. |
| subnet\_nsg\_ids | Map of subnet ids to associated network\_security\_group ids. |
| subnet\_nsg\_names | Map of subnet names to associated network\_security\_group names. |
| subnets | Maps of subnet info. |
| vnet | Virtual network data object. |
<!--- END_TF_DOCS --->
