#!/usr/bin/env bash

# Fancy prints
print_normal (){ printf "%b\n" "$1" >&2; }
print_error  (){ printf "$(tput setaf 1)[fig-tree] %b$(tput sgr0)\n" "$1" >&2; }
print_info   (){ printf "$(tput setaf 3)[fig-tree] %b$(tput sgr0)\n" "$1" >&2; }
print_success(){ printf "$(tput setaf 2)[fig-tree] %b$(tput sgr0)\n" "$1" >&2; }

# Abort in the case of an error
handle_error(){
  if [ $1 -ne 0 ]; then
    print_error "Something went wrong while $2, aborting."
    exit 1
  fi
}

## CUSTOMIZE
RUBY_VERSION=2.1
APP_NAME=app-name
PORT=3000

custom_bootstrap(){
  # Custom bootstrap instructions go here.
  # This is the last bootstrap step; it is run after the first `bundle install`.
  # Since this application has a db, you'll probably want to `rake db:setup`.
  print_info "Setting up the database (rake db:setup)"
  docker-compose run web bundle exec rake db:setup
  handle_error $? "setting up the database"
}
## /CUSTOMIZE

DOCKER_MINIMAL_IMAGE=tianon/true
GEMS_CONTAINER_NAME=gems-$RUBY_VERSION
DB_DATA_CONTAINER_NAME=$APP_NAME-db-data
DOCKER_COMPOSE_PREFIX=$(echo ${PWD##*/} | tr -d '-')

# `docker info` call for testing if the Docker host is reachable.
# Usage: check_docker
check_docker(){
  docker info > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    print_error "ERROR: Docker host could not be reached. Maybe you need sudo?"
    exit 1
  fi
}

# Create a data volume container for a specific path.
# Usage: create_data_container CONTAINER_NAME VOLUME_PATH
create_data_container(){
  docker run -d --name $1 -v $2 $DOCKER_MINIMAL_IMAGE
}

# Stop a container by name.
# Usage: stop_container_by_name CONTAINER_NAME
stop_container_by_name(){
  docker ps -a | grep $1 | awk '{ print $1 }' | xargs --no-run-if-empty docker stop
}

# Remove a container by name.
# Usage: remove_container_by_name CONTAINER_NAME
remove_container_by_name(){
  docker ps -a | grep $1 | awk '{ print $1 }' | xargs --no-run-if-empty docker rm
}

# Remove an image by name.
# Usage: remove_image_by_name IMAGE_NAME
remove_image_by_name(){
  docker images -a | grep $1 | awk '{ print $3 }' | xargs --no-run-if-empty docker rmi
}

# Main options
bootstrap(){
  # Announcing
  print_info "Bootstrapping $APP_NAME"
  print_info "Ruby version: $RUBY_VERSION"

  # Check if the Gems container already exists. If not, create it.
  local GEMS_CONTAINER=$(docker ps -a | grep $GEMS_CONTAINER_NAME)
  if [ -n "$GEMS_CONTAINER" ]; then
    print_success "The gems container for Ruby $RUBY_VERSION ($GEMS_CONTAINER_NAME) already exists."
  else
    print_info "Creating the gems container for Ruby $RUBY_VERSION ($GEMS_CONTAINER_NAME)."
    create_data_container $GEMS_CONTAINER_NAME "/usr/local/bundle"
    handle_error $? "creating $GEMS_CONTAINER_NAME"
    print_success "Gems container for Ruby $RUBY_VERSION ($GEMS_CONTAINER_NAME) successfully created."
  fi

  # Check if the database data container already exists. If not, create it.
  if [ -n "$(docker ps -a | grep $DB_DATA_CONTAINER_NAME)" ]; then
    print_success "The database data container ($DB_DATA_CONTAINER_NAME) already exists."
  else
    print_info "Creating the database data container ($DB_DATA_CONTAINER_NAME)."
    create_data_container $DB_DATA_CONTAINER_NAME "/var/lib/postgresql/data/"
    handle_error $? "creating $DB_DATA_CONTAINER_NAME"
    print_success "Database data container ($DB_DATA_CONTAINER_NAME) successfully created."
  fi

  # Build the web container
  print_info "Building the web container."
  docker-compose build web
  handle_error $? "building the web container"

  # Check if the gems container was just created; if so, install bundler.
  if [ -z "$GEMS_CONTAINER" ]; then
    print_info "Gems container is new, installing bundler."
    docker-compose run web gem install bundler
    handle_error $? "installing bundler"
  else
    print_info "Gems container already existed before this script: assuming bundler is already installed."
    print_info "In the case of failure, run"
    print_info "  docker-compose run web gem install bundler"
    print_info "and re-run this script."
  fi

  # Install app's dependencies
  print_normal
  print_info "Installing dependencies (bundle install)"
  docker-compose run web bundle install --jobs 4 --retry 3
  handle_error $? "installing the app's dependencies"

  custom_bootstrap

  print_normal
  print_success "The project was successfully setup! Run"
  print_success "  $0 start"
  print_success "to start the server."
}

start(){
  # Assume Docker host is localhost, override in the case boot2docker is detected
  local URL=http://localhost:$PORT/
  command -v boot2docker > /dev/null 2>&1 && URL=http://$(boot2docker ip 2> /dev/null):$PORT/

  print_info "Open $URL on your browser."
  print_normal

  docker-compose up
}

bundle_exec(){
  # Teaching docker-compose commands, one at a time.
  local command=$(echo ${@})
  print_info "Running"
  print_info "  docker-compose run web bundle exec $command"
  docker-compose run web bundle exec $command
}

stop(){
  docker-compose stop
  docker-compose rm
}

clean(){
  stop_container_by_name $DOCKER_COMPOSE_PREFIX
  remove_container_by_name $DOCKER_COMPOSE_PREFIX
  remove_image_by_name $DOCKER_COMPOSE_PREFIX
}

project_clean(){
  clean
  remove_container_by_name $DB_DATA_CONTAINER_NAME
}

gems_clean(){
  remove_container_by_name $GEMS_CONTAINER_NAME
}

untagged_clean(){
  remove_image_by_name '^<none>' 2> /dev/null
}

logs(){
  docker-compose logs
}

check_docker
case "$1" in
  "bootstrap")
    bootstrap
  ;;

  "start")
    start
  ;;

  "exec")
    bundle_exec ${@:2}
  ;;

  "console")
    bundle_exec "rails console" ${@:2}
  ;;

  "stop")
    stop
  ;;

  "clean")
    clean
  ;;

  "project-clean")
    project_clean
  ;;

  "gems-clean")
    gems_clean
  ;;

  "untagged-clean")
    untagged_clean
  ;;
  
  "logs")
    logs
  ;;

  *)
    print_normal "Usage: $0 COMMAND"
    print_normal
    print_normal "Available commands:"
    print_normal "  bootstrap"
    print_normal "  start"
    print_normal "  exec"
    print_normal "  console"
    print_normal "  clean"
    print_normal "  project-clean"
    print_normal "  gems-clean"
    print_normal "  untagged-clean"
    print_normal "  logs"
  ;;
esac

exit 0
