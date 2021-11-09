# Bash resources

Some resources to help me write good (or at least better) Bash scripts.

Please see the accompanying template.

## Tips

### Writing scripts

Tips for scripts, as opposed to interactive command line use.

- Always prefer long form parameters (e.g. `--long-form`) over short form (e.g. `-l`).
  - This makes scripts much more readable.
- Prefix variables with `local` inside functions.
  - Variables are globally scoped by default. This reduces the scope to just the function.

## Resources

- [Shellcheck](https://www.shellcheck.net/)
- [Writing Robust Bash Shell Scripts](https://www.davidpashley.com/articles/writing-robust-shell-scripts/)
- [Minimal safe Bash script template](https://betterdev.blog/minimal-safe-bash-script-template/)
- [Safer bash scripts with 'set -euxo pipefail'](https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/)
- [Writing Shell Scripts](https://linuxcommand.org/lc3_writing_shell_scripts.php)
  - [Parameter parsing](https://linuxcommand.org/lc3_wss0120.php)
- [Advanced Bash Scripting Guide](https://tldp.org/LDP/abs/html/index.html)
  - [Parameter substitution](https://tldp.org/LDP/abs/html/parameter-substitution.html)
