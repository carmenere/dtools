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

dt_rc
```
6. Create directories:
```bash
mkdir locals
mkdir stands
mkdir tools
```
7. Add `**/locals/` to file `.gitignore`.
8. Create `rc.sh` in each directory:
```bash
touch locals/rc.sh
touch stands/rc.sh
touch tools/rc.sh
```
9. Add `dt_rc_load %dirname% $(dirname $(realpath "$0"))` to rc.sh file in appropriate directory `%dirname%`:
- `dt_rc_load locals $(dirname $(realpath "$0"))` to file `locals/rc.sh`;
- `dt_rc_load stands $(dirname $(realpath "$0"))` to file `stands/rc.sh`;
- `dt_rc_load tools $(dirname $(realpath "$0"))` to file `tools/rc.sh`;

<br>

## `dtools` layout
```bash
project_root_dir
├── ...
├── dtools/
│   ├── .gitignore
│   ├── core/       # This directory is a git submodule to 'https://github.com/carmenere/dtools' project.
│   │   ├── lib.sh
│   │   ├── ...
│   │   └── rc.sh
│   ├── locals/    # Must be added to .gitignore (**/locals/). It is for overwriting project defaults in local devel environment.
│   │   ├── ...
│   │   └── rc.sh
│   ├── stands/
│   │   ├── ...
│   │   └── rc.sh
│   ├── tools/
│   │   ├── ...
│   │   └── rc.sh
│   └── rc.sh       # Loads "${DT_DTOOLS}/core/lib.sh" and calls "dt_rc" function.
├── ...
```

<br>