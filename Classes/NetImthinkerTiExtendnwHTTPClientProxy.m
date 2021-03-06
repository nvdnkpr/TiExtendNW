#import "NetImthinkerTiExtendnwHTTPClientProxy.h"
#import "TiBlob.h"
#import "TiUtils.h"
// #import "TiDOMDocumentProxy.h"

#pragma mark Anonymous class extension
@interface NetImthinkerTiExtendnwHTTPClientProxy ()

#pragma mark Private properties
@property NSString *verb;
@property NSString *url;
@property BOOL forceReload;
@property KrollCallback *onloadCallback;
@property KrollCallback *onerrorCallback;
@property KrollCallback *ondatastreamCallback;
@property KrollCallback *onsendstreamCallback;

#pragma mark Private methods
// - (TiProxy *)responseXML:(NSString *)baseResponseText;

@end

#pragma mark Implementation
@implementation NetImthinkerTiExtendnwHTTPClientProxy

- (void)open:(id)args
{
    NSLog(@"Call open method");
    
    ENSURE_ARG_OR_NIL_AT_INDEX(self.verb, args, 0, NSString);
    ENSURE_ARG_OR_NIL_AT_INDEX(self.url, args, 1, NSString);
    self.engine = [[MKNetworkEngine alloc] init];
    self.operation = [self.engine operationWithURLString:self.url params:nil httpMethod:self.verb];
    
    // Options
    NSDictionary *options;
    ENSURE_ARG_OR_NIL_AT_INDEX(options, args, 2, NSDictionary);
    if (options) {
        // Freezable
        if (options[@"freezable"] && [options[@"freezable"] isKindOfClass:[NSNumber class]]) {
            [self.operation setFreezable:[TiUtils boolValue:options[@"freezable"] def:NO]];
        } else {
            [self.operation setFreezable:NO];
        }
        
        // Force reload
        if (options[@"forceReload"] && [options[@"forceReload"] isKindOfClass:[NSNumber class]]) {
            self.forceReload = [TiUtils boolValue:options[@"forceReload"] def:NO];
        } else {
            self.forceReload = NO;
        }
    }
}

- (void)setOnload:(KrollCallback *)callback
{
    NSLog(@"Call onload method");
    
    self.onloadCallback = callback;
}

- (void)setOnerror:(KrollCallback *)callback
{
    NSLog(@"Call onerror method");
    
    self.onerrorCallback = callback;
}

- (void)setOndatastream:(KrollCallback *)callback
{
    NSLog(@"Call ondatastream method");
    
    self.ondatastreamCallback = callback;
}

- (void)setOnsendstream:(KrollCallback *)callback
{
    NSLog(@"Call onsendstream method");
    
    self.onsendstreamCallback = callback;
}

- (void)setRequestHeader:(id)args
{
    NSString *key;
    NSString *value;
    ENSURE_ARG_OR_NIL_AT_INDEX(key, args, 0, NSString);
    ENSURE_ARG_OR_NIL_AT_INDEX(value, args, 1, NSString);
    [self.operation addHeader:key withValue:value];
}

- (void)send:(id)args
{
    NSLog(@"Call send method");
    
    // Weak reference self object for blocks
    __block NetImthinkerTiExtendnwHTTPClientProxy *weakself = self;
    
    // Prepare send parameter
    if ([[self.verb uppercaseString] isEqualToString:@"GET"]) {
        ENSURE_SINGLE_ARG(args, NSDictionary);
        if (args) {
            // TODO: Construct GET query parameter
        }
    } else {
        for (id arg in args) {
            if ([arg isKindOfClass:[NSString class]]) {
                // NSString
                [self.operation addData:[(NSString *)arg dataUsingEncoding:NSUTF8StringEncoding] forKey:nil];
                
            } else if ([arg isKindOfClass:[NSDictionary class]]) {
                // NSDictionary
                for (id key in arg) {
                    id value = arg[key];
                    if ([value isKindOfClass:[TiBlob class]] || [value isKindOfClass:[TiFile class]]) {
                        // Blob
                        TiBlob *blob = [value isKindOfClass:[TiBlob class]] ? (TiBlob *)value : [(TiFile *)value blob];
                        if ([blob type] == TiBlobTypeFile) {
                            // File
                            [self.operation addFile:[blob path] forKey:key];
                        } else {
                            // Data
                            NSData *data = [blob data];
                            [self.operation addData:data forKey:key];
                        }
                        
                    } else {
                        // Other format (Convert to NSData)
                        [self.operation addData:[(NSString *)value dataUsingEncoding:NSUTF8StringEncoding] forKey:(NSString *)key];
                    }
                }
                
            } else if ([arg isKindOfClass:[TiBlob class]] || [arg isKindOfClass:[TiFile class]]) {
                // TiBlob or TiFile
                TiBlob *blob = [arg isKindOfClass:[TiBlob class]] ? (TiBlob *)arg : [(TiFile *)arg blob];
                if ([blob type] == TiBlobTypeFile) {
                    // File
                    [self.operation addFile:[blob path] forKey:nil];
                } else {
                    NSData *data = [blob data];
                    [self.operation addData:data forKey:nil];
                }
                
            }
        }
    }
    
    // Set send parameter
    [self.operation addParams:nil];
    
    // Set ondatastream / onsendstream hander
    if (self.ondatastreamCallback != nil) {
        [self.operation onDownloadProgressChanged:^(double progress) {
            [weakself _fireEventToListener:@"ondatastream"
                                withObject:@{@"progress": NUMDOUBLE(progress)}
                                  listener:weakself.ondatastreamCallback
                                thisObject:nil];
        }];
    }
    if (self.onsendstreamCallback != nil) {
        [self.operation onUploadProgressChanged:^(double progress) {
            [weakself _fireEventToListener:@"onsendstream"
                                withObject:@{@"progress": NUMDOUBLE(progress)}
                                  listener:weakself.onsendstreamCallback
                                thisObject:nil];
        }];
    }
    
    // Set onload / onerror hander
    [self.operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        // Success
        if (weakself.onloadCallback != nil) {
            NSDictionary *successResponse = @{@"error": @"",
                                              @"code": @(completedOperation.HTTPStatusCode),
                                              @"success": @YES};
            
            // Set response code
            [weakself setValue:@(completedOperation.HTTPStatusCode) forUndefinedKey:@"status"];
            [weakself setValue:[@(completedOperation.HTTPStatusCode) stringValue] forUndefinedKey:@"statusText"];
            
            // Set response headers
            NSDictionary *headers = completedOperation.readonlyResponse.allHeaderFields;
            [weakself setValue:headers forUndefinedKey:@"allResponseHeaders"];
            
            // Set response objects
            if (completedOperation.responseData != nil) {
                // Content-Type
                NSString *contentType;
                if (headers[@"Content-Type"]) {
                    contentType = headers[@"Content-Type"];
                } else {
                    contentType = @"application/octet-stream";
                }
                TiBlob *blob = [[TiBlob alloc] initWithData:completedOperation.responseData mimetype:contentType];
                [weakself setValue:blob forUndefinedKey:@"responseData"];
            }
            if (completedOperation.responseString != nil) {
                [weakself setValue:completedOperation.responseString forUndefinedKey:@"responseText"];
                // [weakself setValue:[weakself responseXML:completedOperation.responseString] forKey:@"responseXML"];
            }
            if (completedOperation.responseJSON != nil) {
                [weakself setValue:completedOperation.responseJSON forUndefinedKey:@"responseJSON"];
            }
            
            // Onload callback
            [weakself _fireEventToListener:@"onload"
                                withObject:successResponse
                                  listener:weakself.onloadCallback
                                thisObject:nil];
        } else {
            NSLog(@"Missing onload callback");
        }
        
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        // Error
        if (weakself.onerrorCallback != nil) {
            NSDictionary *errorResponse = @{@"error": [error localizedDescription],
                                            @"code": @(completedOperation.HTTPStatusCode),
                                            @"success": @NO};
            // Onerror callback
            [weakself _fireEventToListener:@"onerror"
                                withObject:errorResponse
                                  listener:weakself.onerrorCallback
                                thisObject:nil];
        } else {
            NSLog(@"Missing onerror callback");
        }
        
    }];
    
    // Start request operation
    [self.engine enqueueOperation:self.operation forceReload:self.forceReload];
}

#pragma mark Private methods
//- (TiProxy *)responseXML:(NSString *)baseResponseText
//{
//    if (baseResponseText) {
//        TiDOMDocumentProxy *dom = [[TiDOMDocumentProxy alloc] _initWithPageContext:[self executionContext]];
//        [dom parseString:baseResponseText];
//        return dom;
//    }
//    return (id)[NSNull null];
//}

@end
