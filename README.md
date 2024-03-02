# zypper little tools

zypper is a Linux package manager, used by openSUSE etc.

Here some tool around zypper.

## zypper history viewer

Show Linux (openSUSE...) user a report, listing software packages installed (by zypper) in system, grouped by

1. The time you installed/removed them
2. Installed packages, and how they got installed:
   - User choosed
   - Auto selected
   - Other ( when install packages via YaST it doesn't record which packages are auto selected)
3. Removed packages

Usage:

1. `sudo cp /var/log/zypp/history /tmp`
1. Visit [this page](https://garywill.github.io/zypper_little_tools/) and load file `history` into web

