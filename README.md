# Nodi Homebrew tap

Install a prebuilt macOS binary (Apple Silicon or Intel), verified by SHA-256:

```sh
brew install MaximSavhenko/nodi/nodi
nodi version
nodi help
```

Update and remove:

```sh
brew update
brew upgrade MaximSavhenko/nodi/nodi
brew uninstall MaximSavhenko/nodi/nodi
```

No local Go compilation is performed. Formula/nodi.rb is synchronized hourly from a stable [Nodi release](https://github.com/MaximSavhenko/nodi/releases) only when its validation.json confirms all native platform checks and winget validation. The update workflow can also be run manually. The tap uses its own scoped GITHUB_TOKEN and needs no cross-repository PAT. Formula changes trigger actual Homebrew install/test/uninstall jobs on Apple Silicon and Intel GitHub runners.

Source and configuration: [MaximSavhenko/nodi](https://github.com/MaximSavhenko/nodi). Engineering packages are stored separately in the private nodi-packages repository. Public source license: MIT.

Nodi 0.2 installs bash and zsh completion definitions in Homebrew's standard directories. Enable Homebrew completion in your shell as described in https://docs.brew.sh/Shell-Completion; profiles are not edited by this tap. Alternatively, run `nodi completion` for session-only instructions, including PowerShell.

For versions after 0.1.0, CI also installs the existing 0.1.0 Formula and upgrades it to the current confirmed version before checking commands, completion files and uninstall.
