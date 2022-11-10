SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent
.DEFAULT_GOAL := build

include .env
include inc/init.mk
include $(filter-out inc/init.mk ,$(wildcard inc/*.mk))
