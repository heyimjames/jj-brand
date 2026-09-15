/* The Dock app's executable.
 *
 * Two reasons it is a compiled binary rather than a shell script:
 *
 *  1. A bundle whose CFBundleExecutable is a script makes macOS ask to install
 *     Rosetta — there is no Mach-O header to read an architecture from, so
 *     LaunchServices assumes x86_64.
 *  2. A notification posted by `osascript` is attributed to OSASCRIPT, so it
 *     wears the Script Editor icon. Posted through UNUserNotificationCenter
 *     from inside the bundle, it wears ours.
 *
 * Authorisation can be refused, and a refusal is silent, so the osascript path
 * stays as the fallback: the worst case is the borrowed icon we had before,
 * never a missing notification.
 */
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

static NSString *RunGround(int *rc) {
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:@"/bin/sh"];
    NSString *script = [NSHomeDirectory()
        stringByAppendingPathComponent:@".claude/themes/terminal-app/jj-ground.sh"];
    task.arguments = @[script, @"cycle"];
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    NSError *err = nil;
    if (![task launchAndReturnError:&err]) { *rc = 1; return err.localizedDescription; }
    NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
    [task waitUntilExit];
    *rc = task.terminationStatus;
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static void ViaOsascript(NSString *body, BOOL alert) {
    NSTask *t = [[NSTask alloc] init];
    t.executableURL = [NSURL fileURLWithPath:@"/usr/bin/osascript"];
    NSString *src = alert
        ? @"display alert \"Jack & Jill\" message (system attribute \"JJOUT\") as warning"
        : @"display notification (system attribute \"JJOUT\") with title \"Jack & Jill\"";
    t.arguments = @[@"-e", src];
    NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary:
                                NSProcessInfo.processInfo.environment];
    env[@"JJOUT"] = body ?: @"";
    t.environment = env;
    [t launchAndReturnError:nil];
    [t waitUntilExit];
}

int main(void) {
    @autoreleasepool {
        int rc = 0;
        NSString *out = RunGround(&rc);
        if (rc != 0) { ViaOsascript(out, YES); return 1; }

        __block BOOL finished = NO, delivered = NO;
        UNUserNotificationCenter *centre = nil;
        @try { centre = [UNUserNotificationCenter currentNotificationCenter]; }
        @catch (NSException *e) { centre = nil; }

        if (centre) {
            [centre requestAuthorizationWithOptions:UNAuthorizationOptionAlert
                                  completionHandler:^(BOOL granted, NSError *error) {
                if (!granted) { finished = YES; return; }
                UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                content.title = @"Jack & Jill";
                content.body = out;
                UNNotificationRequest *req =
                    [UNNotificationRequest requestWithIdentifier:NSUUID.UUID.UUIDString
                                                        content:content
                                                        trigger:nil];
                [centre addNotificationRequest:req withCompletionHandler:^(NSError *e) {
                    delivered = (e == nil);
                    finished = YES;
                }];
            }];
            NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:4.0];
            while (!finished && deadline.timeIntervalSinceNow > 0) {
                [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode
                                       beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
            }
        }
        if (!delivered) ViaOsascript(out, NO);
        return 0;
    }
}
