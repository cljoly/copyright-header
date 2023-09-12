# Copyright Header Checker

Check all copyright headers in your project. For use with any licenses: GPL, MPL, Apache, MIT.

Most licenses recommand to add a line with the author name and the years for each file. Example for the GNU GPL:


> To do so, attach the following notices to the program. It is safest to attach them to the start of each source file to most effectively state the exclusion of warranty; and each file should have at least the “copyright” line and a pointer to where the full notice is found.
>
>     <one line to give the program's name and a brief idea of what it does.>
>     Copyright (C) <year>  <name of author>
>
>     This program is free software: you can redistribute it and/or modify
>     […]

Maintaining accurate years can be quite tedious to maintain, so this repo contains a script to automate this.

The output can be use as a quickfix list in vim, to jump to all the places where the headers need to be tweaked.

## TODO

- [ ] Scan files
- [ ] Support more copyright header format
- [ ] Allow exclusions and tweak
