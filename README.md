# Postgres Wasm FDW [Template]

This project demostrates how to create a Postgres Foreign Data Wrapper with Wasm, using the [Wasm FDW framework](https://github.com/supabase/wrappers/tree/main/wrappers/src/fdw/wasm_fdw). 

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

You can use this example as the start point to develop your own FDW. 

### Fork

Fork this project to your own GitHub account by clicking the `Fork` button on top of this page, and then clone your forked project to your local machine

### Install prerequisites

This project is a normal Rust library project, so we will assume you have installed Rust toolchain. This project uses [The WebAssembly Component Model](https://component-model.bytecodealliance.org/) to build WebAssembly package, we will also install below dependencies:

1. Add `wasm32-unknown-unknown` target:

   ```bash
   rustup target add wasm32-unknown-unknown
   ```

2. Install the [WebAssembly Component Model subcommand](https://github.com/bytecodealliance/cargo-component):

   ```bash
   cargo install cargo-component
   ```

### Implement the foreign data wrapper logic

To implement the foreign data wrapper logic, we need to implement the `Guest` trait:

```rust
pub trait Guest {
    /// ----------------------------------------------
    /// foreign data wrapper interface functions
    /// ----------------------------------------------
    /// define host version requirement, e.g, "^1.2.3"
    fn host_version_requirement() -> String;

    /// fdw initialization
    fn init(ctx: &Context) -> FdwResult;

    /// data scan
    fn begin_scan(ctx: &Context) -> FdwResult;
    fn iter_scan(ctx: &Context, row: &Row) -> Result<Option<u32>, FdwError>;
    fn re_scan(ctx: &Context) -> FdwResult;
    fn end_scan(ctx: &Context) -> FdwResult;

    /// data modify
    fn begin_modify(ctx: &Context) -> FdwResult;
    fn insert(ctx: &Context, row: &Row) -> FdwResult;
    fn update(ctx: &Context, rowid: Cell, new_row: &Row) -> FdwResult;
    fn delete(ctx: &Context, rowid: Cell) -> FdwResult;
    fn end_modify(ctx: &Context) -> FdwResult;
}
```


Check out the details in the `src/lib.rs` file to see how to read GitHub Events endpoint. This package will be built to `wasm32-unknown-unknown` target, which is a limited execution environment and lack of most stdlib functionalities such as file and socket IO. Also note that many 3rd parties libs on crates.io are not supporting the `wasm32-unknown-unknown` target, so choose your dependencies carefully.

### Build the Wasm FDW package

Once the `Guest` trait is implemented, now it is time to build the Wasm FDW package, it is just a simple command:

```bash
cargo component build --release --target wasm32-unknown-unknown
```

This will build the Wasm file in `target/wasm32-unknown-unknown/release/wasm_fdw_example.wasm`. This is the Wasm FDW package can be used on Supabase platform.

## Use with Supabase

You can use your Wasm FDW on the Supabase platform as long as the Wrappers extension version is `>=0.4.1`.

### Checking Wrappers version

Go to `SQL Editor` in Supabase Studio and run below query to check its version:

```sql
select * 
from pg_available_extension_versions 
where name = 'wrappers';
```

### Installing your Wasm FDW

Install the Wrappers extension and initialize the Wasm FDW:

```sql
create extension if not exists wrappers with schema extensions;

create foreign data wrapper wasm_wrapper
  handler wasm_fdw_handler
  validator wasm_fdw_validator;
```

Create foreign server and foreign table like below,

```sql
create server example_server
  foreign data wrapper wasm_wrapper
  options (
    -- change below fdw_pacakge_* options accordingly
    -- check available releases at https://github.com/supabase-community/wasm-fdw-example/releases
    fdw_package_url 'https://github.com/supabase-community/wasm-fdw-example/releases/download/v0.1.0/wasm_fdw_example.wasm',
    fdw_package_name 'my-company:example-fdw',
    fdw_package_version '0.1.0',
    fdw_package_checksum '67bbe7bfaebac6e8b844813121099558ffe5b9d8ac6fca8fe49c20181f50eba8',
    api_url 'https://api.github.com'
  );

create schema github;

create foreign table github.events (
  id text,
  type text,
  actor jsonb,
  repo jsonb,
  payload jsonb,
  public boolean,
  created_at timestamp
)
  server example_server
  options (
    object 'events',
    rowid_column 'id'
  );
```

Query the foreign table to see what's happening on GitHub:

```sql
select
  id,
  type,
  actor->>'login' as login,
  repo->>'name' as repo,
  created_at
from
  github.events
limit 5;
```

<img width="812" alt="image" src="https://github.com/user-attachments/assets/53e963cb-6e8f-44f8-9f2e-f0edc73ddf3a">

:clap: :clap: Congratulations! You have built your first Wasm FDW.

## Considerations

### Version compatibility

This Wasm FDW (guest) runs insider a Wasm runtime (host) which is provided by the [Wrappers Wasm FDW framework](https://github.com/supabase/wrappers/tree/main/wrappers/src/fdw/wasm_fdw). The guest and host versions need to be compatible. We can define the required host version in the guest's `host_version_requirement()` function like below:

```rust
impl Guest for ExampleFdw {
    fn host_version_requirement() -> String {
        "^0.1.0".to_string()
    }
}
```

Both guest and host are using [Semantic Versioning](https://docs.rs/semver/latest/semver/enum.Op.html). The above code means the guest is compatible with host version greater or equal `0.1.0` but less than `0.2.0`. If the version isn't comatible, this Wasm FDW cannot run on that version of host.

All the available host versions are listed here: https://github.com/supabase/wrappers/blob/main/wrappers/src/fdw/wasm_fdw/README.md. When you develop your own Wasm FDW, always choose compatible host version properly.

### Security

> [!WARNING]
> Never use untrusted Wasm FDW on your database.

Although we have implemented security measures and limited the Wasm runtime environment to a minimal interface, ultimately you are responsible for your data. Never install a Wasm FDW from untrusted source. Always use official sources, like [Supabase Wasm FDW](https://github.com/supabase/wrappers/tree/main/wasm-wrappers), or sources which you have full visibility and control.

### Performance

The Wasm package will be dynamically downloaded and loaded to run on Postgres, and so you should make sure the Wasm FDW is small to improve performance. Always build your project in `release` mode using the profile specified in the `Cargo.toml` file:

```toml
[profile.release]
strip = "debuginfo"
lto = true
```

```bash
# build in release mode and target wasm32-unknown-unknown
cargo component build --release --target wasm32-unknown-unknown
```

### Automation

If you host source code on GitHub, the building and release process can be automated, take a look at the `.github/workflow/release_wasm_fdw.yml` file to see an example of CI workflow.


## Other examples

Some other Wasm foreign data wrapper projects developed by Supabase team:

- [Snowflake Wasm FDW](https://github.com/supabase/wrappers/tree/main/wasm-wrappers/fdw/snowflake_fdw)
- [Paddle Wasm FDW](https://github.com/supabase/wrappers/tree/main/wasm-wrappers/fdw/paddle_fdw)
