# xplot, xmplot and mplot

Command-line plotting of numeric data, with a shared compact syntax and editable
output. Use `./PROGRAM -h` for the full option list.

| Program | Backend | Requirements | Saved project |
| --- | --- | --- | --- |
| `xplot` | Grace / QtGrace | Perl, including `Archive::Extract` | `.agr` |
| `xmplot` | Grace / QtGrace | Python 3.9+ (standard library only) | Self-contained `.agr` |
| `mplot` | Matplotlib | Python 3.9+, NumPy, Matplotlib ≥3.7 | Standalone `.py` |

Run the scripts from this directory or copy the executables into your `PATH`.
`xmplot` and `mplot` need no companion files. Interactive Matplotlib windows
require a GUI backend, such as macOS, QtAgg or TkAgg.


**Grace configuration:** In macOS systems the Xquartz server used in
official xmgrace application `brew install grace` lags a lot. A fix is
to use QTgrace instead. The `xplot` and `xmplot` scripts in this
checkout then launches
`/Applications/qtgrace.app/Contents/MacOS/qtgrace` from both `xplot` and
`xmplot`. 

For another installation, change `$prog0` in `xplot` or `command` in `xmplot` to the appropriate Grace executable.


## Installation

```sh
make                         # Check dependencies, then install all three scripts.
make check                   # Check only; do not install.
make DIREX=/another/path     # Override DIREX=$(HOME)/.scripts.
make install-mplot           # Install only mplot, under the name plot.
make install-xplot           # Install only xplot.
make install-xmplot          # Install only xmplot.
```

The default installation copies `mplot` → `plot`, `xplot` → `xplot`, and
`xmplot` → `xmplot` into `$HOME/.scripts`, with executable permissions.
Add `export PATH="$HOME/.scripts:$PATH"` to your shell configuration if needed.
You can also edit `DIREX` directly in the Makefile.

Checks cover Python/Matplotlib versions, NumPy, Perl modules, the configured
Grace executables, and Matplotlib's selected GUI toolkit. Failed checks print
installation/configuration suggestions; no packages are installed automatically.
For headless use, run `make CHECK_GUI=0` and use `plot --no-gui ...`.
The GUI check imports the toolkit but does not open a window or verify a display.
The installed Python scripts use `python3` from `PATH`; keep the required Python
environment active when running them.

## Common syntax

Options are attached to their values: `-u1:3`, `-x-2:2`, `-sfigure.py`.
Column numbers start at **1**. Quote formulas with **single quotes** to protect
`$N` from shell expansion.

| Option | Meaning |
| --- | --- |
| `-u1:2,1:3` | Plot column 1 against columns 2 and 3 |
| `-uall`, `-uone` | All Y columns against column 1; restore default selection |
| `-stxy`, `-stxydx`, `-stxydy`, `-stxydxdy` | XY data, optionally with symmetric X/Y errors |
| `-xMIN:MAX`, `-yMIN:MAX`, `-lx`, `-ly` | Axis limits and logarithmic scales |
| `-tTEXT`, `-xtTEXT`, `-ytTEXT` | Title and axis labels (`-t` is a subtitle in Grace) |
| `-l`, `-d[N]` | Legend using filenames or directories |
| `-wl`, `-wp`, `-wlp[:N]`, `-lwN`, `-psN` | Lines, points, symbol number, line width and symbol size |
| `-kN`, `-cSCHEME` | Vertical curve offset and curve color palette |
| `-sFILE`, `-show` | Save a project; print generated commands/project/script |

The Python tools (`xmplot`, `mplot`) also support `-LTEXT` for a custom legend,
`--no-gui` for generation without opening a window, and `--` before filenames
starting with a dash. Selection/style options apply to subsequent files; axes,
title, palette and legend mode are global. `-st` resets the column selection:
put a custom `-u` after it.

They read plain text, `.gz` and stdin; blank lines or `&` separate curves.
Comments (`#`), Grace metadata (`@`) and Fortran `D` exponents are accepted.
With no files they read stdin; use `-` to position stdin explicitly. Formulas
support multiple `$N` columns, arithmetic, `**` or `^`, functions such as `sin`,
`cos`, `sqrt`, `log`, `atan2`, and constants **`pi`** and **`e`**. These extended
expression guarantees do not apply to legacy `xplot`.

## xplot — legacy Grace wrapper

Retained for existing workflows. For new work, `xmplot` provides validated input,
correct multi-column formulas and safer file/process handling.

```sh
./xplot data.dat
./xplot -u1:3 -x-1:1 -l data.dat
./xplot -stxydy -u1:2:4 -wlp -sfigure.agr measurements.dat
cat data.dat | ./xplot -uall
```

## xmplot — validated Grace projects

Creates a self-contained `.agr` containing transformed data, styles and error
bars, then opens it in Grace. Input errors are reported before plotting.
Without `-s`, a unique temporary project is retained. `--no-gui` prints its path;
`-show` prints the project and still opens the GUI unless combined with
`--no-gui`.

```sh
./xmplot -u1:3 a.dat.gz -u1:2 b.dat
./xmplot '-u$1/pi:$2+$3' -l -sfigure.agr data.dat
./xmplot -stxydy -u1:2:4 -wlp measurements.dat
cat data.dat | ./xmplot --no-gui -uall -sfigure.agr
```

## mplot — Matplotlib, intensity and 3D

The default is an XY line plot with a very light gray grid. Use `--no-grid` to
remove the grid. The toolbar provides zoom, pan and image export; click XY
points to inspect coordinates or legend symbols to toggle curves. 3D plots
support mouse rotation.

```sh
./mplot -u'$1/pi:2' -l '-xt$\omega/\pi$' data.dat
./mplot --no-grid -stxydy -u1:2:4 -wlp measurements.dat
./mplot --type intensity -u1:2:3 --cmap magma --cb-label 'A(k,omega)' spectral.dat
./mplot --type image --extent=-3:3:-2:2 --aspect equal matrix.dat
./mplot --type scatter-color -u1:2:3 points.dat
./mplot --type line3d --zt z trajectory.dat
./mplot --type surface --cmap viridis surface.dat
```

`intensity` and `surface` require one complete rectangular `x:y:z` grid (row
order is arbitrary; missing or duplicate points are rejected). No interpolation
is applied. `image` reads a rectangular matrix, with origin at the bottom and
`--extent` specifying its outer boundaries. `scatter-color` accepts scattered
points; `scatter3d` is also available. `--cmap`, `--clim MIN:MAX`, `--clog` and
`--cb-label` control colors; logarithmic colors require positive values.
Use `--z MIN:MAX`, `--zt TEXT`, `--lz` for the 3D Z axis.

### Save, edit and reuse

`-sfigure.py` writes a readable script with embedded transformed data and direct,
commented Matplotlib calls in `create_figure()`. It runs independently of
`mplot`, even after the original data files are moved or deleted.

```sh
./mplot '-u$1/pi:2' -sfigure.py data.dat
python3 figure.py
python3 figure.py --no-gui --export figure.pdf

# Generate both an editable script and an image without opening a window.
./mplot --no-gui -sfigure.py --export figure.png data.dat

# Reread source files and recompute formulas whenever the saved script is run.
./mplot --link-data '-u$1/pi:2' -supdate.py data.dat
```

`--link-data` saves absolute source paths instead of embedding data and cannot
reference stdin. Without `-s`, a unique temporary script is retained and its
path is printed. Saving replaces an existing output file. Mouse interactions
change the current window, not the saved script: edit `create_figure()` to
persist labels, limits, styles or grid settings.
