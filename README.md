# zypInstMiss
Find what you miss installing Linux packages. This script is adapted to SUSE's `zypper`.

## Purpose
After installing Linux distro, one has installed a lot of packages. Often `libxxx` is installed but `libxxx-32bit` missed. 

This script finds what is installed and it's relative package isn't.

## Usage
For example

    zypinstmiss lang

will find installed `xxx` and uninstalled `xxx-lang`.
