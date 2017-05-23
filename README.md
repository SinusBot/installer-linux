# SinusBot Installer [LINUX]

Offically supported operating systems:

- Debian 8+
- Ubuntu 14.0.4+
- CentOS 6+

Features:

- Install the sinusbot to a chosen directory
- Update the bot and youtube-dl
- Reset the password
- Uninstall the bot

The following tasks will be done:

- Checks if the linux version (Debian, Ubuntu, CentOS) is supported
- Installs the latest supported version of TS3
- Installs all necessary package dependencies
- Creates a seperate sinusbot user
- Installs the latest sinusbot version
- Installs youtube-dl
- Adds a cronjob for daily youtube-dl update and sinusbot (once supported)
- Sets all the file permissions correctly
- Generates startup files:
  - systemd file => `service sinusbot {start|stop|restart|status}`
  - init.d => `/etc/init.d/sinusbot {start|stop|restart}`
- Removes all unnessercary files and archives
- Starts the sinusbot after installation
- Option to update or remove the bot

The duration of the installation process depends on your system (how many packages need to be updated, internet connection, processing power) but typically takes about one to five minutes

> There's *no support* for *Plesk* or outdated operating systems like *Debian 7*!

[![Watch video](https://img.youtube.com/vi/_GEd_ert7PA/0.jpg)](https://www.youtube.com/watch?v=_GEd_ert7PA)
