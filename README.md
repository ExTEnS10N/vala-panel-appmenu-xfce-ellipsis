# Vala Panel AppMenu XFCE Ellipise

this is a fork of [vala-panel-appmenu-xfce-git AUR package](https://aur.archlinux.org/vala-panel-appmenu-xfce-git.git) and the [source](https://gitlab.com/vala-panel-project/vala-panel-appmenu.git);

### Features

this fork add the following features:
- Ellipsis Mode: When there is more than 5 items in menubar (App name is not included in the count), the 5th to the rest items are collapse in an ellipsis-titled submenu.
- Menus will pop up on mouse hover.
- Fixed the configurations may not being saved in xfce, and the configuration UI doesn't reload the settings on show up.
- Reduce useless make dependencies than the origin aur.

### build

```shell
# Please read the PKGBUILD and run:
makepkg -si
# And to remove the make dependency
pacman -Rsn $(pacman -Qdtq)
```

### Known Issue

- I don't know why the menu may not hide automatically on mouse leave some times, besides, the first menu item may unexpected popup, since it's implemented via a hacky way. But never mind, it's still more convenient than not having the feature.
- Since these changes are just made for myself, I didn't provide translation for the ellipsis mode, and didn't properly organize the change codes.

### License

Please follow licenses of origin repository, there is no additional license for my changes.