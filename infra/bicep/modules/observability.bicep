// modules/observability.bicep
//
// Deploys an Azure Monitor workspace and Application Insights instance for the
// strangler API and load generator.
//
// The Application Insights connection string is injected into the strangler API
// as an environment variable; the API uses the OpenTelemetry Azure Monitor exporter
// to emit structured telemetry including:
//   - Per-request traces with phase annotation (current CutoverPhase on each span)
//   - Reconciler diff count as a custom metric (tagged by drift category)
//   - Outbox lag as a custom metric (sampled at the relay's polling interval)
//   - Shadow-compare failure events (Phase B)
//
// This enables a pre-built Application Insights workbook (to be defined in Phase 2)
// to show phase-boundary latency, drift counts, and outbox lag as correlated time series.
//
// Parameters (to be defined):
//   - workspaceName: name of the Log Analytics workspace
//   - appInsightsName: name of the Application Insights resource
//   - location: Azure region

// TODO: define parameters block
// TODO: deploy Microsoft.OperationalInsights/workspaces resource
// TODO: deploy Microsoft.Insights/components resource linked to the workspace
// TODO: output the Application Insights connection string
