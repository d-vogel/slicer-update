# slicer-update
Just a handy script that downloads and install the latest (stable or nightly) slicer.

## usage: 

Install for your user:

`bash slicer-update.sh stable ~/bin/slicer`

Install system-wide:

`sudo bash slicer-update.sh stable /opt/slicer`

When installing system-wide, the scipt will fix permissions on the extension directory after install so that users can install extensions.


## TODO:
- ~~Download icon, create .desktop file~~ <- done in [5e1c81119b8e0607a54d79da96391f4b823f6068](https://github.com/d-vogel/slicer-update/commit/5e1c81119b8e0607a54d79da96391f4b823f6068)
- At this point why not using Open Build System?
- MacOS version...
