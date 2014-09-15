Throttle Proxy
==============

Just a SOCKS4/5 proxy server to limit transfer speed.

Warning
-------

This is the work of 2 hours, so it may be buggy.

Motivation
----------

I like [Tox](http://tox.im), but sometimes it takes all my bandwidth, so I thought 
it would be a good idea to limit the bandwidth for it. Yah, I know with this
I'm throtteling some elses traffic, but hey, a bad ping isn't an option when playing 
games! Or I must read something like this:

    Ally> Didn't we take heal with us, or where is he?
    Me> Ahm, I'm here.
    Ally> Why did you let me die?
    Me> Uhm, sry, I was about 0.25 sec too late, cause of my bad ping.
    Ally> You have always a bad ping, right?
    Me> No, not always, only when I stream videos or my IM is running.
    Ally> Could you pls stop streaming videos and turn this program off?
    Me> Alright, go ahead.

I was too lazy to do it the right way, i.e. writing a network driver.

Compiling
---------

This is a very simple program, I just put some Indy Components on a form.

Open tpxygui.dproj in Delphi XE3 or higher and click the compile button.

Usage
-----

There are two versions of this program

1. tpxygui (GUI version)

  1. Run the executeable
  2. Enter the transfer speed: Proxy -> Max. Speed in Bits per second.
  2. Configure your client (e.g. µTox) to connect over SOCKS4 or SOCKS5.

2. tpxyc (Console version)

  `tpxyc [-<options>]`
  
    `B<integer>`  Max Bits/s per connection
    `P<integer>` Bind to port
    `H<true|false>` Resolve host names (slower)
    `V<0..3>` Verbosity
    `s<true|false>` Save settings  
  
Binaries
--------

...
