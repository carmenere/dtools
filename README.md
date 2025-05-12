# dtools
Various tools for dev, build, deploy and test automation.

<br>

# Layout
Create directory `dtools` inside root directory of project.<br>

<br>

```bash
project_root_dir
├── ...
├── dtools/
│   ├── .gitignore
│   ├── .local/ # must be added to .gitignore, it is for local overwriting
│   │   ├── ...
│   │   └── rc.sh
│   ├── core/    # git submodule to 'https://github.com/carmenere/dtools' project
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
│   └── rc.sh # calls calls core/lib.sh
├── ...
```