---
title: v3.4.0
has_children: True
has_toc: False
---

# Release Notes - v3.4.0

## Features
+ You can can now pass `-DisableData` when calling `up` to prevent writing to the environment data folder.
  This can improve performance for simple environments.
+ Allow to `docker-compose.override.yml` file to environment folder to extend docker service configuration (e.g. add an extra environment variable)
+ Move installer image to it's own project.  This enables the image to be retained to manage caches  (AB#9661)
+ Improve `packages -restore` scenarios to reduce time taken to restore (AB#9661)
+ Add `packages -restore -clearcache` option to allow caches to be cleared when using local packages or
when referencing floating package versions  (AB#9661)

## Fixes
+ Ensure libpostal service is not pulled when replicas are set to zero
+ Report yellow status correctly for `status` command
+ Ensure `CLUEDIN_SERVER_HOST` is used for status checks when defined
+ Added environment variable `CLUEDIN_MODELS_ENABLED` to control model inclusion (AB#13715)

