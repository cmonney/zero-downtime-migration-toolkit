# tools/seed — TODO

## What this folder will contain

SQL seed scripts for each of the three databases. The seed scripts are mounted into the SQL Server
containers as init scripts and executed at container startup. The folder will be structured as:

```
tools/seed/
├── source-a/
│   └── init.sql   — creates the Source A database, schema, tables, and seed data
├── source-b/
│   └── init.sql   — creates the Source B database, schema, tables, and seed data
└── target/
    └── init.sql   — creates the Target database and canonical schema (no seed data; populated by dual-writer)
```

The Source A and Source B seed scripts are the most important documents in the repository after the
ADRs and runbooks. They must contain deliberate instances of all eight drift categories defined in
ADR 0003, and those instances must be clearly commented so that a reviewer can see what each
anomaly is and why it is there.

## Acceptance criteria

- The Source A init script creates a schema that includes: at least one `float` money column, at
  least one `varchar` column storing multi-byte Unicode characters that will be damaged by Latin1
  collation, at least one `datetime` column in local time at second precision, at least one
  nullable FK used as a soft-delete marker, and at least one column with trailing whitespace in
  seed data.
- The Source B init script creates a schema that includes: at least one `nvarchar` column with
  trailing whitespace in historic seed records, at least one `datetime` column that is
  inconsistently UTC in some rows and local time in others, at least one `decimal` column whose
  scale differs from the target's canonical scale, and at least one record whose address is stored
  differently from the canonical form to exercise the modelling-difference drift category.
- The Target init script creates the canonical schema with none of the above anomalies: money as
  `decimal(19,4)`, all datetimes as `datetime2(6)` in UTC, `nvarchar` throughout, no nullable FK
  soft-deletes, normalised address model.
- Running the reconciler against the seeded Source A and Source B versus an empty target produces
  a report identifying every seeded drift instance.

## Build order

Design the seed scripts before implementing any data access layer project. The schema drives the
entity models in Migration.SourceA, Migration.SourceB, and Migration.Target. Implement Source A
and Source B seeds concurrently. Implement the Target seed after the canonical schema is agreed.
