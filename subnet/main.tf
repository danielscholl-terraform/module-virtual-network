##############################################################
# This module allows the creation of a Virtual Network Subnet
##############################################################

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_type
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.cidrs

  enforce_private_link_endpoint_network_policies = var.enforce_private_link_endpoint_network_policies
  enforce_private_link_service_network_policies  = var.enforce_private_link_service_network_policies

  service_endpoints = var.service_endpoints

  dynamic "delegation" {
    for_each = var.delegations
    content {
      name = delegation.key
      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  count = (var.create_network_security_group ? 1 : 0)
  depends_on = [
    azurerm_network_security_rule.deny_all_inbound,
    azurerm_network_security_rule.deny_all_outbound,
    azurerm_network_security_rule.allow_lb_inbound,
    azurerm_network_security_rule.allow_internet_outbound,
    azurerm_network_security_rule.allow_vnet_outbound,
    azurerm_network_security_rule.allow_https_inbound,
    azurerm_network_security_rule.allow_gateway_manager_inbound,
    azurerm_network_security_rule.allow_load_balancer_inbound,
    azurerm_network_security_rule.allow_bastion_host_inbound,
    azurerm_network_security_rule.allow_ssh_rdp_outbound,
    azurerm_network_security_rule.allow_cloud_outbound,
    azurerm_network_security_rule.allow_bastion_host_outbound,
    azurerm_network_security_rule.allow_information_outbound
  ]

  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.0.id
}

resource "azurerm_network_security_group" "nsg" {
  count = (var.create_network_security_group ? 1 : 0)

  name                = "${var.subnet_type}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.resource_tags, { subnet_type = lookup(local.allowed_subnet_info, var.subnet_type, var.subnet_type) })
}

resource "azurerm_network_security_rule" "deny_all_inbound" {
  count = ((var.create_network_security_group && var.configure_nsg_rules) ? 1 : 0)

  name                        = "DenyAllInbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "deny_all_outbound" {
  count = ((var.create_network_security_group && var.configure_nsg_rules) ? 1 : 0)

  name                        = "DenyAllOutbound"
  priority                    = 4096
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "allow_lb_inbound" {
  count = ((var.create_network_security_group && var.configure_nsg_rules && var.allow_lb_inbound) ? 1 : 0)

  name                        = "AllowAzureLoadBalancerIn"
  priority                    = 4095
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "allow_internet_outbound" {
  count = ((var.create_network_security_group && var.configure_nsg_rules && var.allow_internet_outbound) ? 1 : 0)

  name                        = "AllowInternetOut"
  priority                    = 4095
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "allow_vnet_inbound" {
  count = ((var.create_network_security_group && var.configure_nsg_rules && var.allow_vnet_inbound) ? 1 : 0)

  name                        = "AllowVnetIn"
  priority                    = 4094
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "allow_vnet_outbound" {
  count = ((var.create_network_security_group && var.configure_nsg_rules && var.allow_vnet_outbound) ? 1 : 0)

  name                        = "AllowVnetOut"
  priority                    = 4094
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

## Azure Bation Rules
resource "azurerm_network_security_rule" "allow_https_inbound" {
  count = ((var.subnet_type == "AzureBastionSubnet") ? 1 : 0)

  name                        = "AllowHttpsInBound"
  priority                    = 100
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "Internet"
  destination_port_range      = "443"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "allow_gateway_manager_inbound" {
  count = ((var.subnet_type == "AzureBastionSubnet") ? 1 : 0)

  name                        = "AllowGatewayManagerInBound"
  priority                    = 110
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "GatewayManager"
  destination_port_range      = "443"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "allow_load_balancer_inbound" {
  count = ((var.subnet_type == "AzureBastionSubnet") ? 1 : 0)

  name                        = "AllowLoadBalancerInBound"
  priority                    = 120
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_port_range      = "443"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "allow_bastion_host_inbound" {
  count = ((var.subnet_type == "AzureBastionSubnet") ? 1 : 0)

  name                        = "AllowBastionHostCommunicationInBound"
  priority                    = 130
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_port_ranges     = ["8080", "5701"]
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "allow_ssh_rdp_outbound" {
  count = ((var.subnet_type == "AzureBastionSubnet") ? 1 : 0)

  name                        = "AllowSshRdpOutBound"
  priority                    = 100
  access                      = "Allow"
  direction                   = "Outbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_ranges     = ["22", "3389"]
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "allow_cloud_outbound" {
  count = ((var.subnet_type == "AzureBastionSubnet") ? 1 : 0)

  name                        = "AllowAzureCloudCommunicationOutBound"
  priority                    = 110
  access                      = "Allow"
  direction                   = "Outbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "443"
  destination_address_prefix  = "AzureCloud"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "allow_bastion_host_outbound" {
  count = ((var.subnet_type == "AzureBastionSubnet") ? 1 : 0)

  name                        = "AllowBastionHostCommunicationOutBound"
  priority                    = 120
  access                      = "Allow"
  direction                   = "Outbound"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_port_ranges     = ["8080", "5701"]
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}

resource "azurerm_network_security_rule" "allow_information_outbound" {
  count = ((var.subnet_type == "AzureBastionSubnet") ? 1 : 0)

  name                        = "AllowGetSessionInformationOutBound"
  priority                    = 130
  access                      = "Allow"
  direction                   = "Outbound"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_ranges     = ["80", "443"]
  destination_address_prefix  = "Internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
}
