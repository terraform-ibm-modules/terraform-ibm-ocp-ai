#######################################################################################################################
# Resource Group
#######################################################################################################################
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.0"
  existing_resource_group_name = var.existing_resource_group_name
}

locals {
  prefix       = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  cluster_name = "${local.prefix}${var.cluster_name}"
}

########################################################################################################################
# VPC + Subnet + Public Gateway
########################################################################################################################
locals {
  subnet = {
    "zone-1" = [
      {
        name           = "${local.prefix}subnet"
        cidr           = var.address_prefix
        public_gateway = true
        acl_name       = "${local.prefix}acl"
      }
    ]
  }

  gateways = {
    "zone-1" = true
    "zone-2" = false
    "zone-3" = false
  }
  network_acl = {
    name                         = "${local.prefix}acl"
    add_ibm_cloud_internal_rules = true
    add_vpc_connectivity_rules   = true
    prepend_ibm_rules            = true
    rules = [{
      name        = "${local.prefix}inbound"
      action      = "allow"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "inbound"
      },
      {
        name        = "${local.prefix}outbound"
        action      = "allow"
        source      = "0.0.0.0/0"
        destination = "0.0.0.0/0"
        direction   = "outbound"
      }
    ]
  }
}

module "vpc" {
  source              = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version             = "8.9.2"
  resource_group_id   = module.resource_group.resource_group_id
  region              = var.region
  name                = "${local.prefix}vpc"
  prefix              = var.prefix
  subnets             = local.subnet
  network_acls        = [local.network_acl]
  use_public_gateways = local.gateways
}

locals {
  worker_pools = concat([

    {
      subnet_prefix    = "zone-1"
      pool_name        = "default"                            # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = var.default_worker_pool_machine_type ## minimum of 2 is allowed when using single zone
      operating_system = var.default_worker_pool_operating_system
      workers_per_zone = var.default_worker_pool_workers_per_zone
    }
    ],
    [for pool in var.additional_worker_pools : {
      subnet_prefix     = "zone-1"
      pool_name         = pool.pool_name
      machine_type      = pool.machine_type
      operating_system  = pool.operating_system
      workers_per_zone  = pool.workers_per_zone
      secondary_storage = pool.secondary_storage
      }
  ])
}

########################################################################################################################
# OCP VPC cluster (single zone)
########################################################################################################################
module "ocp_base" {
  source                              = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                             = "3.73.5"
  cluster_name                        = local.cluster_name
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  ocp_version                         = var.openshift_version
  ocp_entitlement                     = var.ocp_entitlement
  vpc_id                              = module.vpc.vpc_id
  vpc_subnets                         = module.vpc.subnet_detail_map
  worker_pools                        = local.worker_pools
  disable_outbound_traffic_protection = true
  access_tags                         = var.access_tags
  addons                              = var.addons
  manage_all_addons                   = var.manage_all_addons
}
