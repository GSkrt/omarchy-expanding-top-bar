# Contributing

How to get the code, work on it, and send it back. Read
[docs/UI-GUIDE.md](docs/UI-GUIDE.md) for how the UI is built and
[docs/TESTING.md](docs/TESTING.md) for how to check your change.

## The rules

- Work from the **`develop`** branch, never from `master`. `master` is what users
  install.
- Never commit straight to `develop` or `master`. Make a branch, open a pull
  request **into `develop`**.
- Do not change version numbers or `manifest.json`; releases are done by the
  maintainer.
- Small, focused pull requests are easier to review and easier to undo.

Only want to **try** the development version, not change it? See "Try the development
version" in the [README](README.md).

## Do I have write access?

The repository is public, so anyone can clone and pull it. Only people the
maintainer has added as **collaborators** can push to it. If you were not added,
`git push` fails with something like:

```
remote: Permission to GSkrt/omarchy-expanding-top-bar.git denied to <you>.
fatal: unable to access ...: The requested URL returned error: 403
```

That is not a bug. Use **Route A** (works for everyone, no permission needed).
If the maintainer adds you as a collaborator, you can use Route B.

## One-time setup

```bash
# git and the GitHub CLI
sudo pacman -S git github-cli      # Arch / Omarchy
gh auth login                      # choose GitHub.com, HTTPS, log in via browser
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

## Route A: fork and pull request (no write access needed)

```bash
# 1. Fork and clone in one go (creates your copy on GitHub and a local clone)
gh repo fork GSkrt/omarchy-expanding-top-bar --clone
cd omarchy-expanding-top-bar

# 2. Check the remotes: origin = your fork, upstream = the main repo
git remote -v
#   origin    https://github.com/<you>/omarchy-expanding-top-bar.git
#   upstream  https://github.com/GSkrt/omarchy-expanding-top-bar.git
# (if upstream is missing: git remote add upstream https://github.com/GSkrt/omarchy-expanding-top-bar.git)

# 3. Start from the latest develop
git fetch upstream
git checkout -b feature/my-change upstream/develop

# 4. Work, then commit
git add -A
git commit -m "Short description of what and why"

# 5. Push the branch to YOUR fork
git push -u origin feature/my-change

# 6. Open the pull request against develop on the main repo
gh pr create --repo GSkrt/omarchy-expanding-top-bar --base develop \
  --title "Short description" --body "What changed, how you tested it (see docs/TESTING.md), screenshot or gif"
```

Keeping your branch up to date while you work:

```bash
git fetch upstream
git rebase upstream/develop        # replays your commits on top of the latest develop
git push --force-with-lease        # only needed if the branch was already pushed
```

## Route B: you are a collaborator

```bash
# 1. Clone and switch to develop
git clone https://github.com/GSkrt/omarchy-expanding-top-bar.git
cd omarchy-expanding-top-bar
git checkout develop
git pull

# 2. Branch off develop
git checkout -b feature/my-change

# 3. Work, commit
git add -A
git commit -m "Short description of what and why"

# 4. Push the branch (first push sets the upstream)
git push -u origin feature/my-change

# 5. Open a pull request into develop
gh pr create --base develop --title "Short description" --body "What changed, how you tested it"
```

After the PR is merged:

```bash
git checkout develop
git pull
git branch -d feature/my-change
```

## Using your clone as the live plugin

So edits show up in the running bar, link your clone into the plugins folder
(details in [docs/UI-GUIDE.md](docs/UI-GUIDE.md) section 1b):

```bash
omarchy plugin add https://github.com/GSkrt/omarchy-expanding-top-bar.git --enable
rm -rf ~/.config/omarchy/plugins/io.github.gskrt.expanding-top-bar
ln -s "$PWD" ~/.config/omarchy/plugins/io.github.gskrt.expanding-top-bar
omarchy-restart-shell
```

Whichever branch is checked out in that folder is what the bar runs, so remember
to be on your feature branch (or `develop`) when you test.

## Commit messages

One short line saying what and why, in the imperative:

```
Add smart-home group icon
Fix drawer taking clicks while closed
```

Add a blank line and a few sentences when the reason isn't obvious.

## What goes in a pull request

- What changed and why, in a few sentences
- Which sections of [docs/TESTING.md](docs/TESTING.md) you ran
- A screenshot or short gif for anything visual
- Icons: the `.svg` files, plus the line added to `BUILTIN_ICONS` in `GroupModel.js`

## Things that commonly go wrong

| You see | Why | What to do |
|---|---|---|
| `403` / `Permission denied` on push | You are not a collaborator | Use Route A (push to your fork), or ask to be added |
| `rejected ... (non-fast-forward)` or `fetch first` | The branch has commits you don't have | `git pull --rebase`, then push again |
| `You are in 'detached HEAD' state` | You checked out a commit, not a branch | `git checkout -b feature/my-change` to keep your work |
| Merge conflicts during rebase | Someone changed the same lines | Fix the marked files, `git add <file>`, `git rebase --continue` |
| `nothing to commit` | Changes are not saved, or the file is ignored | `git status` to see what git sees |
| Pushed to the wrong branch | Committed on `develop` or `master` directly | Don't push; move the commit: `git branch feature/x`, `git reset --hard origin/develop`, `git checkout feature/x` |
| Bar became the stock Omarchy bar | A QML error in your change | See the log, [docs/UI-GUIDE.md](docs/UI-GUIDE.md) section 1 |

## Never commit

- Your `~/.config/omarchy/shell.json` or backups of it (may contain tokens)
- Screenshots that show personal data
- Temporary test edits to `Bar.qml` (forced open states, test timers); check
  `git diff` before every commit
