// Migration.StranglerApi — scaffold stub
//
// This file exists solely so that the Microsoft.NET.Sdk.Web project compiles
// as a valid executable during the scaffold phase. It is not the real
// implementation. See src/Migration.StranglerApi/TODO.md for acceptance
// criteria and build order.
//
// TODO: replace with the real four-phase strangler API once
//       Migration.Contracts, the data access layers, and Migration.DualWriter
//       are implemented.

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Minimal health endpoint so the container can be probed during development.
// The real /health endpoint will report the current CutoverPhase and the
// connection status of all three databases.
app.MapGet("/health", () => Results.Ok(new
{
    status = "scaffold-only",
    note = "See src/Migration.StranglerApi/TODO.md"
}));

app.Run();
