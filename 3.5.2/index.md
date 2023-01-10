---
title: v3.5.2
has_toc: False
has_children: True
---

# Release Notes - v3.5.2

## Features
+ Moved to using CluedIn ACR (Azure Container Registry) instead of DockerHub for container storage. Defaults to: `cluedinprod.azurecr.io`. Please ensure to use the credentials you have been sent or contact support@cluedin.com to request access.
+ Default username + password for `rabbitmq` changed from `guest:guest` to `cluedin:cluedin` due to new security defaults.
## Fixes
+ Fix bug in detecting Docker-compose version

