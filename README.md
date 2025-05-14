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
3. Create `core` directory as **git submodule**:
```bash
git submodule add git@github.com:carmenere/dtools.git core
```
4. Create file `rc.sh`:
```bash
touch rc.sh
```
5. Add to `rc.sh`:
```bash
DT_DTOOLS=$(dirname "$(realpath $0)")

echo "Loading lib ... "
. "${DT_DTOOLS}/core/lib.sh"

dt_init
```
6. Create directories:
```bash
mkdir locals
mkdir scripts
mkdir tests
mkdir tools
```
7. Add `**/locals/` to file `.gitignore`.
8. Create `rc.sh` in each directory:
```bash
touch locals/rc.sh
touch scripts/rc.sh
touch tests/rc.sh
touch tools/rc.sh
```
9. Add the following code to **each** `rc.sh` file you have just created:
```bash
if [ -n "${BASH_SOURCE}" ]; then self="${BASH_SOURCE[0]}"; else self="$0"; fi
dt_rc_load %DIRNAME% $(dirname $(realpath "$self"))
```

The placeholder `%DIRNAME%` corresponds to the appropriate directory:
- `locals`
- `scripts`
- `tests`
- `tools`

<br>

## `dtools` layout
```bash
project_root_dir
├── ...
├── dtools/
│   ├── .gitignore
│   ├── core/   # This directory is a git submodule to 'https://github.com/carmenere/dtools' project.
│   │   ├── lib.sh
│   │   ├── ...
│   │   └── rc.sh
│   ├── locals/   # Must be added to .gitignore (**/locals/). It is for overwriting project defaults in local devel environment.
│   │   ├── ...
│   │   └── rc.sh
│   ├── scripts/
│   │   ├── ...
│   │   └── rc.sh
│   ├── tests/
│   │   ├── ...
│   │   └── rc.sh
│   ├── tools/
│   │   ├── ...
│   │   └── rc.sh
│   └── rc.sh   # Loads "${DT_DTOOLS}/core/lib.sh" and calls "dt_init" function.
├── ...
```

<br>