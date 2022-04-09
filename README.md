
For Linux distros that use zypper as package manager. 

This repo contains:

1. zypInstManAuto (**zyp**per **inst**allation **man**ually? or **auto**matically?)
1. zypInstMiss

# zypInstManAuto

This script will show what packages are chosen by user to install, what packages are automatically selected by dependency solver.

Its output:

- user-choose
- auto-select
- unsure ( when install packages via YaST it doesn't record which packages are auto selected)

Usage:

```bash
sudo cat /var/log/zypp/history | ./zypInstManuAuto
```

[想知道原理及帮助改进](https://gist.github.com/garywill/6a359a9c49f1f66cdfe86d65fb8b6857)

## Other "autoremove" discussion for zypper

- https://github.com/openSUSE/zypper/issues/116
- [How to remove unneeded rpm packages in openSUSE? - Unix &amp; Linux Stack Exchange](https://unix.stackexchange.com/questions/566153/how-to-remove-unneeded-rpm-packages-in-opensuse)
- [Zypper Equivalent for apt-get autoremove](https://forums.opensuse.org/showthread.php/519895-Zypper-Equivalent-for-apt-get-autoremove)
- https://www.reddit.com/r/openSUSE/comments/i57ld8/what_is_zypper_equivalent_of_apt_autoremove/
- [分享一个使用 zypper 实现 autoremove 的方法 - YaST &amp; Zypper - openSUSE 中文论坛](https://forum.suse.org.cn/t/topic/14137/)



# zypInstMiss

Find what you miss installing Linux packages.

After installing Linux, one has installed a lot of packages. Often `libxxx` is installed but `libxxx-32bit` missed. 

This script finds what is installed and it's relative package isn't.

Usage:

For example

    zypinstmiss lang

will find installed `xxx` and uninstalled `xxx-lang`.
