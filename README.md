Throttle Proxy
==============

Just a SOCKS4/5 proxy server to limit transfer speed.

Warning
-------

This is the work of 2 hours, so it may be buggy.

Motivation
----------

I like [Tox](http://tox.im), but sometimes it takes all my bandwidth, so I thought 
it would be a good idea to limit the bandwidth for it. I was too lazy to do it the 
right way, i.e. writing a network driver.

Compiling
---------

This is a very simple program, I just put some Indy Components on a form.

Open tpxygui.dproj in Delphi XE3 or higher and click the compile button.

Usage
-----

1. Run the executeable
2. Enter the transfer speed: Proxy -> Max. Speed in Bits per second.
2. Configure your client (e.g. µTox) to connect over SOCKS4 or SOCKS5.

Binaries
--------

...
