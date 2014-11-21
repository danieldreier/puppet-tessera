#!/bin/bash
# poor man's beaker

TESTCASE='readme_example.pp'

set -x # debug mode, show commands as they're run
set -e # exit on error so that subsequent tests fail the build
puppet module install pkg/*.tar.gz
puppet module list | grep -i tessera #fail if module didn't install at all
puppet module list | grep -i vcsrepo #fail if module didn't install dependency
puppet apply tests/${TESTCASE} > >(tee stdout.log) 2> >(tee stderr.log >&2)
! grep 'Error: ' stderr.log # should be no errors
! grep 'has failures: true' stdout.log # no failures, either

# run again and test for idempotency
puppet apply tests/${TESTCASE} > >(tee stdout2.log) 2> >(tee stderr2.log >&2)
! grep ': created' stdout2.log
! grep 'Error: ' stderr2.log # should be no errors
! grep 'has failures: true' stdout2.log # no failures, either
! grep 'Triggered ' stdout2.log # or refreshes
! grep 'Notice: ' stdout2.log # or anything else, really

# verify that a few random expected changes were made
# very rough smoke test
[ -d /opt/tessera ]
[ -d /var/run/tessera ]
[ -d /opt/tessera/.git ]

# validate that an expected setting was put in place
grep 'SERVER_PORT = 5000' /opt/tessera/tessera/config.py
# verify that valid python syntax was created
python -c "__import__('compiler').parse(open('/opt/tessera/tessera/config.py').read())"

# packages / apps that ought to end up available
type pip
type npm

