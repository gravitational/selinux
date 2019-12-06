# SELinux policy for Gravity

Policy to support installing Gravity to SELinux-enabled environments.

The policy depends on [container-selinux](https://github.com/gravitational/container-selinux/) but the build process abstracts the dependency by building both.
Currently only `centos`/`redhat` are supported but it is planned to extend support to `debian` in future.

## Building

Build depends on docker/podman so make sure either has been installed.

```shell
$ make
```
