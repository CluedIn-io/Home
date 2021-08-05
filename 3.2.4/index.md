---
has_children: True
has_toc: False
title: v3.2.4
---

# Release Notes - v3.2.4

## Features

- Persisted data for services `sqlserver`, `neo4j`, and `elasticsearch` are now stored under `<env>/data/<service>`. Content is persisted between `up`/`down` of instances.
- New Command to manage cleaning of data: `data`
  ```powershell
  > ./cluedin.ps1 data # Lists all current data
    +----------------+
    | CluedIn - Data |
    +----------------+

    Name          Size      Items
    ----          ----      -----
    elasticsearch 0.00 MB       1
    neo4j         0.43 MB      42
    sqlserver     227.88 MB    30

  > ./cluedin.ps1 data -CleanAll # Removes all data
  > ./cluedin.ps1 data -Clean sqlserver,elasticsearch # Removes data for the specified services only
  ```
- When calling `down` data is cleared by default.  A new flag `-KeepData` can be passed to retain data if desired.
  ```powershell
  > ./cluedin.ps1 down # Destroys CluedIn containers and data
  > ./cluedin.ps1 down -KeepData # Destroys CluedIn containers only
  ```
- When calling `down` the `Tag` and `TagOverride` options are no longer available (they performed no actual function for the `down` command)
- Added feature flag for De-duplication Projects. This can be enables by setting CLUEDIN_UI_FEATURES_DEDUPLICATIONPROJECTS=duplication-project in your .env file

## Fixes
+ Normalize environment variables to support ubuntu based images

