# Hoopoo ISO

The Hoopoo ISO streamlines [the installation of Hoopoo](https://learn.omacom.io/2/the-hoopoo-manual/50/getting-started). It includes the Hoopoo Configurator as a front-end to archinstall and automatically launches the [Hoopoo Installer](https://github.com/basecamp/hoopoo) after base arch has been setup.

## Downloading the latest ISO

See the ISO link on [hoopoo.dev](https://hoopoo.dev).

## Creating the ISO

Run `./bin/hoopoo-iso-make` and the output goes into `./release`. You can build from your local $HOOPOO_PATH for testing by using `--local-source` or from a checkout of the dev branch (instead of master) by using `--dev`.

### Environment Variables

You can customize the repositories used during the build process by passing in variables:

- `HOOPOO_INSTALLER_REPO` - GitHub repository for the installer (default: `basecamp/hoopoo`)
- `HOOPOO_INSTALLER_REF` - Git ref (branch/tag) for the installer (default: `master`)

Example usage:
```bash
HOOPOO_INSTALLER_REPO="myuser/hoopoo-fork" HOOPOO_INSTALLER_REF="some-feature" ./bin/hoopoo-iso-make
```

## Testing the ISO

Run `./bin/hoopoo-iso-boot [release/hoopoo.iso]`.

## Signing the ISO

Run `./bin/hoopoo-iso-sign [gpg-user] [release/hoopoo.iso]`.

## Uploading the ISO

Run `./bin/hoopoo-iso-upload [release/hoopoo.iso]`. This requires you've configured rclone (use `rclone config`).

## Full release of the ISO

Run `./bin/hoopoo-iso-release VERSION` to create, test, sign, and upload the ISO in one flow. Add `--rc` to release an RC build instead.
