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
mkdir tools
```
7. Add `**/locals/` to file `.gitignore`.
8. Create `rc.sh` in each directory:
```bash
touch locals/rc.sh
touch scripts/rc.sh
touch tools/rc.sh
```
9. Add the following code to **each** `rc.sh` file you have just created:
```bash
function self_dir() {
  #  $1: contains $0 of .sh script
  if [ -n "${BASH_SOURCE}" ]; then self="${BASH_SOURCE[0]}"; else self="$1"; fi
  echo "$(dirname $(realpath "${self}"))"
}
dt_rc_load $(basename "$(self_dir "$0")") "$(self_dir "$0")"
```

The placeholder `%DIRNAME%` corresponds to the appropriate directory:
- `locals`
- `scripts`
- `tools`
10. If **dir** contains **subdir**, you must put `rc.sh` file in **each** subdir and for every **subdir** add to `rc.sh` of **parent** dir (for example, `tools/rc.sh`) following:
```bash
. "$(self_dir "$0")/%SUBDIR%/rc.sh"
```
where `%SUBDIR%` is a **placeholder for subdir**.<br>

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
│   ├── tools/
│   │   ├── ...
│   │   └── rc.sh
│   └── rc.sh   # Loads "${DT_DTOOLS}/core/lib.sh" and calls "dt_init" function.
├── ...
```

<br>