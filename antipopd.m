// antipopd
//
// Copyright (c) Matthew Robinson 2010 
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
#import <SystemConfiguration/SystemConfiguration.h>
#import <AppKit/AppKit.h>

#import <unistd.h>

#define ANTIPOPD_CONFIG	"/usr/local/share/antipop/ac_only"
#define BATTERY_STATE	CFSTR("State:/IOKit/PowerSources/InternalBattery-0")
#define POWER_SOURCE	CFSTR("Power Source State")
#define	INTERVAL	10 // seconds

static BOOL onACPower = YES;
static BOOL runOnACOnly = YES;


void banner() {
	printf("antipopd\n\n");
	
	printf("Copyright (c) Matthew Robinson 2010\n"); 
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


// Timer callback that actually speaks the space
void speak(CFRunLoopTimerRef timer, void *info) {
	if (onACPower) {
		[(NSSpeechSynthesizer *)info startSpeakingString:@" "];
	}
}

// Callback that is called when the Power Status changes
void getPowerStatus(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {

	// Read the state of the Internal Battery
	CFPropertyListRef value = SCDynamicStoreCopyValue(
		store,
		BATTERY_STATE
	);
	
	// We should always get a dictionary but we'll check anyway 
	if (CFGetTypeID(value) == CFDictionaryGetTypeID()) {

		//Get the Power Source State
		CFStringRef powerSourceState = CFDictionaryGetValue(value, POWER_SOURCE);
		
		if (CFStringCompare(powerSourceState, CFSTR("AC Power"), 0) == 0) {
			onACPower = YES;
		} else { 
			onACPower = NO;
		}
	}

	CFRelease(value);
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
		
		// runOnACOnly is YES, unless...	
		runOnACOnly = YES;
		
		// ...the first byte of the file is 0
		if (result == 1 && buffer == '0') {
			runOnACOnly = NO;
		}
		
		close(fd);
	}	
}

int main(int argc, char *argv[]) {
	if (argc >= 2) { // if we have any parameter show the banner
		banner();
		exit(EXIT_SUCCESS);
	}
	
	SCDynamicStoreRef	store = NULL;
	
	// Put an AutoreleasePool in place in case NSSpeechSynthesizer expects it
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	loadACOnlyConfig();

	// If we only want to run on AC then create and install the callback in
	// the runloop to monitor the battery state
	if (runOnACOnly) {
		store = SCDynamicStoreCreate(
			NULL,
			CFSTR("power"),
			getPowerStatus,
			NULL
		);

		if (store) {
			CFStringRef keys[] = {BATTERY_STATE};
			CFArrayRef notificationKeys = CFArrayCreate(NULL, (void *)keys, 1, NULL);

			// Call the callback manually to set the initial Power Status
			getPowerStatus(store, notificationKeys, NULL);

			if (SCDynamicStoreSetNotificationKeys(store, notificationKeys, NULL)) {
				
				CFRunLoopSourceRef runLoopSource = SCDynamicStoreCreateRunLoopSource(
					NULL, store, 0
				);

				CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);

				CFRelease(runLoopSource);
			} else {
				// Something went wrong setting up the notifications,
				// shutdown the SCDynamicStore and continue as if 
				// runOnACOnly is NO

				CFRelease(store);

				runOnACOnly = NO;
				onACPower = YES;
			}
		} else {
			// Something went wrong connecting to the SCDynamicStore,
			// continue as if runOnACOnly is NO

			runOnACOnly = NO;
			onACPower = YES;
		}
	}

	NSSpeechSynthesizer *speech = [[NSSpeechSynthesizer alloc] initWithVoice:nil];

	CFRunLoopTimerContext context = {
		0, speech, NULL, NULL, NULL, 
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


	// It is unlikely that we will ever get here 
	// as there is no way to exit the runloop

	if (store) CFRelease(store);
	[speech release]; 

	[pool release];

	return(EXIT_SUCCESS);
}

