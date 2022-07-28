---
title: createorg
parent: v3.4.0
---

# createorg

Creates a new organization in CluedIn.
{: .fs-6 .fw-300 }

When creating a new organization an organization admin account is also created.
The associated login details are returned.

## Syntax

```
createorg [[-Env] <string>] -Name <string> [-Email <string>] [-Pass <string>] [-AllowEmailSignup] 
```

```powershell
> .\cluedin.ps1 createorg -Name example

+-------------------------------+
| CluedIn - Create Organization |
+-------------------------------+

#...
Email: admin@example.com
Password: P@ssword!123
```    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| Name | String | true |  | The name of the organization to created. 
| Email | String | false | "admin@${Name}.com" | The email/username of the organization admin. 
| Pass | String | false | P@ssword!123 | The password of the organization admin. 
| AllowEmailSignup | Flag | false | False | If set to true, will allow direct email sign up for future users<br />using an email that matches the organization admins email domain. 


