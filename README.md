# Postgres Wasm FDW [Template]

This project demostrates how to create a Postgres Foreign Data Wrapper with Wasm, using the [Wrappers framework](https://github.com/supabase/wrappers).

This example reads the [realtime GitHub events](https://api.github.com/events) into a Postgres database. 

## Project Structure

```bash
├── src
│   └── lib.rs              # The package source code. We will implement the FDW logic, in this file.
├── supabase-wrappers-wit   # The Wasm Interface Type provided by Supabase. See below for a detailed description.
│   ├── http.wit
│   ├── jwt.wit
│   ├── routines.wit
│   ├── stats.wit
│   ├── time.wit
│   ├── types.wit
│   ├── utils.wit
│   └── world.wit
└── wit                     # The WIT interface this project will use to build the Wasm package.
    └── world.wit
```

A [Wasm Interface Type](https://github.com/bytecodealliance/wit-bindgen) (WIT) defines the interfaces between the Wasm FDW (guest) and the Wasm runtime (host). For example, the `http.wit` defines the HTTP related types and functions can be used in the guest, and the `routines.wit` defines the functions the guest needs to implement.

## Getting started

To get started, visit the [Wasm FDW developing guide](https://fdw.dev/guides/create-wasm-wrapper/).

## License

[Apache License Version 2.0](./LICENSE)
