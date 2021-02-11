# Dotfiles

**Warning:** these are scripts and configs are designed for my own custom workflows. Use at your own risk!

## Usage

Clone this repository into `~/dotfiles`.

Add the following to your `~/.bashrc` or `~/.bash_profile`

```
. ~/dotfiles/configs/.bashrc
```

Add the following to your `~/.gitconfig` file:

```
[include]
    path = <dotfiles_location>/configs/.gitconfig
```

If you want scripts to be available in non-bash shells (e.g. powershell), then update the PATH environment variables to include the `scripts` folder.

## Additional scripts

If you have local scripts you want to include, then symbolically link them to `~/dotfiles/local-scripts`.

For windows: `mklink /D "<dotfiles_location>\local-scripts" "<folder_of_local_scripts>"`

This folder is git ignored.

You may wish to include this path in the environment PATH.