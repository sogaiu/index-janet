# index-janet

Generate tags / TAGS files for janet source code.

## Setup

```
git clone https:/github.com/sogaiu/index-janet
cd index-janet
jpm install
```

This should install a script named `idx-janet`.

## Usage

Assuming Janet source code lives in `~/src/janet`, to
generate `tags`:

```
cd ~/src/janet
idx-janet
```

This should produce a `tags` file.

For `TAGS` (emacs):

```
cd ~/src/janet
IJ_OUTPUT_FORMAT=etags idx-janet
```

This should produce a `TAGS` file.

