"fzf-fs" "1" "Sun Mar 22 05:56:18 CET 2015" "0.2.0" "README"

##### README

[fzf-fs](https://github.com/D630/fzf-fs) acts like a very simple file browser/navigator for the command line by taking advantage of the general-purpose fuzzy finder [fzf](https://github.com/junegunn/fzf). Although coming without Miller columns, fzf-fs is inspired by tools like [lscd](https://github.com/hut/lscd) and [deer](https://github.com/vifon/deer), which both follow the example set by [ranger](https://github.com/hut/ranger).

##### BUGS & REQUESTS

Get in touch with fzf-fs by reading the [USAGE](../master/doc/USAGE.md) text file and have also a look at the [TODO](../master/doc/TODO.md) document. Feel free to open an issue or put in a pull request on https://github.com/D630/fzf-fs

##### GIT

To download the very latest source code:

```
git clone https://github.com/D630/fzf-fs
```

If you also want to use the latest tagged version, do something like this:

```
cd ./fzf-fs
git checkout $(git describe --abbrev=0 --tags)
```

##### NOTICE

fzf-fs follows the [Utilities portion of the POSIX specification](http://pubs.opengroup.org/stage7tc1/utilities/V3_chap04.html#tag_20) and has been written in [GNU bash](http://www.gnu.org/software/bash/) on [Debian GNU/Linux 8 (jessie)](http://pubs.opengroup.org/stage7tc1/utilities/V3_chap04.html#tag_20) with these programs/packages:

- GNU bash 4.3.30
- GNU coreutils 8.23: basename, echo, ls, md5sum, printf, sort, tail
- GNU findutils 4.4.2: find
- GNU nano version 2.2.6
- GNU sed 4.2.2
- MIRBSD KSH R50 2014/10/19
- XTerm(312)
- fzf 0.9.4 (Go version)
- less 458 (GNU regular expressions)
- ncurses 5.9.20140913: tput
- zsh 5.0.7

[mksh](https://www.mirbsd.org/mksh.htm) and [zsh](http://www.zsh.org/) users are not excluded from fzf-fs. I have been trying to keep sight [of](https://github.com/D630/fzf-fs/issues/3) [compatibility](https://github.com/D630/fzf-fs/issues/4).

##### LICENCE

Same [license](https://github.com/junegunn/fzf#license) like in fzf. Notice that fzf-fs contains a (modified) function, that is part of [liquidprompt](https://github.com/nojhan/liquidprompt/blob/master/liquidprompt).
