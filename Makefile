# Installation directory. Override here or with: make DIREX=/another/directory
DIREX=$(HOME)/.scripts

# Set to 0 for a headless installation: make CHECK_GUI=0
# Run installed Python scripts with --no-gui when no GUI backend is available.
CHECK_GUI ?= 1

.DEFAULT_GOAL := install
.PHONY: all install install-mplot install-xplot install-xmplot check \
        check-mplot check-xplot check-xmplot help

all: install

# Check all dependencies before copying any script.
install: check
	@mkdir -p "$(DIREX)"
	install -m 755 mplot "$(DIREX)/plot"
	install -m 755 xplot "$(DIREX)/xplot"
	install -m 755 xmplot "$(DIREX)/xmplot"
	@printf '%s\n' 'Installed plot, xplot and xmplot in $(DIREX).' \
	    'Ensure that this directory is in your PATH.'

install-mplot: check-mplot
	@mkdir -p "$(DIREX)"
	install -m 755 mplot "$(DIREX)/plot"

install-xplot: check-xplot
	@mkdir -p "$(DIREX)"
	install -m 755 xplot "$(DIREX)/xplot"

install-xmplot: check-xmplot
	@mkdir -p "$(DIREX)"
	install -m 755 xmplot "$(DIREX)/xmplot"

check: check-mplot check-xplot check-xmplot

check-mplot:
	@test -r mplot || { echo 'ERROR: mplot is missing; run make from the source directory.' >&2; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { \
	    echo 'ERROR: Python 3.9+ is required. Install it (brew install python, or your OS package manager) and put python3 in PATH.' >&2; exit 1; }
	@python3 -c "$$CHECK_PYTHON_DEPS" mplot "$(CHECK_GUI)"

check-xplot:
	@test -r xplot || { echo 'ERROR: xplot is missing; run make from the source directory.' >&2; exit 1; }
	@command -v perl >/dev/null 2>&1 || { \
	    echo 'ERROR: Perl is required. Install it with brew install perl or your OS package manager.' >&2; exit 1; }
	@perl -MFile::Basename -MFile::Temp -MArchive::Extract -MMath::Trig -MMath::Complex -e 1 || { \
	    echo 'Fix: install missing Perl modules for the perl in PATH. For Archive::Extract: cpan Archive::Extract (or cpanm Archive::Extract).' >&2; exit 1; }
	@perl -c xplot
	@grace=$$(sed -n 's/^[[:space:]]*[$$]prog0[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' xplot | sed 's/[[:space:]]*$$//'); \
	    test -n "$$grace" || { echo 'ERROR: cannot read the Grace executable from $$prog0 in xplot.' >&2; exit 1; }; \
	    command -v "$$grace" >/dev/null 2>&1 || { \
	    printf '%s\n' "ERROR: xplot requires $$grace." \
	    'Fix: install QtGrace/Grace and set $$prog0 in xplot to its executable (with a trailing space).' >&2; exit 1; }; \
	    printf '%s\n' "xplot dependencies OK (Grace: $$grace)."

check-xmplot:
	@test -r xmplot || { echo 'ERROR: xmplot is missing; run make from the source directory.' >&2; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { \
	    echo 'ERROR: Python 3.9+ is required. Install it (brew install python, or your OS package manager) and put python3 in PATH.' >&2; exit 1; }
	@python3 -c "$$CHECK_PYTHON_DEPS" xmplot "$(CHECK_GUI)"

# Kept in this Makefile so dependency checks require no companion script.
# Check the same python3 selected by the installed scripts' /usr/bin/env shebang.
define CHECK_PYTHON_DEPS
import ast
import importlib
import re
import shutil
import sys
from pathlib import Path

def fail(message, fix):
    print('ERROR: ' + message, file=sys.stderr)
    print('Fix: ' + fix, file=sys.stderr)
    sys.exit(1)

program = sys.argv[1]
if sys.version_info < (3, 9):
    fail('Python 3.9+ is required; found ' + sys.version.split()[0],
         'Install a newer Python and ensure python3 in PATH selects it.')

# Parsing catches syntax errors without importing or running the plotting script.
tree = ast.parse(Path(program).read_text(encoding='utf-8'), filename=program)
if program == 'xmplot':
    executable = None
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'command' for t in node.targets):
            executable = ast.literal_eval(node.value.elts[0])
            break
    if not executable or not shutil.which(executable):
        fail('xmplot requires its configured Grace executable: ' + str(executable),
             'Install QtGrace/Grace and edit the command list in xmplot to point to its executable.')
    print('xmplot dependencies OK (Grace: ' + executable + ').')
else:
    for module in ('numpy', 'matplotlib'):
        try:
            importlib.import_module(module)
        except Exception as exc:
            fail('Cannot import ' + module + ': ' + str(exc),
                 'Run python3 -m pip install numpy "matplotlib>=3.7" in your Python environment. '
                 'If Python is externally managed, create/activate a venv first: '
                 'python3 -m venv .venv; . .venv/bin/activate; then install the packages. '
                 'Keep that environment active when using plot.')
    import matplotlib
    version = tuple(int(v) for v in re.match(r'(\d+)\.(\d+)', matplotlib.__version__).groups())
    if version < (3, 7):
        fail('Matplotlib >=3.7 is required; found ' + matplotlib.__version__,
             'Run python3 -m pip install --upgrade "matplotlib>=3.7" in your Python environment.')
    if sys.argv[2] not in ('0', '1'):
        fail('CHECK_GUI must be 0 or 1.', 'Use make CHECK_GUI=0 for a headless installation.')
    if sys.argv[2] == '1':
        try:
            backend = matplotlib.get_backend()
            module_name = backend[9:] if backend.startswith('module://') else 'matplotlib.backends.backend_' + backend.lower()
            canvas = importlib.import_module(module_name).FigureCanvas
            if not canvas.required_interactive_framework:
                raise RuntimeError('Selected backend ' + backend + ' is non-interactive')
        except Exception as exc:
            fail('Interactive Matplotlib backend unavailable: ' + str(exc),
                 'Install a GUI toolkit (e.g. python3 -m pip install PyQt6), '
                 'select it with export MPLBACKEND=QtAgg, and rerun make. '
                 'For headless use: make CHECK_GUI=0, then plot --no-gui ...')
        print('mplot GUI toolkit OK (' + backend + '); a working desktop/display is still required.')
    print('mplot dependencies OK (Python ' + sys.version.split()[0] + ', Matplotlib ' + matplotlib.__version__ + ').')
endef
export CHECK_PYTHON_DEPS

help:
	@printf '%s\n' \
	    'make                         Check dependencies and install all scripts.' \
	    'make DIREX=/path             Override the installation directory.' \
	    'make check                   Check dependencies without installing.' \
	    'make install-mplot           Install only mplot as plot.' \
	    'make install-xplot           Install only xplot.' \
	    'make install-xmplot          Install only xmplot.' \
	    'make CHECK_GUI=0             Skip the Matplotlib GUI check (headless use).'
