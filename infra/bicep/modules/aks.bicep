// modules/aks.bicep
//
// Deploys an Azure Kubernetes Service cluster to host the strangler API and load generator.
//
// The cluster has two node pools:
//   - System pool: Standard_D2s_v3 nodes, for AKS system workloads.
//   - Application pool: Standard_D4s_v3 nodes, for the strangler API and load generator pods.
//
// The strangler API is deployed as a Deployment with a single replica during the cutover rehearsal;
// scaling to multiple replicas requires confirming that the feature-flag read is consistent across
// instances (a shared external store, not the in-process default).
//
// The load generator is deployed as a Job, not a Deployment, so that the cutover SLO test can
// observe its completion and collect its summary report.
//
// Parameters (to be defined):
//   - clusterName: name of the AKS resource
//   - location: Azure region
//   - nodeCount: number of nodes in the application pool (default: 2)
//   - acrId: resource ID of the Azure Container Registry to attach to the cluster

// TODO: define parameters block
// TODO: deploy Microsoft.ContainerService/managedClusters resource
// TODO: attach ACR to the cluster using the acrPull role assignment
// TODO: output the kubelet identity object ID and the cluster FQDN
