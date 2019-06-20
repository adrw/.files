## Square Setup

```
$ ./bootstrap.sh -p mac_square -r -b /usr/local -v -s adrw
```

## Steps
- Use quick start command from README to run bootstrap with the above options
- Follow steps in go/ssh to create new SSH key, and add to Bitbucket, Github, and Registry
- Rerun bootstrap which now should succeed (especially for the Square specific parts that require Bitbucket access)
- Run `$ babushka cacerts`
- polyrepo init
- polyrepo add ...
- Import project into IntelliJ
