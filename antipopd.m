// antipopd
//
// Copyright (c) Matthew Robinson 2010, 2018
// Email: matt@blendedcocoa.com
//
// See banner() below for a description of this program.
//
// This version of antipopd is released, like Robert Tomsick's version, under
// a Creative Commons Attribution Noncommercial Share Alike License 3.0,
// http://creativecommons.org/licenses/by-nc-sa/3.0/us

/*

export MACOSX_DEPLOYMENT_TARGET=10.4
clang -framework CoreFoundation -framework Foundation -framework SystemConfiguration 
  -framework AppKit -arch i386 -arch x86_64 -o antipopd antipopd.m

*/

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <IOKit/ps/IOPowerSources.h>

#import <unistd.h>

#define ANTIPOPD_CONFIG	"/usr/local/share/antipop/ac_only"
#define BATTERY_STATE	CFSTR("State:/IOKit/PowerSources/InternalBattery-0")
#define POWER_SOURCE	CFSTR("Power Source State")
#define	INTERVAL	10 // seconds

static BOOL runOnACOnly = NO;

void banner() {
	printf("antipopd\n\n");
	
	printf("Copyright (c) Matthew Robinson 2010, 2018\n"); 
	printf("Email: matt@blendedcocoa.com\n\n");
	
	printf("antipopd is a drop in replacement for Robert Tomsick's antipopd 1.0.2 bash\n");
	printf("script which is available at http://www.tomsick.net/projects/antipop\n\n");
	
	printf("antipopd is a utility program which keeps the audio system active to stop\n");
	printf("the popping sound that can occur when OS X puts the audio system to sleep.\n");
	printf("This is achieved by using the Speech Synthesizer system to speak a space,\n");
	printf("which results in no audio output but keeps the audio system awake.\n\n");
	
	printf("The benefit of this compiled version over the bash script is a reduction\n");
	printf("in resource overheads.  The bash script executes two expensive processes \n");
	printf("(pmset and say) every ten seconds (one process if ac_only is set to 0).\n\n");
	
	printf("This version of antipopd is released, like Robert Tomsick's version, under\n");
	printf("a Creative Commons Attribution Noncommercial Share Alike License 3.0,\n");
	printf("http://creativecommons.org/licenses/by-nc-sa/3.0/us\n\n");
	
}


NSSpeechSynthesizer *speech = nil;

// Timer callback that actually speaks the space
void speak(CFRunLoopTimerRef timer, void *info) {
    if (!speech) {
        speech = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
    }
    
    // If we are only supposed to run on AC power
    if (runOnACOnly) {
        // and we don't have unlimited power remaining
        if (IOPSGetTimeRemainingEstimate() != kIOPSTimeRemainingUnlimited) {
            // then return without speaking
            return;
        }
    }
    
    [speech startSpeakingString:@" "];
}

// Check for the existance of the ac_only file, check the contents
// and set runOnACOnly as appropriate
void loadACOnlyConfig() {
    // Try to open the ac_only config file
	int fd = open(ANTIPOPD_CONFIG, O_RDONLY);
	
	// If succesful look inside, otherwise proceed with runOnACOnly default
	if (fd != -1) {
		char    buffer;
		
		ssize_t result = read(fd, &buffer, 1);
				
		// ...the first byte of the file is 1
		if (result == 1 && buffer == '1') {
			runOnACOnly = YES;
		}
		
		close(fd);
  }
}

int main(int argc, char *argv[]) {
    loadACOnlyConfig();

    // Put an AutoreleasePool in place in case NSSpeechSynthesizer expects it
    @autoreleasepool {
        if (argc >= 2) { // if we have any parameter show the banner
            banner();
            exit(EXIT_SUCCESS);
        }
        
        CFRunLoopTimerContext context = {
            0, NULL, NULL, NULL, NULL,
        };
        
        CFRunLoopTimerRef timer = CFRunLoopTimerCreate(
                                                       NULL,
                                                       0,
                                                       INTERVAL,
                                                       0,
                                                       0,
                                                       speak,
                                                       &context
                                                       );
        
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopDefaultMode);
        
        CFRunLoopRun();
    }

    // It is unlikely that we will ever get here
    // as there is no way to exit the runloop

	  return(EXIT_SUCCESS);
}
