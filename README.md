# cmake.nvim

This plugin allows you to make work with the CMake pipeline more automated. In fact, it creates Vim
commands as dynamic aliases for cmake commands for generating, building, running, testing (WIP),
installing (WIP) and packaging (WIP) a project.

In addition, it provides a way to navigate through the project in terms of CMake, for example, displaying a list
of targets, projects, directories and entities dependent on them (WIP).

## TODO

- [ ] Support CMake Presets
- [ ] Docs and help pages
- [ ] API for other plugins to interact with internal processes
- [ ] CMake settings per project (`cmake-settings.yaml`)
- [ ] Support more substitutions in `build_directory`
- [ ] Intergation with Telescope to list
  - targets
  - projects
  - directories
  - installers
  - ...

  and go to it's definitions, depentent target and other possible entities in any meaningful relations
