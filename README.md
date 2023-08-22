## :lizard: :yo_yo: **zig spin**

[![CI][ci-shield]][ci-url]
[![Codecov][codecov-shield]][codecov-url]
[![License][license-shield]][license-url]

### Zig SDK for [Spin](https://github.com/fermyon/spin), a serverless application framework, created by the [Fermyon team](https://www.fermyon.com/).

### :rocket: Usage

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
    ```

    </details>

### :battery: Progress

> Legend: :green_circle: - tested, :yellow_circle: - untested, :red_circle: - unimplemented.

| Component  |     Status      |           Example            |
|------------|:---------------:|:----------------------------:|
| KVS        |  :red_circle:   |    [Click](examples/kvs)     |
| HTTP       | :yellow_circle: |    [Click](examples/http)    |
| Redis      |  :red_circle:   |   [Click](examples/redis)    |
| Config     | :yellow_circle: |   [Click](examples/config)   |
| SQLite     |  :red_circle:   |   [Click](examples/sqlite)   |
| MySQL      |  :red_circle:   |   [Click](examples/mysql)    |
| PostgreSQL |  :red_circle:   | [Click](examples/postgresql) |

### :arrow_down: Dependencies

- [`wit-bindgen-cli v0.2.0` - guest language WIT bindings generator](https://github.com/bytecodealliance/wit-bindgen/releases/tag/v0.2.0).

    ```sh
    cargo install --git https://github.com/bytecodealliance/wit-bindgen --rev cb871cf wit-bindgen-cli
    ```

<!-- MARKDOWN LINKS -->

[ci-shield]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-spin/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/zig-spin/blob/main/.github/workflows/ci.yaml
[codecov-shield]: https://img.shields.io/codecov/c/github/tensorush/zig-spin?style=for-the-badge&labelColor=black
[codecov-url]: https://app.codecov.io/gh/tensorush/zig-spin
[license-shield]: https://img.shields.io/github/license/tensorush/zig-spin.svg?style=for-the-badge&labelColor=black
[license-url]: https://github.com/tensorush/zig-spin/blob/main/LICENSE.md
