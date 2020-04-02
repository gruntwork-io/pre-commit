import os
import sys
import glob
import unittest

if sys.version_info[0] < 3:
    import subprocess32 as subprocess
else:
    import subprocess


class TestCheckSkipEnv(unittest.TestCase):
    def setUp(self):
        self.root = get_git_root()
        self.hook_script = os.path.join(self.root, 'hooks', 'check_skip_env.py')
        self.fixture_dir = os.path.join(self.root, 'test', 'fixtures')

    def _check_success(self, files):
        subprocess.run([self.hook_script] + files, check=True)

    def _check_failure(self, files, failed_files):
        result = subprocess.run([self.hook_script] + files, stderr=subprocess.PIPE)
        self.assertEqual(result.returncode, 1)
        for f in failed_files:
            self.assertIn(f, result.stderr.decode('utf-8'))

    def test_everything_commented(self):
        self._check_success([os.path.join(self.fixture_dir, 'everything_commented_test.go')])

    def test_non_skip_uncommented(self):
        self._check_success([os.path.join(self.fixture_dir, 'non_skip_uncommented_test.go')])

    def test_skip_uncommented(self):
        test_file_path = os.path.join(self.fixture_dir, 'skip_uncommented_test.go')
        self._check_failure([test_file_path], [test_file_path])

    def test_terratest_region_uncommented(self):
        test_file_path = os.path.join(self.fixture_dir, 'terratest_region_uncommented_test.go')
        self._check_failure([test_file_path], [test_file_path])

    def test_multiple_skip_uncommented(self):
        test_file_path = os.path.join(self.fixture_dir, 'multiple_skip_uncommented_test.go')
        self._check_failure([test_file_path], [test_file_path])

    def test_nested_uncommented(self):
        test_file_path = os.path.join(self.fixture_dir, 'nested_uncommented_test.go')
        self._check_failure([test_file_path], [test_file_path])

    def test_everything(self):
        all_test_files = glob.glob(os.path.join(self.fixture_dir, '*.go'))
        failed_files = [
            os.path.join(self.fixture_dir, 'skip_uncommented_test.go'),
            os.path.join(self.fixture_dir, 'multiple_skip_uncommented_test.go'),
            os.path.join(self.fixture_dir, 'nested_uncommented_test.go'),
            os.path.join(self.fixture_dir, 'terratest_region_uncommented_test.go'),
        ]
        self._check_failure(all_test_files, failed_files)


def get_git_root():
    """ Returns the root directory of the git repository, assuming this script is run from within the repository. """
    result = subprocess.run(['git', 'rev-parse', '--show-toplevel'], stdout=subprocess.PIPE, check=True)
    if result.stdout is None:
        # TODO: concrete exception
        raise Exception('Did not get any output from git: stderr is "{}"'.format(result.stderr))
    return result.stdout.decode('utf-8').rstrip('\n')


if __name__ == '__main__':
    unittest.main()
