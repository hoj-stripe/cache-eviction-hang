- Use Bazelisk

### reproduce hanging behavior
- Just run `./repro_hanging.sh`

### reproduce exit code 34
- Clone https://github.com/buildbarn/bb-deployments/ then run `WORKDIR=$(mktemp -d -p /tmp) && bazel run -- //bare:bare $WORKDIR` in it
- While the above is running, run `./repro_34_exit.sh`