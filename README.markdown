# Enchanted Vim

This is a vim script which makes searches with `\v` (very magic) persistent.
You can turn it off temporarily with 
```viml
  let g:VeryMagic = 0 (default is 1)
```
or if you are already in the command line you can type `\m` or `\M` (see :help
`\m`).  There are also: very magic `substitute`, `global` and `vimgrep`
(`lvimgrep`), which you have to turn on if you want to use them:
```viml
  let g:VeryMagicSubstitute = 1 (default is 0)
  let g:VeryMagicGlobal = 1 (default is 0)
  let g:VeryMagicVimGrep = 1 (default is 0)
```
## How it works
It simply injects `\v` at the beginning of your pattern *after you press enter*
or after c&#95;CTRL-f.

Note: if you are using one of the two other of my plugins which are defining
maps to &lt;CR&gt; in the command line, you need to update them to the latest
version so that they will all work:
* [System](https://github.com/coot/System)
* [CommandAlias](https://github.com/coot/cmdalias_vim)

# Requirements
You have to also install
[CRDispatcher](https://www.github/coot/CRDispatcher) plugin.

