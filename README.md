## :lizard: :flying_disc: **zig spin**

[![CI][ci-shield]][ci-url]
[![CD][cd-shield]][cd-url]
[![Docs][docs-shield]][docs-url]
[![Codecov][codecov-shield]][codecov-url]
[![License][license-shield]][license-url]

### Zig SDK for the [Spin tool](https://github.com/fermyon/spin) created by the [Fermyon team](https://www.fermyon.com/).

#### :rocket: Usage

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

<!-- MARKDOWN LINKS -->

[ci-shield]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-spin/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/zig-spin/blob/main/.github/workflows/ci.yaml
[cd-shield]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-spin/cd.yaml?branch=main&style=for-the-badge&logo=github&label=CD&labelColor=black
[cd-url]: https://github.com/tensorush/zig-spin/blob/main/.github/workflows/cd.yaml
[docs-shield]: https://img.shields.io/badge/click-F6A516?style=for-the-badge&logo=zig&logoColor=F6A516&label=docs&labelColor=black
[docs-url]: https://tensorush.github.io/zig-spin
[codecov-shield]: https://img.shields.io/codecov/c/github/tensorush/zig-spin?style=for-the-badge&labelColor=black
[codecov-url]: https://app.codecov.io/gh/tensorush/zig-spin
[license-shield]: https://img.shields.io/github/license/tensorush/zig-spin.svg?style=for-the-badge&labelColor=black
[license-url]: https://github.com/tensorush/zig-spin/blob/main/LICENSE.md
