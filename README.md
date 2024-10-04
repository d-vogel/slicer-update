# slicer-update
Just a handy script that downloads and install the latest (stable or nightly) slicer.

## usage: 

Install for your user:

`bash slicer-update.sh stable ~/bin/slicer`

Install system-wide:

`sudo bash slicer-update.sh stable /opt/slicer`

When installing system-wide, the scipt will fix permissions on the extension directory after install so that users can install extensions.


## TODO:
- Download icon, create .desktop file
- At this point why not using Open Build System?
- MacOS version...
