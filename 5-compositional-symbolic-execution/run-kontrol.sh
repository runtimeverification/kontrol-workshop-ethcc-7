#!/bin/bash

kontrol build

kontrol prove --cse

FOUNDRY_PROFILE=no-cse kontrol build

FOUNDRY_PROFILE=no-cse kontrol prove
