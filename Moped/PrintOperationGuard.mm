//
//  PrintOperationGuard.mm
//
//  Moped - A general purpose text editor, small and light.
//
//  AppKit's print machinery raises rather than returning errors: a driver or PDF
//  workflow that fails throws an NSException (and occasionally a C++ exception) up
//  through `runOperation`, which would terminate the app since Swift cannot catch
//  either. This thin Objective-C++ shim converts both into a BOOL plus a reason
//  string so `MopedCommands.printDocument` can show an alert instead.
//
//  The `.mm` extension is load-bearing — the `catch (const std::exception &)` clause
//  below only compiles as Objective-C++.
//

#import "PrintOperationGuard.h"
#include <exception>

@implementation PrintOperationGuard

+ (BOOL)runPrintOperation:(NSPrintOperation *)operation
				 inWindow:(NSWindow * _Nullable)window
		  exceptionReason:(NSString * _Nullable * _Nullable)reason {
	try {
		@try {
			if (window != nil) {
				[operation runOperationModalForWindow:window delegate:nil didRunSelector:NULL contextInfo:NULL];
			} else {
				[operation runOperation];
			}
			return YES;
		}
		@catch (NSException *exception) {
			if (reason != NULL) {
				*reason = exception.reason ?: exception.name;
			}
			return NO;
		}
	} catch (const std::exception &ex) {
		if (reason != NULL) {
			*reason = [NSString stringWithUTF8String:ex.what()];
		}
		return NO;
	} catch (...) {
		if (reason != NULL) {
			*reason = @"Unknown C++ exception while printing.";
		}
		return NO;
	}
}

@end
