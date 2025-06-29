# Configuring complex inputs for Red Hat OpenShift AI

Several optional input variables in the Red Hat OpenShift AI [Deployable Architecture](https://cloud.ibm.com/catalog#deployable_architecture) use complex object types. You can specify these variables when you configure your deployable architecture.

- [Add-ons](#options-with-addons) (`addons`)

## Options with `addons` <a name="options-with-addons"></a>

This variable configuration allows you to specify which Red Hat OpenShift add-ons to install on your cluster and the version of each add-on to use.

- Variable name: `addons`
- Type: An object representing Red Hat OpenShift cluster add-ons.
- Default value: a predefined object containing `openshift-ai` addon with version `416`.

## Configuring Openshift-AI addon
- `openshift-ai` (optional): (Object) The Red Hat OpenShift AI add-on enables quick deployment of Red Hat OpenShift AI on a Red Hat OpenShift Cluster in IBM Cloud.
  - `version` (optional): The add-on version. Omit the version that you want to use as the default version.This is required when you want to update the add-on to specified version.
  - `parameters_json` (optional): Add-On parameters to pass in a JSON string format. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#custom-options).

Please refer to [this](https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions) page for information on supported versions.

### Example
```hcl
{
  openshift-ai = {
    version         = "416"
  }
}
```
- [Additional Worker Pools](#options-with-additional-worker-pools) (`additional_worker_pools`)


## Options with additional_worker_pools <a name="options-with-additional-worker-pools"></a>

This variable defines the worker node pools for the Red Hat OpenShift cluster, with each pool having its own configuration settings.
> **Note**: At least one worker pool, whether default or additional, must have GPU enabled.

- Variable name: `additional_worker_pools`.
- Type: A list of objects. Each object represents a `worker_pool` configuration.
- Default value: A list with one object defining a worker pool with specific machine type,workers and Operating system.

### Options for additional_worker_pools

- `vpc_subnets` (optional): (List) A list of objects which specify which all subnets the worker pool should deploy its nodes in.
  - `id` (required): A unique identifier for the VPC subnet.
  - `zone` (required): The zone where the subnet is located.
  - `cidr_block` (required): This defines the IP address range for the subnet in CIDR notation.
- `pool_name` (required): The name of the worker pool.
- `machine_type` (required): The machine type for worker nodes. Preferred machine type is GPU.
- `workers_per_zone` (required): Number of worker nodes in each zone of the cluster.
- `operating_system` (required): The operating system installed on the worker nodes.
- `labels` (optional): A set of key-value labels assigned to the worker pool for identification.
- `minSize` (optional): The minimum number of worker nodes allowed in the pool.
- `maxSize` (optional): The maximum number of worker nodes allowed in the pool.
- `secondary_storage` (optional): The secondary storage attached to the worker nodes. Secondary storage is immutable and cannot be changed after provisioning.
- `enableAutoscaling` (optional): Set to `true` to enable automatic scaling of worker based on workload demand.
- `additional_security_group_ids` (optional): A list of security group IDs that are attached to the worker nodes for additional network security controls.

### Example for additional_worker_pools configuration

#### Example 1: Configuration with GPU Node
```hcl
[
    {
      pool_name        = "gpu"
      machine_type     = "gx3.16x80.l4"
      workers_per_zone = 2
      operating_system = "RHCOS"
    },
]
```
### Validation Rules

- Each worker node in worker pools must have at least 8 CPU cores.
- Each worker node in worker pools must have at least 32 GB of RAM.
- At least one worker pool must be GPU-enabled.
- For OpenShift version 4.18 or higher, each worker pool operating system must be RHCOS.
For further reference, please check [here](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui).
---
