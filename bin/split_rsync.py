#!/usr/bin/env python
"""
Experimental

Use rsync to transfer one or more files to a destination via splitting the file
Made for *nix systems.
Assumes we can SSH to the target system without having to provide a password.
"""
import argparse
import logging
import os
import shutil
import subprocess
import tempfile


def cleanup():
    log.info("removing temp files on remote")
    rc = subprocess.call([
        'ssh', '{user}@{host}'.format(user=ssh_user, host=ssh_host),
        'rm -rf {remote_dir}'.format(remote_dir=remote_tmp_dir)
    ])
    assert rc == 0

    log.info("Removing local file splits")
    shutil.rmtree(splits_dir)


###############################################################################
parser = argparse.ArgumentParser()
parser.add_argument('--splits', type=int,
                    help='number of file splits to transfer '
                         'asynchronously')
parser.add_argument('--file',
                    help="path to the file to transfer")
parser.add_argument('--ssh-host', help='remote host to ssh file to')
parser.add_argument('--ssh-user',
                    default=os.environ['USER'],
                    help='User to ssh as. defaults to currently logged in '
                         'user name.')
parser.add_argument('--remote-dir',
                    default="~",
                    help='Directory on remote machine to put file into. '
                         'Defaults to the home directory.')
parser.add_argument('--temp-dir',
                    default=tempfile.gettempdir(),
                    help="Local filesystem directory to use as a temporary "
                         "directory for file splitting. We will create a "
                         "sub-directory under the given dir.")
parser.add_argument('-v', '--verbose', action='store_true', default=False,
                    help='print additional debug messages')

###############################################################################
args = parser.parse_args()

filepath = args.file
splits = args.splits
ssh_host = args.ssh_host
ssh_user = args.ssh_user
remote_dir = args.remote_dir
temp_dir = args.temp_dir

assert filepath
assert splits
assert ssh_host
assert ssh_user
assert remote_dir
assert temp_dir

###############################################################################
# Initialize logging stream
llevel = logging.INFO
if args.verbose:
    llevel = logging.DEBUG

log_formatter = logging.Formatter(
    "%(levelname)7s - %(asctime)s - %(name)s.%(funcName)s - %(message)s"
)
stream_handler = logging.StreamHandler()
stream_handler.setFormatter(log_formatter)
stream_handler.setLevel(llevel)
logging.getLogger().addHandler(stream_handler)
logging.getLogger().setLevel(llevel)

log = logging.getLogger(__name__)

###############################################################################
log.info("Splitting file")
splits_dir = tempfile.mkdtemp(dir=temp_dir)
rc = subprocess.call(['split', '-n', str(splits), filepath,
                      os.path.join(splits_dir, 'split.')])
assert rc == 0
split_filenames = sorted(os.listdir(splits_dir))
log.debug("local split dir: %s", splits_dir)
log.debug("split filenames: %s", split_filenames)

###############################################################################
log.info("Making remote target directory for transfer")
# noinspection PyProtectedMember
remote_tmp_dir = os.path.join(remote_dir,
                              '.' + tempfile._RandomNameSequence().next())
log.debug("remote tmp transfer path: %s", remote_tmp_dir)
subprocess.call(['ssh',
                 '{user}@{host}'.format(user=ssh_user, host=ssh_host),
                 'mkdir -p {dir}'.format(dir=remote_tmp_dir)])

###############################################################################
log.info("Spawn transfer processes")

#: :type: list[subprocess.Popen]
transfer_procs = []
for i, fn in enumerate(split_filenames):
    log.debug("  - [%d] %s", i, fn)
    transfer_procs.append(
        subprocess.Popen(['rsync', '-Pvh', os.path.join(splits_dir, fn),
                          "{user}@{host}:{dir}/".format(
                              user=ssh_user,
                              host=ssh_host,
                              dir=remote_tmp_dir,
                          )])
    )

log.info("Waiting for completion...")
failure = False
for i, p in enumerate(transfer_procs):
    rc = p.wait()
    log.debug('  - [%d] done', i)
    if rc != 0:
        log.error('    - scp FAILED with code %d', rc)
        failure = True

if failure:
    log.error("A transfer failed above")
    cleanup()
    exit(1)

###############################################################################
log.info("Combining files on remote")
remote_files = [os.path.join(remote_tmp_dir, fn) for fn in split_filenames]
rc = subprocess.call([
    'ssh', '{user}@{host}'.format(user=ssh_user, host=ssh_host),
    'cat {remote_file_list} >{target}'.format(
        remote_file_list=' '.join(remote_files),
        target=os.path.join(remote_dir, os.path.basename(filepath))
    )
])
assert rc == 0, "End file cat failed"

###############################################################################
cleanup()
log.info("Done")
