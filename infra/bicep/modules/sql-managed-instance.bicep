// modules/sql-managed-instance.bicep
//
// Deploys an Azure SQL Managed Instance with three databases:
//
//   - SourceA: Latin1_General_CI_AS collation, models the practice-management legacy schema.
//   - SourceB: Latin1_General_CS_AS collation, models the billing legacy schema.
//   - Target:  Latin1_General_100_CS_AS_SC_UTF8 collation, hosts the canonical unified schema.
//
// The managed instance is deployed into a dedicated subnet in the provided VNet.
// All three databases are on the same instance to minimise cost in a demonstration environment;
// in a production migration, Source A and Source B would be on separate instances representing
// the legacy systems, and the Target would be a new instance.
//
// Parameters (to be defined):
//   - instanceName: name of the SQL Managed Instance resource
//   - location: Azure region
//   - subnetId: resource ID of the dedicated subnet (must be delegated to SQL MI)
//   - adminLogin / adminPassword: SQL SA credentials
//   - skuName: e.g., GP_Gen5_4 for a cost-conscious dev deployment

// TODO: define parameters block
// TODO: deploy Microsoft.Sql/managedInstances resource
// TODO: deploy three Microsoft.Sql/managedInstances/databases child resources
// TODO: output the managed instance FQDN for use by the AKS workloads
