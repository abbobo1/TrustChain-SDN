# GitHub Upload Instructions

## 1. Extract the prepared repository

Copy the archive into your Kali home directory, then run:

```bash
cd ~
tar -xzf TrustChain-SDN-GitHub-ready.tar.gz
cd TrustChain-SDN
```

Keep your original 828 MB project folder as a backup. If a folder with the same
name already exists, extract the archive into another directory and review it
before replacing anything.

## 2. Configure Git identity

Use the name and email attached to your GitHub account:

```bash
git config --global user.name "Areeson Oluwatobiloba Emmanuel"
git config --global user.email "YOUR-GITHUB-EMAIL"
```

## 3. Create the local repository

```bash
git init
git branch -M main
git add .
git status
git commit -m "Initial TrustChain-SDN source release"
```

Before committing, `git status` must not list virtual environments, Fabric
binaries, generated organizations, private keys, logs or CSV results.

## 4. Create an empty GitHub repository

On GitHub, create a repository named `TrustChain-SDN`. Do not initialize it with
a README, `.gitignore` or licence because those files already exist locally.

## 5. Connect and push

Replace `YOUR-USERNAME` with your actual GitHub username:

```bash
git remote add origin https://github.com/YOUR-USERNAME/TrustChain-SDN.git
git push -u origin main
```

GitHub no longer accepts an account password for Git operations over HTTPS. Use
a personal access token when prompted, or authenticate with the GitHub CLI:

```bash
gh auth login
git push -u origin main
```

## 6. Final online check

Confirm that GitHub displays `README.md` and these source directories:

```text
blockchain-api/
sdn-controller/
trustchain-smartcontract/
opendaylight/
tests/
docs/
```

Copy the public repository URL and test it in a private/incognito browser window
before submitting it to the lecturer.
