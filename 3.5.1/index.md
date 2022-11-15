---
title: v3.5.1
has_toc: False
has_children: True
---

# Release Notes - v3.5.1

## Features
- Added env variables enable/disable fuzzy matching, disabled by default [AB#17207].
    - CLUEDIN_FUZZYENTITYMATCHING_MATCHER_EMAIL_ENABLED
    - CLUEDIN_FUZZYENTITYMATCHING_MATCHER_NAME_ENABLED
    - CLUEDIN_FUZZYENTITYMATCHING_MATCHER_LEGACY_ENABLED
    - CLUEDIN_FUZZYENTITYMATCHING_MATCHER_LEGACYFUZZYENTITYMATCHERV2_ENABLED
- Added nuget installer custom certs. Custom CA can be added by placing the ca.crt into a certs folder inside the environment folder [AB#17276].

## Fixes

