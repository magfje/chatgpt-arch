# chatgpt-arch

Arch Linux packaging for OpenAI's official ChatGPT desktop app for Linux.

This project does not rebuild the macOS app, replace Electron, or patch the
application bundle. It verifies OpenAI's signed apt repository metadata,
downloads the matching native Linux `.deb`, and repackages its payload as a
pacman package.

> This is an unofficial community package and is not supported by OpenAI.
> OpenAI currently lists Ubuntu, Debian, and Fedora as supported distributions;
> Arch Linux may work but is not formally supported.

## Install from the personal pacman repository

```bash
git clone https://github.com/magfje/chatgpt-arch.git
cd chatgpt-arch
./scripts/setup-personal-repo.sh
```

After installation, launch **ChatGPT** from the application menu or run:

```bash
chatgpt
```

Updates are installed with the rest of the system:

```bash
sudo pacman -Syu
```

The personal repository and its packages are unsigned. The release workflow
does verify OpenAI's signed repository metadata and pinned package SHA-256
before building, but users should treat this repository as a personal trust
root.

## Build locally

```bash
makepkg -si
```

The package supports `x86_64` and `aarch64`. CI currently publishes the
`x86_64` build.

## Update metadata

```bash
./scripts/update-package.sh
makepkg --printsrcinfo > .SRCINFO
```

`update-package.sh` verifies the OpenAI `InRelease` signature with the pinned
Codex Linux Repository key, verifies each `Packages.gz` digest from that signed
metadata, and copies the published version, paths, and SHA-256 values into the
`PKGBUILD`.

Pinned repository-key fingerprint:

```text
3BFA 0E4A E8B8 CC16 A2D9 BA68 4A3B 4A56 6C46 60E4
```

## Deliberate differences from the Debian package

- Debian maintainer scripts are not executed.
- The apt repository configuration is not installed.
- The Debian-specific, unconfined AppArmor compatibility profile is omitted.
- OpenAI's application payload is otherwise copied without modification.

## Upstream

- [Official Linux documentation](https://learn.chatgpt.com/docs/linux/linux-app)
- [OpenAI Linux apt repository](https://persistent.oaistatic.com/codex-app-prod/linux/deb)

