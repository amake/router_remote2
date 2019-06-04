# Router Remote 2

This is an extremely simple remote control app for DD-WRT routers. Currently all
it does is toggle on and off the OpenVPN client.

It is a Flutter port of the original [Router
Remote](https://github.com/amake/RouterRemote/). It runs on both Android and
iOS.

# How To Use

1. Tap the Settings button in the upper right
   1. Set the username and password you use to log in to your router's control
      panel
       - Note: Only BASIC authentication is supported; these credentials will be
         sent as plain text!
   2. Set the host for the router, e.g. 192.168.1.1
2. Go back to the main screen. The VPN on/off button should now work (assuming
   you have set up the router's OpenVPN client)

# License

Apache 2.0
