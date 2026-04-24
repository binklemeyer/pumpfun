#!/bin/bash

call_to_success() {
  local max_retries=$1
  local retries=0
  shift

  until "$@"; do 
    retries=$((retries + 1))
    if [ "$retries" -ge "$max_retries" ]; then
      echo "Command ${command} failed"
      exit 1
    fi
    echo "Command ${command} failed, retrying"
    sleep 1
  done
}
