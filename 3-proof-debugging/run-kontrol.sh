#!/bin/bash

kontrol build

kontrol prove --mt testMulWad || true

FOUNDRY_PROFILE=lemmas kontrol build --require lemmas.k --module MulWad:KONTROL-LEMMAS

FOUNDRY_PROFILE=lemmas kontrol prove --mt testMulWad
