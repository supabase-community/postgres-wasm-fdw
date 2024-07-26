#!/bin/bash

set -euxo pipefail

# build wasm fdw package
cargo component build --release --target wasm32-unknown-unknown

# set wasm file permission and copy it into supabase db container
chmod +r target/wasm32-unknown-unknown/release/*.wasm
docker cp target/wasm32-unknown-unknown/release/*.wasm supabase_db_supabase:/
