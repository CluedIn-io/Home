---
parent: Frequently Asked Questions
---

# Why does my generated docker name contain extra characters?

When running a CluedIn instance using `.\cluedIn.ps1 up` script or similar you might notice that docker name contains a generated string inserted after the normalized environment name.

For example:

```
> ./cluedin.ps1 up 3.2.5

Creating network "cluedin_325_61ef0f49_default" with the default driver
Creating cluedin_325_61ef0f49_seq_1           ... done

...
```

Here we can see the value `_61ef0f49` inserted after our environment name.

The generated string is a unique hash of the environments path. By inserting it into the project name we can ensure the environment never collides with other Home environments. That allows us to better handle scenarios like:
- Having two separate copies of `Home` folder and both of them contain an environment with the same name (e.g. `default`)
- Having multiple environments which differ by special characters only (e.g. `325` and `3.2.5`). That causes issues because `docker-compose` [sanitizes special characters](https://github.com/docker/compose/issues/2119) from project name.
