//
//  PrintOperationGuard.h
//
//  Moped - A general purpose text editor, small and light.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PrintOperationGuard: NSObject

+ (BOOL)runPrintOperation:(NSPrintOperation *)operation
				 inWindow:(nullable NSWindow *)window
		  exceptionReason:(NSString * _Nullable * _Nullable)reason;

@end

NS_ASSUME_NONNULL_END
