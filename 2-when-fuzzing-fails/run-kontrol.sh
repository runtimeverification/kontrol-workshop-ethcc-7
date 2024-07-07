#!/bin/bash

kontrol build

kontrol prove --mt testFuzz_SetNumberCaffeinated || true
