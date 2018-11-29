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

clang -framework AppKit -framework IOKit -arch i386 -arch x86_64 -o antipopd antipopd.m

*/

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <IOKit/ps/IOPowerSources.h>
#import <AudioToolbox/AudioToolbox.h>

#import <unistd.h>

#define ANTIPOPD_AC_ONLY_CONFIG	"/usr/local/share/antipop/ac_only"
#define ANTIPOPD_BUILT_IN_ONLY_CONFIG "/usr/local/share/antipop/built_in_only"

#define BATTERY_STATE	CFSTR("State:/IOKit/PowerSources/InternalBattery-0")
#define POWER_SOURCE	CFSTR("Power Source State")
#define	INTERVAL	10 // seconds

static BOOL runOnACOnly = NO;
static BOOL runOnBuiltInOnly = NO;

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

void *preparePropertyAddress(AudioObjectPropertyAddress *propertyAddress, UInt32 prop) {
    propertyAddress->mSelector = prop;
    propertyAddress->mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress->mElement = kAudioObjectPropertyElementMaster;

    return propertyAddress;
}

OSStatus getDeviceTransportType(AudioDeviceID deviceId, UInt32 *transportType) {
    AudioObjectPropertyAddress propertyAddress;
    preparePropertyAddress(&propertyAddress, kAudioDevicePropertyTransportType);
    UInt32 dataSize = sizeof(UInt32);

    return AudioObjectGetPropertyData(deviceId, &propertyAddress, 0, NULL, &dataSize, transportType);
}

OSStatus getDefaultOutputDevice(AudioDeviceID *deviceId) {
    AudioObjectPropertyAddress propertyAddress;
    preparePropertyAddress(&propertyAddress, kAudioHardwarePropertyDefaultOutputDevice);
    UInt32 dataSize = sizeof(AudioDeviceID);

    return AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &dataSize, deviceId);
}

OSStatus isDefaultOutputDeviceBuiltIn(BOOL *result) {
    AudioDeviceID defaultOutputId;
    OSStatus error = getDefaultOutputDevice(&defaultOutputId);

    if (error) {
        NSLog(@"Error getting default output device (code: %d)", (int) error);
        return error;
    }

    UInt32 transportType;
    error = getDeviceTransportType(defaultOutputId, &transportType);

    if (error) {
        NSLog(@"Error getting transport type for device ID: %d (code: %d)", (int) defaultOutputId, (int) error);
        return error;
    }

    *result = transportType == kAudioDeviceTransportTypeBuiltIn;

    return kAudioServicesNoError;
}

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

    if (runOnBuiltInOnly) {
        BOOL defaultOutputIsBuiltIn;
        OSStatus error = isDefaultOutputDeviceBuiltIn(&defaultOutputIsBuiltIn);

        if (error) {
            NSLog(@"Error while trying to determine default output device. Code: %d", (int) error);
            exit(error);
        }

        if (!defaultOutputIsBuiltIn) {
            return;
        }
    }

    [speech startSpeakingString:@" "];
}

// Check for the existence of the config file, check the contents
// and set parameter as appropriate
void loadConfigAndSetParameter(BOOL *parameter, char *config) {
    // Try to open the config file
	int fd = open(config, O_RDONLY);

	// If succesful look inside, otherwise proceed with default parameter
	if (fd != -1) {
		char    buffer;

		ssize_t result = read(fd, &buffer, 1);

		// ...the first byte of the file is 1
		if (result == 1 && buffer == '1') {
			*parameter = YES;
		}

		close(fd);
  }
}

int main(int argc, char *argv[]) {
    loadConfigAndSetParameter(&runOnACOnly, ANTIPOPD_AC_ONLY_CONFIG);
    loadConfigAndSetParameter(&runOnBuiltInOnly, ANTIPOPD_BUILT_IN_ONLY_CONFIG);

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
