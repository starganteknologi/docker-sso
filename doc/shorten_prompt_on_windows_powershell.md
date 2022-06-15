# Shorten prompt on windows powershell

``` shell
function prompt {'PS ' + $(Get-Location | Split-Path -Leaf) + ">"}
```

save ke profile 

``` shell
Test-Path $Profile
```

if it returns false then no you don’t have a profile file yet, so create it:

```shell
New-Item –Path $Profile –Type File –Force
notepad $Profile
```

and put the function in $Profile