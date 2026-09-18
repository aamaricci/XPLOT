import ast
import gzip
from pathlib import Path
import re
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

SCRIPT = Path(__file__).resolve().parents[1] / 'xplot-veusz'


class XplotVeuszTests(unittest.TestCase):
    def run_plot(self, args, stdin=None):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'plot.vsz'
            result = subprocess.run(
                [sys.executable, str(SCRIPT), '--no-gui', f'-s{output}', *args],
                input=stdin, text=True, capture_output=True)
            content = output.read_text() if output.exists() else ''
            if result.returncode == 0:
                ast.parse(content)
            return result, content

    def test_stdin_blocks_expression_and_error_bars(self):
        result, doc = self.run_plot(
            ['-stxydy', '-u1:cos($2):3', '-wlp:2', '-l', '-k2'],
            '0 0 0.1\n1 1 0.2\n\n2 2 0.3\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("SetData('y1', [1.0, 0.5403023058681398], symerr=[0.1, 0.2])", doc)
        self.assertIn("SetData('y2', [1.5838531634528576], symerr=[0.3])", doc)
        self.assertEqual(doc.count("Add('xy'"), 2)
        self.assertIn("Set('key', 'stdin set 2 1:cos($2):3')", doc)

    def test_file_options_are_snapshotted_and_gzip_is_read(self):
        with tempfile.TemporaryDirectory() as tmp:
            first = Path(tmp) / 'first.dat'
            second = Path(tmp) / 'second.dat.gz'
            first.write_text('1 2 3\n2 3 4\n')
            with gzip.open(second, 'wt') as out:
                out.write('1 5 6\n2 7 8\n')
            result, doc = self.run_plot(['-u1:3', str(first), '-u1:2', str(second), '-l'])
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("SetData('y1', [3.0, 4.0]", doc)
            self.assertIn("SetData('y2', [5.0, 7.0]", doc)
            self.assertIn("Set('key', 'first.dat 1:3')", doc)
            self.assertIn("Set('key', 'second.dat.gz')", doc)

    def test_rejects_unsafe_or_bad_column_expression(self):
        result, _ = self.run_plot(['-u1:__import__("os")'], '1 2\n')
        self.assertEqual(result.returncode, 2)
        self.assertIn('unsupported function call', result.stderr)
        result, _ = self.run_plot(['-u1:3'], '1 2\n')
        self.assertEqual(result.returncode, 2)
        self.assertIn('list index out of range', result.stderr)

    def test_all_columns_axes_and_palette(self):
        result, doc = self.run_plot(
            ['-uall', '-x1:10', '-y0:8', '-lx', '-xtTime', '-ytSignal',
             '-tOverview', '-cred:blue', '-m960:720'],
            '1 2 3\n2 4 5\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(doc.count("Add('xy'"), 2)
        self.assertIn("Set('log', True)", doc)
        self.assertIn("Set('PlotLine/color', '#ff0000')", doc)
        self.assertIn("Set('PlotLine/color', '#0000ff')", doc)
        self.assertIn("Set('label', 'Overview')", doc)

    def test_dense_curves_keep_all_line_points_but_space_markers(self):
        data = ''.join(f'{i} {i * i}\n' for i in range(100))
        result, doc = self.run_plot([], data)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Set('thinfactor', 4)", doc)
        self.assertIn("Set('PlotLine/hide', False)", doc)
        self.assertIn('9801.0', doc)

    def test_tex_like_text_in_axes_title_and_legend(self):
        result, doc = self.run_plot(
            [r'-xt$\omega_n$', r'-yt$\Sigma_{xx}$', r'-t$\frac{A}{B}$',
             r'-L$\chi(i\omega_n)$'],
            '1 2\n2 3\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Set('label', " + repr(r'\omega_n') + ')', doc)
        self.assertIn("Set('label', " + repr(r'\Sigma_{xx}') + ')', doc)
        self.assertIn("Set('label', " + repr(r'\frac{A}{B}') + ')', doc)
        self.assertIn("Set('key', " + repr(r'\chi(i\omega_n)') + ')', doc)
        self.assertIn("Add('key', name='key1'", doc)

    @unittest.skipUnless(sys.platform == 'darwin', 'macOS Launch Services')
    def test_macos_open_uses_launch_services(self):
        launch = runpy.run_path(str(SCRIPT))['launch']
        with mock.patch('subprocess.run') as open_app:
            open_app.return_value.returncode = 0
            launch(Path('/tmp/plot.vsz'))
        self.assertEqual(open_app.call_args.args[0],
                         ['/usr/bin/open', '-a', '/Applications/Veusz.app',
                          '/tmp/plot.vsz'])

    def test_default_symbols_and_twelve_color_cycle(self):
        row = ' '.join(str(i) for i in range(1, 15)) + '\n'
        result, doc = self.run_plot(['-uall'], row)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(doc.count("Set('markerSize', '6pt')"), 13)
        self.assertEqual(doc.count("Set('PlotLine/hide', False)"), 13)
        self.assertIn("Set('marker', 'circle')", doc)
        self.assertIn("Set('marker', 'square')", doc)
        colors = re.findall(r"Set\('PlotLine/color', '(#[0-9a-f]{6})'\)", doc)
        self.assertEqual(len(set(colors[:12])), 12)
        self.assertEqual(colors[:3], ['#000000', '#d62728', '#1f77b4'])
        self.assertEqual(colors[12], colors[0])

        result, doc = self.run_plot(['-wl', '-ps1', '-cblue:red'], '1 2 3\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Set('marker', 'none')", doc)
        self.assertIn("Set('markerSize', '3pt')", doc)
        self.assertIn("Set('PlotLine/color', '#0000ff')", doc)


if __name__ == '__main__':
    unittest.main()
