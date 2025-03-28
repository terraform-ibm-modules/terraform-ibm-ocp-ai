# Cloud Automation for Red Hat OpenShift AI

## Description

This solution simplifies the deployment of Red Hat OpenShift clusters on IBM Cloud, pre-integrating them with essential AI components. It accelerates the setup of machine learning environments, reducing the complexity of AI infrastructure management and allowing data scientists and developers to focus on model development and deployment.

**Note:** This offering depends on 'Cloud automation for Red Hat OpenShift VPC' to create a base OCP cluster.

For more information about Red Hat OpenShift AI please refer the [documentation](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-about&interface=ui)

## Features and Capabilities

-  **AI-Enhanced Red Hat OpenShift Deployment**: Automates the provisioning of a fully configured Red Hat OpenShift Cluster on VPC with integrated AI capabilities on IBM Cloud. This includes optimized configurations for machine learning frameworks and simplified deployment of AI-driven applications.


## Architecture

![Red Hat OpenShift Cluster with AI](https://raw.githubusercontent.com/terraform-ibm-modules/terraform-ibm-ocp-ai/blob/main/reference-architecture/deployable-architecture-ocp-cluster-qs.svg)

This architecture consists of:

-   **Red Hat OpenShift Cluster on VPC**: A container platform for deploying and managing applications.
-   **OpenShift AI**: Pre-integrated components and configurations for machine learning and AI workloads.

## Configuration

The following input variables can be configured:

-   `default_worker_pool_machine_type`: Specifies the machine type for the default worker pool. This determines the CPU, memory, and disk resources available to each worker node. Choose a machine type that suits your AI workload's computational requirements.
-   `default_worker_pool_workers_per_zone`: Defines the number of worker nodes to provision in each zone for the default worker pool. Increasing the number of workers enhances the cluster's compute capacity and resilience.
-   `default_worker_pool_operating_system`: Selects the operating system for the worker nodes in the default worker pool.
-   `additional_worker_pools`: Allows you to define additional worker pools with custom configurations, such as different machine types or operating systems, to accommodate diverse workload requirements within the cluster.

## Dependencies

This solution depends on the `Cloud automation for Red Hat OpenShift VPC` to create Red Hat Openshift cluster.
