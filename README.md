# SinusBot Installer [LINUX]

Officially supported linux distributions:

- Debian 8+
- Ubuntu 14.0.4+
- CentOS 6+

Features:

- Install the SinusBot to a selected folder
- Update the SinusBot and youtube-dl
- Reset the password
- Uninstall the bot

The following tasks will be done:

- Checks if the linux distribution is supported
- Installs the latest supported version of the teamspeak client
- Installs all the necessary dependencies
- Creates a separated user
- Installs the latest SinusBot version
- Installs youtube-dl
- Adds a cronjob for daily youtube-dl update
- Sets all the file permissions correctly
- Generates startup files:
  - systemd file => `service sinusbot {start|stop|restart|status}`
  - init.d => `/etc/init.d/sinusbot {start|stop|restart}`
- Removes all temporary files
- Starts the SinusBot after installation

The duration of the installation process depends on your system (how many packages need to be updated, internet connection, processing power) but typically takes about one to five minutes.

> There's *no support* for *Plesk* or outdated operating systems like *Debian 7*!

[![Watch video](https://img.youtube.com/vi/_GEd_ert7PA/0.jpg)](https://www.youtube.com/watch?v=_GEd_ert7PA)
