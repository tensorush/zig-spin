## :lizard: :yo_yo: **zig spin**

[![CI][ci-shield]][ci-url]
[![CD][cd-shield]][cd-url]
[![DC][docs-shield]][docs-url]
[![LC][license-shield]][license-url]

### Zig SDK for the [Spin](https://github.com/fermyon/spin) serverless application framework created by the [Fermyon team](https://www.fermyon.com/).

### :rocket: Usage

> #### [**WIP**! Haven't yet figured out a way to correctly package the library with the Zig package manager.](test/)

1. Add `spin` as a dependency in your `build.zig.zon`.

    <details>

    <summary><code>build.zig.zon</code> example</summary>

    ```zig
    .{
        .name = "<name_of_your_package>",
        .version = "<version_of_your_package>",
        .dependencies = .{
            .spin = .{
                .url = "https://github.com/tensorush/zig-spin/archive/<git_tag_or_commit_hash>.tar.gz",
                .hash = "<package_hash>",
            },
        },
    }
    ```

    Set `<package_hash>` to `12200000000000000000000000000000000000000000000000000000000000000000`, and Zig will provide the correct found value in an error message.

    </details>

2. Add `spin` as a module in your `build.zig`.

    <details>

    <summary><code>build.zig</code> example</summary>

    ```zig
    const spin = b.dependency("spin", .{});
    exe.addModule("spin", spin.module("spin"));
    exe.linkLibrary(spin.artifact("spin"));
    ```

    </details>

### :battery: Progress

Legend: :green_circle: - tested, :yellow_circle: - untested, :red_circle: - unimplemented.

| Component                            |     Status      |           Example            |
|--------------------------------------|:---------------:|:----------------------------:|
| [HTTP (outbound)](src/http.zig#L133) | :green_circle:  |  [Click](examples/http-out)  |
| [HTTP (inbound)](src/http.zig#L71)   | :green_circle:  |  [Click](examples/http-in)   |
| [Redis (outbound)](src/redis.zig)    |  :red_circle:   | [Click](examples/redis-out)  |
| [Redis (inbound)](src/redis.zig)     |  :red_circle:   |  [Click](examples/redis-in)  |
| [PostgreSQL](src/postgresql.zig)     |  :red_circle:   | [Click](examples/postgresql) |
| [MySQL](src/mysql.zig)               |  :red_circle:   |   [Click](examples/mysql)    |
| [SQLite](src/sqlite.zig)             | :yellow_circle: |   [Click](examples/sqlite)   |
| [Config](src/config.zig#L23)         | :green_circle:  |   [Click](examples/config)   |
| [KVS](src/kvs.zig)                   |  :red_circle:   |    [Click](examples/kvs)     |
| [LLM](src/llm.zig)                   |  :red_circle:   |    [Click](examples/llm)     |

### :arrow_down: Dependencies

- [`wit-bindgen-cli v0.2.0` - guest language WIT bindings generator](https://github.com/bytecodealliance/wit-bindgen/releases/tag/v0.2.0).

    ```sh
    cargo install --git https://github.com/bytecodealliance/wit-bindgen --rev cb871cf wit-bindgen-cli
    ```

<!-- MARKDOWN LINKS -->

[ci-shield]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-spin/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/zig-spin/blob/main/.github/workflows/ci.yaml
[cd-shield]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-spin/cd.yaml?branch=main&style=for-the-badge&logo=github&label=CD&labelColor=black
[cd-url]: https://github.com/tensorush/zig-spin/blob/main/.github/workflows/cd.yaml
[docs-shield]: https://img.shields.io/badge/click-F6A516?style=for-the-badge&logo=zig&logoColor=F6A516&label=docs&labelColor=black
[docs-url]: https://tensorush.github.io/zig-spin
[license-shield]: https://img.shields.io/github/license/tensorush/zig-spin.svg?style=for-the-badge&labelColor=black
[license-url]: https://github.com/tensorush/zig-spin/blob/main/LICENSE.md
