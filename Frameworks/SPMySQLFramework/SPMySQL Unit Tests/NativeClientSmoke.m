#import <Cocoa/Cocoa.h>
#import <SPMySQL/SPMySQL.h>

// Run only against a disposable local server. No databases or tables are changed.
int main(int argc, char **argv)
{
    if (argc != 2) return 64;
    @autoreleasepool {
        SPMySQLConnection *connection = [[SPMySQLConnection alloc] init];
        connection.username = @"root";
        connection.password = @"";
        connection.useSocket = YES;
        connection.socketPath = [NSString stringWithUTF8String:argv[1]];
        connection.useKeepAlive = NO;
        connection.retryQueriesOnConnectionFailure = NO;
        if (![connection connect]) {
            NSLog(@"Connection failed: %@", [connection lastErrorMessage]);
            return 1;
        }

        // This conversion previously called an untyped IMP, which has a
        // different calling convention on Apple Silicon.
        NSString *text = @"Việt Nam ' Apple Silicon";
        NSString *quoted = [connection escapeAndQuoteString:text];
        SPMySQLResult *result = [connection queryString:
            [NSString stringWithFormat:@"SELECT %@, 1234567890123, NULL", quoted]];
        NSArray *row = [result getRowAsArray];
        if (row.count != 3 || ![row[0] isEqual:text] ||
            ![row[1] isEqual:@"1234567890123"] || row[2] != [NSNull null]) {
            NSLog(@"Buffered result failed: %@; %@", row, [connection lastErrorMessage]);
            return 2;
        }

        // The background downloader also invokes a cached BOOL-returning IMP.
        SPMySQLStreamingResultStore *store = [connection resultStoreFromQueryString:
            @"SELECT 42, 'native' UNION ALL SELECT 43, 'arm64'"];
        if (!store) {
            NSLog(@"Streaming query failed: %@", [connection lastErrorMessage]);
            return 3;
        }
        [store startDownload];
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5];
        while (!store.dataDownloaded && [deadline timeIntervalSinceNow] > 0) {
            [NSThread sleepForTimeInterval:0.01];
        }
        if (!store.dataDownloaded || [store numberOfRows] != 2 ||
            ![[store cellDataAtRow:1 column:0] isEqual:@"43"]) {
            NSLog(@"Background streaming failed (%llu rows)", [store numberOfRows]);
            return 4;
        }
        NSLog(@"PASS arm64: UTF-8 quoting, SQL NULL, 64-bit values, background streaming");
        [connection disconnect];
        [connection release];
    }
    return 0;
}
