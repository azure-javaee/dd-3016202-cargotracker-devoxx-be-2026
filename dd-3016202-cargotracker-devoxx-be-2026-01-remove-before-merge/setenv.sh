#!/usr/bin/env bash

setenv_sourced=0
if [ -n "${ZSH_VERSION:-}" ]; then
    case "${ZSH_EVAL_CONTEXT:-}" in
        *:file) setenv_sourced=1 ;;
    esac
elif [ -n "${BASH_VERSION:-}" ] && [ "${BASH_SOURCE:-}" != "$0" ]; then
    setenv_sourced=1
fi

if [ "$setenv_sourced" -ne 1 ]; then
    printf '%s\n' \
        'This script must be sourced to update the current shell:' \
        '  source ./setenv.sh' >&2
    exit 1
fi
unset setenv_sourced

SHEPHERD_HOME="${HOME}/.copilot/plugins/shepherd-task/scripts"

if [ ! -d "$SHEPHERD_HOME" ]; then
    printf 'Shepherd Task scripts directory not found: %s\n' "$SHEPHERD_HOME" >&2
    return 1
fi

case ":${PATH}:" in
    *":${SHEPHERD_HOME}:"*) ;;
    *) PATH="${SHEPHERD_HOME}:${PATH}" ;;
esac

export SHEPHERD_HOME
export PATH
