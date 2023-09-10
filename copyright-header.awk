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
    # Used to separate copyright years as well
    FS="[, ]"
}

BEGINFILE {
	print "-> " FILENAME
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
	for (author in git_file_authors) {
		print author " (C) " format_years(git_file_authors[author])
		for (year in git_file_authors[author]) {
			print "Year: " year
		}
	}
}

ENDFILE {
	git_last_author = ""
	delete git_file_authors
}


# [2018,2020,2021,2022] -> "2018, 2020-2022"
function format_years(years_array)
{
	prev_year = 0
	formatted = ""
	for (year in years_array) {
		switch (formatted) {
		case /-$/:
			if (year != prev_year + 1) {
				formatted = formatted prev_year ", "
			}
		default:
			if (year != prev_year + 1) {
				formatted = formatted prev_year ", "
			} else {
				formatted = formatted prev_year "-"
			}
		}
		prev_year = year
	}
	# Take care of the last one
	if (formatted ~ /-$/) {
		formatted = formatted prev_year
	} else {
		formatted = formatted prev_year
	}
	return formatted
}
