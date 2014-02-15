antipopd

Copyright (c) Matthew Robinson 2010 
Email: matt@blendedcocoa.com

antipopd is a drop in replacement for Robert Tomsick's antipopd 1.2 bash
script which is available at http://www.tomsick.net/projects/antipop

antipopd is a utility program which keeps the audio system active to stop
the popping sound that can occur when OS X puts the audio system to sleep.
This is achieved by using the Speech Synthesizer system to speak a space,
which results in no audio output but keeps the audio system awake.

The benefit of this compiled version over the bash script is a reduction
in resource overheads.  The bash script executes two expensive processes 
(pmset and say) every ten seconds (one process if ac_only is set to 0).

This version of antipopd is released, like Robert Tomsick's version, under
a Creative Commons Attribution Noncommercial Share Alike License 3.0,
http://creativecommons.org/licenses/by-nc-sa/3.0/us
