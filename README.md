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
    path = ~/dotfiles/configs/.gitconfig
```

If you want scripts to be available in non-bash shells (e.g. powershell), then update the PATH environment variables to include the `scripts` folder.

## AI agent skills

Agent skills live in `~/.agents/skills/`. This repo tracks two things:

- `skills/` — my own skills (one folder per skill).
- `.skill-lock.json` — manifest of installed third-party skills. Their files
  aren't committed; this file reinstalls them.

### Setup

```bash
# link Claude and the lockfile to the skills hub
mkdir -p ~/.agents/skills ~/.claude
ln -sfn ~/.agents/skills            ~/.claude/skills
ln -sfn ~/dotfiles/.skill-lock.json ~/.agents/.skill-lock.json

# link my own skills into the hub
for d in ~/dotfiles/skills/*/; do
  ln -sfn "$d" ~/.agents/skills/"$(basename "$d")"
done

# reinstall third-party skills from the manifest
npx skills experimental_install
```
