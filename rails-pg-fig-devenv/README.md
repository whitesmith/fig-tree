# rails-pg-fig-devenv

This repository is a barebones development environment that aims to provide a
starting point for using Docker (through [Fig][]) to setup a simple Rails
Development Environment: a web application and a PostgreSQL database.

## Installation
### Docker
Before proceeding to install [Fig][], you must first have Docker installed on
your system. Since the installation instructions may change over time, please
refer to [Docker Documentation: Installation][] for your OS specific
instructions.

[Docker Documentation: Installation]: https://docs.docker.com/installation/

**Note**: Because the Docker Engine uses Linux-specific kernel features, you'll
need to use a lightweight virtual machine (VM) to run it on OS X. The VM that
was chosen to be supported by our internal development process is `boot2docker`,
even though there are other alternatives. Please use the installation
instructions that are specific of that VM.

### Fig
Installation instructions for [Fig][] may be found in [Installing Fig][].

[Installing Fig]: http://www.fig.sh/install.html

## Prepare your application
This setup persists the database between builds by storing it on an _external_
container (external to Fig).

To prepare this setup:

1. Edit `fig.yml` and change `APP_NAME` (on the `volumes_from` of the `db`
container) to match your application's name; it should be unique so there are no
collisions with future projects that use this setup. Edit the `RUBY_VERSION` (on
the `volumes_from` of the `web` container) to match your Ruby version.
`RUBY_VERSION` should only be the `MAJOR.MINOR` (e.g.: 2.1).
2. Open `project.sh` and head to `## CUSTOMIZE`. Adapt the variables to your
specific case and add your bootstrap commands to `custom_bootstrap` if needed.
**Note**: `APP_NAME` and `RUBY_VERSION` **must match** step 1.
3. Move the `fig.yml`, `Dockerfile` and `project.sh` files to your application's
folder. They should be on the root of the application.
4. Edit your application's `config/database.yml` and add the following fields to
your `development` and `test` environments (use this repo's `database.yml` as
reference):

```yaml
host: db
username: postgres
```

## Usage
This approach makes use of [data volume containers][]:

* A `gems-<RUBY_VERSION>` container for persisting the used gems. This container
will be used by multiple projects, saving disk space and enabling `bundle
install` and `bundle update` commands to make use of cache.
* A `<APP_NAME>-db-data` container for persisting the database's data. This
allows us to remove the database's container while persisting the data for later
usage.

Because Fig only creates containers on a specific namespace (it uses the
folder's name) and because `fig rm` removes every container declared on the
`fig.yml`, these two data volume containers have to be created before using
Fig.

In order to ease the pain of this process, a script was created, `project.sh`.
After having followed the steps detailed in [Prepare your
application](#prepare-your-application), run

```bash
./project.sh bootstrap
```

This will:

* Pull (download) the necessary Docker images;
* Create both data volume containers;
* Create the database container;
* Build the application (`web`) container;
* Install `bundler` (when running for the first time);
* Install the application's dependencies;
* Run `rake db:setup` (or your custom bootstrapping instructions).

Because the bootstrap phase pulls the necessary Docker images, it
may take a while.

From now on, you'll only have to run

```bash
./project.sh start
```

and open your browser on the printed location.

In the future, you may run `./project.sh stop` to stop your containers.
For removing the containers, you may run `./project.sh clean` (or `./project.sh
project-clean` if you don't plan to use the database's data anymore).

Run `./project.sh help` for a list of the available commands. You may also refer
to the [Fig CLI Documentation][] or to [fig.yml Documentation][] for customizing
the `fig.yml`.

[Fig CLI Documentation]: http://www.fig.sh/cli.html
[fig.yml Documentation]: http://www.fig.sh/yml.html

## Documentation
For more information about using Docker, `boot2docker` or Fig, please refer to:

- [Docker](https://docs.docker.com/)
- [boot2docker](https://github.com/boot2docker/boot2docker) (Mac OS X only)
- [Fig][]

[heroku/ruby-rails-sample]: https://github.com/heroku/ruby-rails-sample
[Fig]: http://fig.sh/
[data volume containers]: https://docs.docker.com/userguide/dockervolumes/#creating-and-mounting-a-data-volume-container