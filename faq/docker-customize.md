---
parent: Frequently Asked Questions
---

# Extend existing docker service

For the most common configuration you can modify `.env` file and specify values there, as values are proxied to a service
in the relevant `docker-compose.xxx.yml` file. However from time to time comes a need to configure something which is not
exposed through `.env` file. You can modify the `.yml` files directly, but then the change is applied to all the environments
and cannot be isolated to a single instance.

For this scenario you can simply drop a `docker-compose.override.yml` file inside your environment directory and
extend an existing service there. 

> Note: you cannot override existing values or remove them (e.g. you cannot remove existing
volume mounts), only append new values.

## Example: Add an ad-hoc environment variable

A good use case is the configuration of an environment variable which is not available in the `.env` file.

`docker-compose.override.yml`

```yml
services:
  server:
    environment:
        - CLUEDIN_SERILOG__MINIMUMLEVEL__OVERRIDE__CluedIn.Processing.EntityResolution.Matchers.RuleMatcher.RuleEntityMatcherBase=Verbose
```