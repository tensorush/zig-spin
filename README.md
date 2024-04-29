# :lizard: :yo_yo: zig spin

[![CI][ci-shd]][ci-url]
[![CD][cd-shd]][cd-url]
[![DC][dc-shd]][dc-url]
[![LC][lc-shd]][lc-url]

## Zig SDK for the [Spin serverless application framework](https://github.com/fermyon/spin) created by the [Fermyon team](https://www.fermyon.com/).

### :rocket: Usage

> #### See the [package test](test/) for a full usage example.

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
        .paths = .{
            "src/",
            "build.zig",
            "README.md",
            "LICENSE.md",
            "build.zig.zon",
        },
    }
    ```

    Set `<package_hash>` to `12200000000000000000000000000000000000000000000000000000000000000000` and build your package to find the correct value specified in a compiler error message.

    </details>

2. Add `spin` as a module in your `build.zig`.

    <details>

    <summary><code>build.zig</code> example</summary>

    ```zig
    const spin_dep = b.dependency("spin", .{});
    const spin_mod = spin.module("spin");
    exe.root_module.addImport("spin", spin_mod);
    ```

    </details>

### :battery: Progress

> #### Legend: :green_circle: - tested, :yellow_circle: - untested, :red_circle: - unimplemented.

| Component                            |     Status      |           Example            |
|--------------------------------------|:---------------:|:----------------------------:|
| [HTTP (outbound)](src/http.zig#L139) | :green_circle:  |  [Click](examples/http-out)  |
| [HTTP (inbound)](src/http.zig#L81)   | :green_circle:  |  [Click](examples/http-in)   |
| [Redis (outbound)](src/redis.zig)    | :yellow_circle: | [Click](examples/redis-out)  |
| [Redis (inbound)](src/redis.zig)     | :yellow_circle: |  [Click](examples/redis-in)  |
| [Key-value store](src/kvs.zig)       | :green_circle:  |    [Click](examples/kvs)     |
| [PostgreSQL](src/postgresql.zig)     | :yellow_circle: | [Click](examples/postgresql) |
| [MySQL](src/mysql.zig)               | :yellow_circle: |   [Click](examples/mysql)    |
| [SQLite](src/sqlite.zig)             | :yellow_circle: |   [Click](examples/sqlite)   |
| [Config](src/config.zig)             | :green_circle:  |   [Click](examples/config)   |
| [MQTT](src/mqtt.zig)                 |  :red_circle:   |    [Click](examples/mqtt)    |
| [LLM](src/llm.zig)                   |  :red_circle:   |    [Click](examples/llm)     |

### :arrow_down: Dependencies

- [`wit-bindgen-cli` - guest language WIT bindings generator](https://github.com/fermyon/wit-bindgen-backport).

    ```sh
    cargo install --git https://github.com/fermyon/wit-bindgen-backport --rev b89d507 wit-bindgen-cli
    ```

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-spin/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/zig-spin/blob/main/.github/workflows/ci.yaml
[cd-shd]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-spin/cd.yaml?branch=main&style=for-the-badge&logo=github&label=CD&labelColor=black
[cd-url]: https://github.com/tensorush/zig-spin/blob/main/.github/workflows/cd.yaml
[dc-shd]: https://img.shields.io/badge/click-F6A516?style=for-the-badge&logo=zig&logoColor=F6A516&label=doc&labelColor=black
[dc-url]: https://tensorush.github.io/zig-spin
[lc-shd]: https://img.shields.io/github/license/tensorush/zig-spin.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/tensorush/zig-spin/blob/main/LICENSE.md
