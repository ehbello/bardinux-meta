'''Send crashes to Bardinux if the package comes from Bardinux.

Copyright (C) 2009 Lionel Le Folgoc <mrpouit@ubuntu.com>
Author: Lionel Le Folgoc <mrpouit@ubuntu.com>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.  See http://www.gnu.org/copyleft/gpl.html for
the full text of the license.
'''

def add_info(report):
    try:
        if report['Package'].split()[1].find('bardinux') != -1:
            report['CrashDB'] = 'bardinux'
        if not apport.packaging.is_distro_package(report['Package'].split(0)):
            report['ThirdParty'] = 'True'
    except ValueError, e:
        return
