---
parent: Frequently Asked Questions
---

# What is `pwsh`?

`pwsh` is the command for [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/overview?view=powershell-7) the cross platform shell and scripting language from Microsoft.

PowerShell is used by Home to ensure a consistent approach and language for local development of CluedIn on any operating system.

## How do I start a PowerShell session?

In Windows you can start a new PowerShell session using the dedicated **PowerShell (x64) application**.

For all operating systems (including Windows), you can also start your favourite shell and type `pwsh` to enter a new session:
```cmd
myname@machine:~$ pwsh

PowerShell 7.1.3
Copyright (c) Microsoft Corporation.

https://aka.ms/powershell
Type 'help' to get help.

PS /Users/myname>
```

You can exit the session by typing `exit`
# Do not use `pwsh .\cluedin.ps1 ...`

You _could_ avoid entering a session by providing your commands to to `cluedin.ps1` directly after `pwsh` but this is no longer reccomended.
When running on macOS or Linux some arguments are not passed correctly, causing `.\cluedin.ps1` to perform incorrect actions.