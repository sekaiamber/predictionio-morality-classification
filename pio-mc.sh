#!/bin/bash

# load utils
CurDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${CurDir}/utils.sh

# get host ip
HostIP='0.0.0.0'

# set data dir
JobWork='/data/predictionio/work'

update_images() {
  # pull spark-cluster docker image
  docker pull docker.baozou.com/baozou/predictionio

  check_exec_success "$?" "pulling 'predictionio' image"
}

start() {

  update_images

  docker kill predictionio_mc 2>/dev/null
  docker rm predictionio_mc 2>/dev/null

  mkdir -p ${JobWork}
  mkdir -p ${CurDir}/sbt

  docker run -d --name predictionio_mc \
    -v ${CurDir}:/data/predictionio \
    -v ${JobWork}:/data/work/predictionio \
    -v ${CurDir}/conf:/PredictionIO/conf \
    -v ${CurDir}/sbt:/sbt \
    --env HOME=${JobWork} \
    --env SBT_OPTS="-Dsbt.global.base=/sbt/.sbt -Dsbt.ivy.home=/sbt/.ivy2" \
    --net=host \
    --log-opt max-size=10m \
    --log-opt max-file=9 \
    docker.baozou.com/baozou/predictionio \
    pio eventserver \
    $* 2>&1

  check_exec_success "$?" "start project ${WorkDir}"
}

newapp() {
  docker exec predictionio_mc pio app new mc
}

build() {
  docker exec predictionio_mc bash -c "cd /data/predictionio && pio build --verbose"
}

train() {
  docker exec predictionio_mc bash -c "cd /data/predictionio && pio train -- --driver-class-path /data/predictionio/jars/mysql-connector-java-5.1.36-bin.jar"
}

deploy() {
  docker exec -d predictionio_mc bash -c "cd /data/predictionio && pio deploy -- --driver-class-path /data/predictionio/jars/mysql-connector-java-5.1.36-bin.jar"
}

example() {
  python3 ${CurDir}/data/import_events.py --access_key $*
}

debug() {
  docker exec -it predictionio_mc bash
}

status() {
  echo "======================"
  echo "Show status"
  echo "======================"
  docker exec predictionio_mc pio status
  echo "======================"
  echo "Show app list"
  echo "======================"
  docker exec predictionio_mc pio app list
}

stop() {
  docker kill predictionio_mc 2>/dev/null
  docker rm predictionio_mc 2>/dev/null
}

##################
# Start of script
##################

case "$1" in
  start)
    shift
    start $*
    ;;
  newapp) newapp ;;
  build) build ;;
  train)
    shift
    train $*
    ;;
  deploy)
    shift
    deploy $*
    ;;
  example)
    shift
    example $*
    ;;
  stop) stop ;;
  status) status ;;
  debug) debug ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage:"
    echo "./pio-mc.sh <Command>"
    echo ""
    echo "Command:"
    echo "  - start"
    echo "  - newapp"
    echo "  - build"
    echo "  - train"
    echo "  - deploy"
    echo "  - example <access_key>"
    echo "  - status"
    echo "  - stop"
    exit 1
    ;;
esac

exit 0