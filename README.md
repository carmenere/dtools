# dtools
Various tools for **dev**, **build**, **deploy** and **test** automation.<br>

<br>

# Getting started
## Prepare
1. Create directory `dtools` inside root directory of a project:
```bash
mkdir dtools
```
2. Go to `dtools`:
```bash
cd dtools
```
3. Create file `rc.sh`:
```bash
touch rc.sh
```
4. Add to `rc.sh`:
```bash
DT_DTOOLS=$(dirname "$(realpath $0)")

echo "Loading lib ... "
. "${DT_DTOOLS}/core/lib.sh"

dt_rc
```
5. Create directories:
```bash
mkdir .locals
mkdir commands
mkdir ctxes
mkdir stands
```
6. Add `**/.locals/` to file `.gitignore`.
7. Create `rc.sh` in each directory:
```bash
touch .locals/rc.sh
touch commands/rc.sh
touch ctxes/rc.sh
touch stands/rc.sh
```
8. Add `dt_rc_load %dirname% $(dirname $(realpath "$0"))` to rc.sh file in appropriate directory `%dirname%`:
- `dt_rc_load .locals $(dirname $(realpath "$0"))` to file `.locals/rc.sh`;
- `dt_rc_load commands $(dirname $(realpath "$0"))` to file `commands/rc.sh`;
- `dt_rc_load ctxes $(dirname $(realpath "$0"))` to file `ctxes/rc.sh`;
- `dt_rc_load stands $(dirname $(realpath "$0"))` to file `stands/rc.sh`;

<br>

## `dtools` layout
```bash
project_root_dir
├── ...
├── dtools/
│   ├── .gitignore
│   ├── .locals/    # Must be added to .gitignore, it is for overwriting project defaults in local devel environment.
│   │   ├── ...
│   │   └── rc.sh
│   ├── core/       # This directory is a git submodule to 'https://github.com/carmenere/dtools' project.
│   │   ├── lib.sh
│   │   ├── ...
│   │   └── rc.sh
│   ├── commands/
│   │   ├── ...
│   │   └── rc.sh
│   ├── ctxes/
│   │   ├── ...
│   │   └── rc.sh
│   ├── stands/
│   │   ├── ...
│   │   └── rc.sh
│   └── rc.sh       # Loads "${DT_DTOOLS}/core/lib.sh" and calls "dt_rc" function.
├── ...
```

<br>