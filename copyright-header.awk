#!/usr/bin/gawk -f

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2023 Clément Joly

# This program relies on a number of gawk-specific extensions. Please run it
# with GNU AWK.
BEGIN {
	# Scanning order https://www.gnu.org/software/gawk/manual/html_node/Controlling-Scanning.html
	# This is enough because all years are the same length ("2XXX")
	PROCINFO["sorted_in"] = "@ind_num_asc"
	# Some invalid copyright lines were enconutered or some lines were missing
	invalid_lines = 0
}

BEGINFILE {
	git_blame = "git blame --porcelain -- '" FILENAME "'"
	while ((git_blame | getline) > 0) {
		# This relies on encountering the author before the year, which
		# should always happen
		if (match($0, /^author /)) {
			git_last_author = substr($0, RLENGTH + 1)
		}
		if (match($0, /^author-time /)) {
			git_file_authors[git_last_author][strftime("%Y", substr($0, RLENGTH))] = 1
		}
	}
	close(git_blame)
}

# Copyright line format follows this recommandation:
# https://www.gnu.org/licenses/gpl-howto.html#copyright-notice, although it
# allows for years and copyright owner to be in a random order
match($0, /[Cc]opyright (\([cC]\)|\302\251)?/) {
	n = split(substr($0, RSTART + RLENGTH), years_author, /[, ]/)
	author_name = ""
	for (i = 1; i <= n; i++) {
		switch (years_author[i]) {
		case /[12][90][0-9][0-9]/:
			years[years_author[i]] = 1
			break
		case /[^ \t]/:
			author_name = author_name " " years_author[i]
			break
		default:
			# Skip spaces
			break
		}
	}
	# Remove the space at the start
	author_name = substr(author_name, 2)
	# Check that the years are the same and if so, mark the author as properly
	# credited
	expected_years = length(git_file_authors[author_name])
	if (expected_years == length(years)) {
		all_equal = 1
		for (y in git_file_authors[author_name]) {
			if (years[y] != git_file_authors[author_name][y]) {
				all_equal = 0
				break
			}
		}
		if (! all_equal) {
			print FILENAME "|" FNR "| Unexpected years, should be 'Copyright (C) " format_years(git_file_authors[author]) " " author "'"
			invalid_lines++
		}
		delete git_file_authors[author_name]
	}
	if (expected_years < length(years)) {
		print FILENAME "|" FNR "| Too few years, should be 'Copyright (C) " format_years(git_file_authors[author]) " " author "'"
		invalid_lines++
		delete git_file_authors[author_name]
	}
	if (expected_years > length(years)) {
		print FILENAME "|" FNR "| Too many years, should be 'Copyright (C) " format_years(git_file_authors[author]) " " author "'"
		invalid_lines++
		delete git_file_authors[author_name]
	}
}

ENDFILE {
	# All that’s left is what wasn’t properly formatted or what was entirely
	# absent
	for (author in git_file_authors) {
		print FILENAME "|1| Add line 'Copyright (C) " format_years(git_file_authors[author]) " " author "'"
		invalid_lines++
	}
	# Clear variables
	git_last_author = ""
	delete git_file_authors
}

END {
	if (invalid_lines > 0) {
		print "Encountered " invalid_lines " errors"
		exit 2
	}
}


# Supports only full enumeration of copyright years, since
# https://www.gnu.org/licenses/gpl-howto.html#copyright-notice recommands to use
# a range only if its use is documented
function format_years(years_array)
{
	formatted = ""
	prev_year = 0
	for (year in years_array) {
		if (prev_year) {
			formatted = formatted prev_year ", "
		}
		prev_year = year
	}
	formatted = formatted prev_year
	return formatted
}
