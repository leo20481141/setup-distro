#!/bin/bash

if [ "$1" = "--caret-tracking" ]; then
  VALUE=$(gsettings get org.gnome.desktop.a11y.magnifier caret-tracking)
  if [ "$VALUE" = "'none'" ]; then
    gsettings set org.gnome.desktop.a11y.magnifier caret-tracking 'centered'
  else
    gsettings set org.gnome.desktop.a11y.magnifier caret-tracking 'none'
  fi
fi

if [ "$1" = "--add" ]; then
  VALUE=$(gsettings get org.gnome.desktop.a11y.magnifier mag-factor)
  VALUE=$(echo "$VALUE + .25" | bc)
  gsettings set org.gnome.desktop.a11y.magnifier mag-factor $VALUE
fi

if [ "$1" = "--substract" ]; then
  VALUE=$(gsettings get org.gnome.desktop.a11y.magnifier mag-factor)
  VALUE=$(echo "$VALUE - .25" | bc)
  gsettings set org.gnome.desktop.a11y.magnifier mag-factor $VALUE
fi
