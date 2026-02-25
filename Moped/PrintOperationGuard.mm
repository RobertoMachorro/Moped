//
//  PrintOperationGuard.m
//
//  Moped - A general purpose text editor, small and light.
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
