---
has_children: True
title: v3.3.0
has_toc: False
---

# Release Notes - v3.3.0

## Features

+ Enable engine room processing (Rabbit Queues) on docker-compose
+ Enable engine room statistics on docker-compose
+ Email support via smpt4dev (AB#1004)
+ Add flag to enable/disable Explain Log feature on UI
+ The public nuget feed is now configured by default
+ Configured additional paths for Sql Server database persistence - existing instances will be updated when the envioronment is restarted with `down/up` or `stop/start`

## Fixes

+ Fix environment paths could be calculated wrongly depending on working dir
+ Changed the default value of the `CLUEDIN_AGENT_ENABLED` setting from `false` to `true` in order to enable crawlers by default.
+ Fix config for grafana and prometheus end points.
+ Fix datasource dashboard
+ Fix listing of environment when calling `cluedin.ps1 env`
+ Prevent header information from writing to output

