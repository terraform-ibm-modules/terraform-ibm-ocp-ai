# Cloud Automation for Red Hat OpenShift AI

## Description

This solution simplifies the deployment of Red Hat OpenShift clusters on IBM Cloud, pre-integrating them with essential AI components. It accelerates the setup of machine learning environments, reducing the complexity of AI infrastructure management and allowing data scientists and developers to focus on model development and deployment.

**Note:** This offering depends on 'Cloud automation for Red Hat OpenShift VPC' to create a Red Hat OpenShift Cluster with AI.

For more information about Red Hat OpenShift AI please refer the [documentation](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-about&interface=ui)

## Features and Capabilities

-  **AI-enhanced Red Hat OpenShift Deployment**: Automates the provisioning of a fully configured Red Hat OpenShift Cluster on VPC with integrated AI capabilities on IBM Cloud. This includes optimized configurations for machine learning frameworks and simplified deployment of AI-driven applications.


## Architecture

![Red Hat OpenShift Cluster with AI](https://raw.githubusercontent.com/terraform-ibm-modules/terraform-ibm-ocp-ai/blob/main/reference-architecture/deployable-architecture-ocp-ai-cluster.svg)

This architecture consists of:

-   **Red Hat OpenShift Cluster on VPC**: A container platform for deploying and managing applications.
-   **OpenShift AI**: Pre-integrated components and configurations for machine learning and AI workloads.


## Dependencies

This solution depends on the `Cloud automation for Red Hat OpenShift Container Platform on VPC` to create Red Hat OpenShift cluster.
