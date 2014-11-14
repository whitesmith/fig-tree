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
This setup persists the database between builds by storing it on the host system
using a volume; it is mounted on the host's `~/.docker-volumes/app-name/db/`
folder.

To prepare this setup:

1. Edit `fig.yml` and change `app-name` to match your application's name; it
should be unique so there are no collisions with future projects that use this
setup.
2. Create the `~/.docker-volumes/app-name/db/` folder tree (since Docker assumes
it already exists). A quick way to do it:
`mkdir -p ~/.docker-volumes/<app-name>/db/`.
3. Move the `fig.yml` and `Dockerfile` files to your application's folder. They
should be on the root of the application.
4. Edit your application's `config/database.yml` and add the following fields to
your `development` and `test` environments (use this repo's `database.yml` as
reference):

```yaml
host: db
username: postgres
```

## Usage
Before we can run the dev env, we must first setup the database. This is only
needed when running for the first time. After doing so, we'll be able to run
both applications simultaneously.

```
fig up -d db              # starts the database detached from the current window
fig run web rake db:setup # setups the database by running a one-off command
fig up                    # starts the web application attached to the window
```

The app should now be running on [localhost:3000](http://localhost:3000/).

**Note**: The first time you run `fig up` will _pull_ (download) the necessary
Docker images. This may take a while.

Since the database has been setup, from now on it will be possible to start both
applications simply by running `fig up`. For stopping the applications, you may
run `fig stop`. For removing the containers, you may run `fig rm`. Run
`fig help` for more options or refer to the [Fig CLI Documentation][]. For
customizing the `fig.yml`, refer to [fig.yml Documentation][].

[Fig CLI Documentation]: http://www.fig.sh/cli.html
[fig.yml Documentation]: http://www.fig.sh/yml.html

## Documentation
For more information about using Docker, `boot2docker` or Fig, please refer to:

- [Docker](https://docs.docker.com/)
- [boot2docker](https://github.com/boot2docker/boot2docker) (Mac OS X only)
- [Fig][]

[heroku/ruby-rails-sample]: https://github.com/heroku/ruby-rails-sample
[Fig]: http://fig.sh/
