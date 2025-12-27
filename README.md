# index-janet

Generate `tags` / `TAGS` files for Janet's source code.

The index files provide lookups for Janet identifiers:

* Janet -> Janet (e.g. `if-let`)
* Janet -> C (e.g. `length` or `def`)

## Setup

Whichever method chosen below, first:

```
git clone https:/github.com/sogaiu/index-janet
```

Note that in all cases, it's assumed that `janet` has been installed.

### jpm

```
cd index-janet
jpm install
```

This should install a script named `idx.janet`.

### Via Copy or Symlink

Alternatively, after cloning, copy `idx.janet` to some directory on
`PATH`, or make a symlink from within some directory on `PATH` to
`idx.janet` in the cloned directory.

Note that this method may not work on Windows.

## Usage

Assuming Janet source code lives in `~/src/janet`, to
generate `tags`:

```
cd ~/src/janet
idx.janet
```

This should produce a `tags` file, typically used by vim / neovim.

For `TAGS` (emacs):

```
cd ~/src/janet
IJ_OUTPUT_FORMAT=etags idx.janet
```

This should produce a `TAGS` file, typically used by emacs.

