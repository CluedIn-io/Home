---
has_toc: False
title: v4.0.0
has_children: True
---

# Release Notes - v4.0.0

### Features
- Updated package versions for .Net 6 upgrade
- Updated RabbitMQ to version 3.12
- Important! Switched to use `cluedin/neo4j-home` image for Neo4j
- Important! Switched to use `sqlserver-home` image to run SQL Server
- Environment variable to control the limit size for the JSON parser so it can process larger payload if required (default 10MB)
- Hubspot provider updated to pass bearer authentication in header of requests
- New grafana charts, dashboards and config for profiling of vocabulary keys
- Enabled development feature flags
- Support for new microservices and deprecation of annotation, datasource and submitter
- Support for Copilot signalR endpoint

