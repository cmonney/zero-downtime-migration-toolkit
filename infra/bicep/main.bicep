// main.bicep
//
// Top-level deployment for the zero-downtime-migration-toolkit Azure environment.
//
// This module orchestrates the deployment of:
//   - An Azure SQL Managed Instance hosting three databases (Source A, Source B, Target)
//   - An AKS cluster hosting the strangler API and load generator
//   - An Application Insights workspace for observability
//
// Parameters (to be defined):
//   - location: Azure region for all resources
//   - environmentName: short identifier used as a prefix for all resource names
//   - sqlAdminLogin / sqlAdminPassword: credentials for the SQL Managed Instance SA account
//   - acrName: name of the Azure Container Registry hosting the strangler API image
//
// Note: SQL Managed Instance provisioning takes 4–6 hours on a new subnet.
// Run this deployment well in advance of any cutover rehearsal.

// TODO: define parameters block
// TODO: deploy sql-managed-instance module
// TODO: deploy aks module
// TODO: deploy observability module
// TODO: output the strangler API URL and Application Insights connection string
