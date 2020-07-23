# Dotfiles

**Warning:** these are scripts and configs are designed for my own custom workflows. Use at your own risk!

## Usage

Add the following to your `~/.bashrc` or `~/.bash_profile` (replace `<dotfiles_location>` with the location where this directory is stored):

```
PATH=$PATH:<dotfiles_location>/scripts

. <dotfiles_location>/configs/.bash_aliases
```

Add the following to your `~/.gitconfig` file:

```
[include]
    path = <dotfiles_location>/configs/.gitconfig
```