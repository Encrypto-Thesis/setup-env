# Setup Environment

Sets up an environment for building `[libOTe](https://github.com/osu-crypto/libOTe)`.

## Dependencies

- `perl`
- `git`
- `make`
- `docker`

## How-To

```bash
# CLONE REPOS
perl setup.pl

# BUILD CONTAINER
make docker-build

# BUILD LIBOTE
make build

# SHELL TO CONTAINER
make shell
```
