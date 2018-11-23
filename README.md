`antipopd`
==========

Copyright (c) Matthew Robinson 2010, 2018 

Email: matt@blendedcocoa.com

`antipopd` is a drop in replacement for Robert Tomsick's `antipopd` 1.0.2 bash
script which is available at http://www.tomsick.net/projects/antipop.html

`antipopd` is a utility program which keeps the audio system active to stop
the popping sound that can occur when OS X puts the audio system to sleep.
This is achieved by using the Speech Synthesizer system to speak a space,
which results in no audio output but keeps the audio system awake.

The benefit of this compiled version over the bash script is a reduction
in resource overheads.  The bash script executes two expensive processes 
(`pmset` and `say`) every ten seconds (one process if `ac_only` is set to 0).

This version of `antipopd` is released, like Robert Tomsick's version, under
a Creative Commons Attribution Noncommercial Share Alike License 3.0,
http://creativecommons.org/licenses/by-nc-sa/3.0/us


Build
=====

`antipopd` can be built in a terminal using the following command:

    clang -framework AppKit -framework IOKit -arch i386 -arch x86_64 -o antipopd antipopd.m

A built version (`i386` and `x86_64`) of `antipopd` is included in the repository.

Configuration
=============

By default `antipopd` will run every ten seconds to keep the audio system 
running. If you would like `antipopd` to only *speak* when the computer is 
connected to a power source you can create a configuration file 
at `/usr/local/share/antipop/ac_only`.

If the first byte of the configuration file is a `1` the audio system will 
only be kept alive when on AC power. 

The configuration file is only read once when `antipopd` launches. Changing 
the configuration file will not take effect until `antipopd` is restarted.

Installation
============

In order to have `antipopd` run as a daemon (run automatically) it is 
necessary to configure `launchctl`. In `Terminal` run the following commands:

	sudo cp com.blendedcocoa.antipopd.plist /Library/LaunchDaemons
	sudo cp antipopd /usr/local/bin
	sudo launchctl load -w /Library/LaunchDaemons/com.blendedcocoa.antipopd.plist

You will need to provide your password to allow the installation.
