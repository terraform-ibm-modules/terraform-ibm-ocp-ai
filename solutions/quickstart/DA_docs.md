# Configuring complex inputs for OCP in IBM Cloud projects

Several optional input variables in the Red Hat OpenShift cluster [Deployable Architecture](https://cloud.ibm.com/catalog#deployable_architecture) use complex object types. You can specify these inputs when you configure your deployable architecture.

- [Add-ons](#options-with-addons) (`addons`)

## Options with `addons` <a name="options-with-addons"></a>

This variable configuration allows you to specify which Red Hat OpenShift add-ons to install on your cluster and the version of each add-on to use.

- Variable name: `addons`
- Type: An object representing Red Hat OpenShift cluster add-ons.
- Default value: An empty object (`{}`).

## Configuring Openshift-AI addon
- `openshift-ai` (optional): (Object) The Red Hat OpenShift AI add-on enables quick deployment of Red Hat OpenShift AI on a Red Hat OpenShift Cluster in IBM Cloud.
  - `version` (optional): The add-on version. Omit the version that you want to use as the default version.This is required when you want to update the add-on to specified version.
  - `parameters_json` (optional): Add-On parameters to pass in a JSON string format.

Please refer to [this](https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions) page for information on supported versions.

### Example
```hcl
{
  openshift-ai = {
    version         = "416"
  }
}
```
