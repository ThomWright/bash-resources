# Bash resources

Some resources to help me write good (or at least better) Bash scripts.

Please see the accompanying template.

- [Template](./template.sh) - Template for starting new scripts.
- [Snippets](./snippets) - Reusable snippets.
- [Scripts](./scripts/) - A collection of full scripts.

## Tips

- Use a recent version of Bash.
  - MacOS (at the time of writing) uses an old version of Bash by default (3.2). Upgrade with e.g. `brew install bash`.

### Writing scripts

Tips for writing scripts, as opposed to interactive command line use.

- Use [ShellCheck](https://www.shellcheck.net/).
- Always prefer long form parameters (e.g. `--long-form`) over short form (e.g. `-l`).
  - This makes scripts much more readable.
- Prefix variables with `local` inside functions.
  - Variables are globally scoped by default. This reduces the scope to just the function.

### Tricks

- [Variable length arguments list](https://unix.stackexchange.com/questions/444113/correct-way-of-building-variable-length-argument-line-to-external-command-in-bas)
  - Use an array: `some_cmd "${args[@]}"`
- [Empty array expansion when using `nounset`](https://stackoverflow.com/questions/7577052/bash-empty-array-expansion-with-set-u)
  - To support Bash <4.4: `${arr[@]+"${arr[@]}"}`

## Resources

- [ShellCheck](https://www.shellcheck.net/)
- [Writing Robust Bash Shell Scripts](https://www.davidpashley.com/articles/writing-robust-shell-scripts/)
- [Minimal safe Bash script template](https://betterdev.blog/minimal-safe-bash-script-template/)
- [Shell Script Best Practices](https://sharats.me/posts/shell-script-best-practices/)
- [Safer bash scripts with 'set -euxo pipefail'](https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/)
- [Writing Shell Scripts](https://linuxcommand.org/lc3_writing_shell_scripts.php)
  - [Parameter parsing](https://linuxcommand.org/lc3_wss0120.php)
- [Advanced Bash Scripting Guide](https://tldp.org/LDP/abs/html/index.html)
  - [Parameter substitution](https://tldp.org/LDP/abs/html/parameter-substitution.html)
