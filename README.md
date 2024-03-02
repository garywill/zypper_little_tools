# zypper little tools

zypper is a Linux package manager, used by openSUSE etc.

Here some tools around zypper.

## zypper history viewer

Shows you a report listing software packages installed (installed by zypper package manager) in your Linux system, grouped by

1. The time you installed/removed them
2. Installed packages, and how they got installed:
   - User choose
   - Auto select
   - Other ( when install packages via YaST it doesn't record which packages are auto selected)
3. Removed packages

Usage:

1. `sudo cp /var/log/zypp/history /tmp`
1. Load `history` into web

