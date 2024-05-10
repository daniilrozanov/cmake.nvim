# cmake.nvim

This plugin allows you to make work with the CMake pipeline more automated. In fact, it creates Vim
commands as dynamic aliases for cmake commands for generating, building, running, testing (WIP),
installing (WIP) and packaging (WIP) a project.

In addition, it provides a way to navigate through the project in terms of CMake, for example, displaying a list
of targets, projects, directories and entities dependent on them (WIP).

# Install

With Lazy.nvim do
```lua
{
  'daniilrozanov/cmake.nvim',
  lazy = false,
  opts = {--[[...]]}
}
```
Since the plugin is asynchronous, you don't have to lazily load it. Loading time in a directory with a project such as ranges v3 is about 4 ms.

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
- [ ] quickfix
- [ ] Ability to keep one runner terminal per project or target
