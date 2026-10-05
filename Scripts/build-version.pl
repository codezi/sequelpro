#! /usr/bin/perl

#
#  build-version.pl
#  sequel-pro
#
#  Created by Stuart Connolly (stuconnolly.com)
#  Copyright (c) 2009 Stuart Connolly. All rights reserved.
#
#  Permission is hereby granted, free of charge, to any person
#  obtaining a copy of this software and associated documentation
#  files (the "Software"), to deal in the Software without
#  restriction, including without limitation the rights to use,
#  copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following
#  conditions:
#
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
#  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.
#
#  More info at <https://github.com/sequelpro/sequelpro>

#  Updates the application/bundle's Info.plist CFBundleVersion to
#  match that of the current Git revision.

use strict;
use warnings;

use Carp;

croak "$0: Must be run from within Xcode. Exiting..." unless $ENV{"BUILT_PRODUCTS_DIR"};

my $plist_path = "$ENV{BUILT_PRODUCTS_DIR}/$ENV{INFOPLIST_PATH}";

#
# Get the revision from Git.
#
sub _get_revision_number
{
	my $svn2git_migration_compensation = 480;

	return `git log --oneline | wc -l` + $svn2git_migration_compensation;
}

#
# Get the rveision long hash from Git.
#
sub _get_revision_long_hash
{
	return `git log -n 1 --pretty=format:%H`;
}

#
# Get the revision short hash from Git.
#
sub _get_revision_short_hash
{
	return `git log -n 1 --pretty=format:%h`;
}

printf("Updating Info.plist file at path $plist_path\n");

my $version = _get_revision_number();
my $version_long_hash = _get_revision_long_hash();
my $version_short_hash = _get_revision_short_hash();

$version_long_hash =~ s/\n//;
$version_short_hash =~ s/\n//;

croak "$0: Unable to determine Git revision. Exiting..." unless $version;
croak "$0: Unable to determine Git revision hash. Exiting..." unless $version_long_hash;
croak "$0: Unable to determine Git revision short hash. Exiting..." unless $version_short_hash;

# Xcode may remove an empty CFBundleVersion or serialize empty strings as
# <string/>. Update plist keys structurally instead of matching XML text.
for my $entry (
    ["CFBundleVersion", "$version"],
    ["SPVersionLongHash", $version_long_hash],
    ["SPVersionShortHash", $version_short_hash]
) {
    system('/usr/bin/plutil', '-replace', $entry->[0], '-string', $entry->[1], $plist_path) == 0
        or croak "Unable to update $entry->[0] in $plist_path";
}

printf("CFBundleVersion set to $version\n");
printf("SPVersionLongHash set to $version_long_hash\n");
printf("SPVersionShortHash set to $version_short_hash\n");

exit 0
