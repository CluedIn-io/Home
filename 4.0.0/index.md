---
has_toc: False
title: v4.0.0
has_children: True
---

# Release Notes - v4.0.0

### Features
- Updated hubspot provider with bearer authentication  (#17806)
- Supports new microservices  (#26811)
- Addition of charts and config to grafana for profiling of vocabulary keys.  (#25764)
- Copilot signalR endpoint environment variable  (#24841)
- Enable development feature flags  (#29143)
- Profiling for vocabulary keys  (#29268)

### Others
- Update installed package versions  (#22608)
- Updated RabbitMQ to 3.12  (#25063)
- Add an env variable to control the limit size for the JSON parser so it can process larger payload if required. The default is set to 10MB  (#28076)
- Important change: Switch to use usage of `cluedin/neo4j-home` image for Neo4j  (#28421)
- Switch to `sqlserver-home` image to run SQL Server  (#27728)

