#!/bin/bash

set -euxo pipefail

# build wasm fdw package
cargo component build --release --target wasm32-unknown-unknown

# set wasm file permission and copy it into supabase db container
chmod +r target/wasm32-unknown-unknown/release/*.wasm
db_container=`docker ps --format "{{.Names}}" | grep supabase_db_`
docker cp target/wasm32-unknown-unknown/release/*.wasm ${db_container}:/
