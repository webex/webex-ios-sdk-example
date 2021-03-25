//
//  LLBSDConnection.m
//  LLBSDMessaging
//
//  Created by Damien DeVille on 1/31/15.
//  Copyright (c) 2015 Damien DeVille. All rights reserved.
//
/* 2017-10-04, Cisco Systems, Inc. */

#import "LLBSDConnection.h"

#import <sys/socket.h>
#import <sys/sysctl.h>
#import <sys/un.h>
#import <TargetConditionals.h>

NSString * const LLBSDMessagingErrorDomain = @"com.ddeville.llbsdmessaging";

typedef struct {
    size_t length;
    pid_t pid;
} LLBSDMessageHeader;

static NSString * const kLLBSDConnectionMessageNameKey = @"name";
static NSString * const kLLBSDConnectionMessageUserInfoKey = @"userInfo";
static NSString * const kLLBSDConnectionMessageConnectionInfoKey = @"connectionInfo";

static const pid_t kInvalidPid = -1;

#pragma mark - LLBSDConnection

@interface LLBSDConnection ()

@property (copy, nonatomic) NSString *socketPath;
@property (assign, nonatomic) dispatch_fd_t fd;

@property (strong, nonatomic) dispatch_queue_t queue;

- (void)_startOnSerialQueue:(void (^)(NSError *error))completion;
- (void)_invalidateOnSerialQueue;

@end

@implementation LLBSDConnection

static NSString *_LLBSDConnectionValidObservationContext = @"_LLBSDConnectionValidObservationContext";

- (instancetype)initWithApplicationGroupIdentifier:(NSString *)applicationGroupIdentifier connectionIdentifier:(uint8_t)connectionIdentifier
{
    NSAssert(![self isMemberOfClass:[LLBSDConnection class]], @"Cannot instantiate the base class");
    
    self = [self init];
    if (self == nil) {
        return nil;
    }

    _fd = kInvalidPid;
    _socketPath = _createSocketPath(applicationGroupIdentifier, connectionIdentifier);
    _queue = dispatch_queue_create("com.ddeville.llbsdmessaging.serial-queue", DISPATCH_QUEUE_SERIAL);
    _processInfo = [[NSProcessInfo processInfo] processIdentifier];

    [self addObserver:self forKeyPath:@"valid" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:&_LLBSDConnectionValidObservationContext];

    return self;
}

- (void)dealloc
{
    // By removing the observer before invalidating we ensure that the invalidation handler is not invoked.
    [self removeObserver:self forKeyPath:@"valid" context:&_LLBSDConnectionValidObservationContext];
}

#pragma mark - Public

- (void)start:(void (^)(NSError *error))completion
{
    dispatch_async(self.queue, ^ {
        [self _startOnSerialQueue:completion];
    });
}

- (void)invalidate
{
    dispatch_async(self.queue, ^ {
        [self _invalidateOnSerialQueue];
    });
}

- (BOOL)isValid
{
    return (self.fd != kInvalidPid);
}

#pragma mark - KVO

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSMutableSet *keyPaths = [NSMutableSet setWithSet:[super keyPathsForValuesAffectingValueForKey:key]];

    if ([key isEqualToString:@"valid"]) {
        [keyPaths addObject:@"fd"];
    }

    return keyPaths;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &_LLBSDConnectionValidObservationContext) {
        BOOL oldValid = [change[NSKeyValueChangeOldKey] boolValue];
        BOOL newValid = [change[NSKeyValueChangeNewKey] boolValue];
        if ((oldValid && !newValid) && self.invalidationHandler) {
            self.invalidationHandler();
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Private (Serial Queue)

- (void)_startOnSerialQueue:(__unused void (^)(NSError *error))completion
{
    NSAssert(NO, @"Cannot call on the base class");
}

- (void)_invalidateOnSerialQueue
{
    NSAssert(NO, @"Cannot call on the base class");
}

#pragma mark - Private

static NSString *_createSocketPath(NSString *applicationGroupIdentifier, uint8_t connectionIdentifier)
{
	NSString *socketPath = nil;
	
    /*
     * `sockaddr_un.sun_path` has a max length of 104 characters
     * However, the container URL for the application group identifier in the simulator is much longer than that
     * Since the simulator has looser sandbox restrictions we just use /tmp
     */
#if TARGET_IPHONE_SIMULATOR
    NSString *tempGroupLocation = [NSString stringWithFormat:@"/tmp/%@", applicationGroupIdentifier];
    [[NSFileManager defaultManager] createDirectoryAtPath:tempGroupLocation withIntermediateDirectories:YES attributes:nil error:NULL];
	
	socketPath = [tempGroupLocation stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", connectionIdentifier]];
#else
    NSURL *applicationGroupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:applicationGroupIdentifier];
	NSCAssert(applicationGroupURL != nil, @"Cannot retrieve the container URL for the application group identifier %@. Make sure that it has been added to the `com.apple.security.application-groups` entitlement.", applicationGroupIdentifier);

    NSURL *socketURL = [applicationGroupURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%d", connectionIdentifier]];
	socketPath = socketURL.path;
#endif /* TARGET_IPHONE_SIMULATOR */
	
	static const int __attribute__((unused)) kSockaddrSunPathMaxLength = 104;
	NSCAssert(strlen(socketPath.UTF8String) <= kSockaddrSunPathMaxLength, @"The socket path is limited to %i characters but the path %@ is %li character. Consider using a shorter application group identifier", kSockaddrSunPathMaxLength, socketPath, strlen(socketPath.UTF8String));
	
	return socketPath;
}

static dispatch_data_t _createFramedMessageData(dispatch_data_t message, pid_t info, NSError **errorRef)
{
    LLBSDMessageHeader header;
    header.length = dispatch_data_get_size(message) + sizeof(LLBSDMessageHeader);
    dispatch_data_t headerData = dispatch_data_create(&header, sizeof(LLBSDMessageHeader), NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    return dispatch_data_create_concat(headerData, message);
}

- (dispatch_data_t)_readData:(dispatch_data_t)data toFramedMessage:(dispatch_data_t)framedMessage
{
    framedMessage = dispatch_data_create_concat(framedMessage, data);
    size_t frameSize = framedMessage ? dispatch_data_get_size(framedMessage) : 0;
    
    if (frameSize >= sizeof(LLBSDMessageHeader)) {
        LLBSDMessageHeader *header;
        dispatch_data_t subrange = dispatch_data_create_subrange(framedMessage, 0, sizeof(LLBSDMessageHeader));
        __unused dispatch_data_t headerData = dispatch_data_create_map(subrange, (const void **)&header, NULL);
        size_t messageLength = header->length;
        
        if (frameSize >= messageLength) {
            dispatch_data_t message = dispatch_data_create_subrange(framedMessage, sizeof(LLBSDMessageHeader), messageLength - sizeof(LLBSDMessageHeader));
            __strong id <LLBSDConnectionDelegate> delegate = self.delegate;
            if ([delegate respondsToSelector:@selector(connection:didReceiveMessage:fromProcess:)]) {
                [delegate connection:self didReceiveMessage:message fromProcess:header->pid];
            }
            framedMessage = dispatch_data_create_subrange(framedMessage, messageLength, frameSize - messageLength);
        }
    }
    
    return framedMessage;
}

@end

#pragma mark - LLBSDConnectionServer

static const int kLLBSDServerConnectionsBacklog = 1024;

@interface LLBSDConnectionServer ()

@property (strong, nonatomic) dispatch_source_t listeningSource;

@property (strong, nonatomic) NSMutableDictionary *fdToChannelMap;
@property (strong, nonatomic) NSMutableDictionary *infoToFdMap;
@property (strong, nonatomic) NSMutableDictionary *fdToFramedMessageMap;

@end

@implementation LLBSDConnectionServer

@dynamic delegate;

- (instancetype)initWithApplicationGroupIdentifier:(NSString *)applicationGroupIdentifier connectionIdentifier:(uint8_t)connectionIdentifier
{
    self = [super initWithApplicationGroupIdentifier:applicationGroupIdentifier connectionIdentifier:connectionIdentifier];
    if (self == nil) {
        return nil;
    }

    _fdToChannelMap = [NSMutableDictionary dictionary];
    _infoToFdMap = [NSMutableDictionary dictionary];
    _fdToFramedMessageMap = [NSMutableDictionary dictionary];

    return self;
}

- (void)broadcastMessage:(dispatch_data_t)message completion:(void (^)(NSError *error))completion
{
    dispatch_async(self.queue, ^ {
        [self _broadcastMessageOnSerialQueue:message completion:completion];
    });
}

- (void)sendMessage:(dispatch_data_t)message toClient:(pid_t)info completion:(void (^)(NSError *error))completion
{
    dispatch_async(self.queue, ^ {
        [self _sendMessageOnSerialQueue:message toClient:info completion:completion];
    });
}

#pragma mark - Private (Serial Queue)

- (void)_startOnSerialQueue:(void (^)(NSError *error))completion
{
    NSParameterAssert(self.fd == kInvalidPid);

    void (^reportError)(void) = ^ {
        if (completion) {
            NSString *description = (strerror(errno) ? [NSString stringWithUTF8String:strerror(errno)] : @"");
            completion([NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey : description}]);
        }
    };

    dispatch_fd_t fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) {
        reportError();
        return;
    }

    self.fd = fd;

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;

    const char *socket_path = self.socketPath.UTF8String;
    unlink(socket_path);
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);

    int bound = bind(fd, (struct sockaddr *)&addr, sizeof(addr));
    if (bound < 0) {
        reportError();
        return;
    }

    int listening = listen(fd, kLLBSDServerConnectionsBacklog);
    if (listening < 0) {
        reportError();
        return;
    }

    dispatch_source_t listeningSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, (uintptr_t)fd, 0, self.queue);
    dispatch_source_set_event_handler(listeningSource, ^ {
        [self _acceptNewConnection];
    });
    dispatch_resume(listeningSource);
    self.listeningSource = listeningSource;

    if (completion) {
        completion(nil);
    }
}

- (void)_invalidateOnSerialQueue
{
    [self _cleanup];

    if (self.socketPath) {
        unlink(self.socketPath.UTF8String);
        self.socketPath = nil;
    }

    if (self.fd != kInvalidPid) {
        close(self.fd);
        self.fd = kInvalidPid;
    }
}

- (void)_broadcastMessageOnSerialQueue:(dispatch_data_t)message completion:(void (^)(NSError *error))completion
{
    for (NSNumber *info in self.infoToFdMap.allKeys) {
        [self sendMessage:message toClient:info.intValue completion:completion];
    }
}

- (void)_sendMessageOnSerialQueue:(dispatch_data_t)message toClient:(pid_t)info completion:(void (^)(NSError *error))completion
{
    dispatch_fd_t fd = [self.infoToFdMap[@(info)] intValue];
    dispatch_io_t channel = self.fdToChannelMap[@(fd)];

    if (!channel) {
        completion([NSError errorWithDomain:LLBSDMessagingErrorDomain code:LLBSDMessagingInvalidChannelError userInfo:nil]);
        return;
    }

    NSError *messageError = nil;
    dispatch_data_t message_data = _createFramedMessageData(message, info, &messageError);

    if (!message_data) {
        if (completion) {
            completion(messageError);
        }
        return;
    }

    dispatch_io_write(channel, 0, message_data, self.queue, ^ (bool done, __unused dispatch_data_t data, int write_error) {
        if (done && completion) {
            completion((write_error != 0 ? [NSError errorWithDomain:NSPOSIXErrorDomain code:write_error userInfo:nil] : nil));
        }
    });
}

#pragma mark - Private

static pid_t _findProcessIdentifierBehindSocket(dispatch_fd_t fd)
{
    pid_t pid;
    socklen_t pid_len = sizeof(pid);

    int retrieved = getsockopt(fd, SOL_LOCAL, LOCAL_PEERPID, &pid, &pid_len);
    if (retrieved < 0) {
        return kInvalidPid;
    }

    return pid;
}

- (void)_acceptNewConnection
{
    struct sockaddr client_addr;
    socklen_t client_addrlen = sizeof(client_addr);
    dispatch_fd_t client_fd = accept(self.fd, &client_addr, &client_addrlen);

    if (client_fd < 0) {
        return;
    }

    BOOL accepted = NO;

    pid_t info = _findProcessIdentifierBehindSocket(client_fd);
    if (info) {
        id <LLBSDConnectionServerDelegate> delegate = self.delegate;
        accepted = [delegate server:self shouldAcceptNewConnection:info];
    }

    if (!accepted) {
        close(client_fd);
        return;
    }

    self.infoToFdMap[@(info)] = @(client_fd);
    [self _setupChannelForNewConnection:client_fd];
}

- (void)_setupChannelForNewConnection:(dispatch_fd_t)fd
{
    dispatch_io_t channel = dispatch_io_create(DISPATCH_IO_STREAM, fd, self.queue, ^ (__unused int error) {});
    dispatch_io_set_low_water(channel, 1);
    dispatch_io_set_high_water(channel, SIZE_MAX);
    self.fdToChannelMap[@(fd)] = channel;
    self.fdToFramedMessageMap[@(fd)] = dispatch_data_empty;

    dispatch_io_read(channel, 0, SIZE_MAX, self.queue, ^ (bool done, dispatch_data_t data, int error) {
        if (error) {
            return;
        }

        dispatch_data_t framedMessage = self.fdToFramedMessageMap[@(fd)];
        if (framedMessage) {
            self.fdToFramedMessageMap[@(fd)] = [self _readData:data toFramedMessage:framedMessage];
        }

        if (done) {
            [self _cleanupConnection:fd];
        }
    });
}

- (void)_cleanupConnection:(dispatch_fd_t)fd
{
    dispatch_io_t channel = self.fdToChannelMap[@(fd)];
    if (channel) {
        dispatch_io_close(channel, DISPATCH_IO_STOP);
        [self.fdToChannelMap removeObjectForKey:@(fd)];
    }
    
    [self.fdToFramedMessageMap removeObjectForKey:@(fd)];

    __block pid_t info = kInvalidPid;
    [self.infoToFdMap enumerateKeysAndObjectsUsingBlock:^ (NSNumber *connectionInfo, NSNumber *fileDescriptor, BOOL *stop) {
        if (fileDescriptor.intValue == fd) {
            info = connectionInfo.intValue;
            *stop = YES;
        }
    }];

    if (info) {
        [self.infoToFdMap removeObjectForKey:@(info)];
    }
}

- (void)_cleanup
{
    for (dispatch_io_t channel in  self.fdToChannelMap.allValues) {
        dispatch_io_close(channel, DISPATCH_IO_STOP);
    }

    [self.fdToChannelMap removeAllObjects];
    [self.fdToFramedMessageMap removeAllObjects];
    [self.infoToFdMap removeAllObjects];
}

@end

#pragma mark - LLBSDConnectionClient

@interface LLBSDConnectionClient ()

@property (strong, nonatomic) dispatch_io_t channel;
@property (strong, nonatomic) id /* dispatch_data_t */ framedMessage;

@end

@implementation LLBSDConnectionClient

@dynamic delegate;

- (void)sendMessage:(dispatch_data_t)message completion:(void (^)(NSError *error))completion
{
    dispatch_async(self.queue, ^ {
        [self _sendMessageOnSerialQueue:message completion:completion];
    });
}

#pragma mark - Private (Serial Queue)

- (void)_startOnSerialQueue:(void (^)(NSError *error))completion
{
    NSParameterAssert(self.fd == kInvalidPid);

    void (^reportError)(void) = ^ {
        if (completion) {
            NSString *description = (strerror(errno) ? [NSString stringWithUTF8String:strerror(errno)] : @"");
            completion([NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey : description}]);
        }
    };

    dispatch_fd_t fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) {
        reportError();
        return;
    }

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;

    const char *socket_path = self.socketPath.UTF8String;
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);

    int connected = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    if (connected < 0) {
        close(fd);
        NSError *underlyingError = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey : (strerror(errno) ? [NSString stringWithUTF8String:strerror(errno)] : @"")}];
        completion([NSError errorWithDomain:LLBSDMessagingErrorDomain code:LLBSDMessagingInvalidChannelError userInfo:@{NSUnderlyingErrorKey : underlyingError}]);
        return;
    }

    self.fd = fd;

    [self _setupChannel];

    if (completion) {
        completion(nil);
    }
}

- (void)_invalidateOnSerialQueue
{
    if (self.channel) {
        dispatch_io_close(self.channel, DISPATCH_IO_STOP);
        self.channel = nil;
    }
    
    self.framedMessage = nil;

    if (self.fd != kInvalidPid) {
        close(self.fd);
        self.fd = kInvalidPid;
    }
}

- (void)_sendMessageOnSerialQueue:(dispatch_data_t)message completion:(void (^)(NSError *error))completion
{
    if (!self.channel) {
        completion([NSError errorWithDomain:LLBSDMessagingErrorDomain code:LLBSDMessagingInvalidChannelError userInfo:nil]);
        return;
    }

    NSError *messageError = nil;
    dispatch_data_t message_data = _createFramedMessageData(message, self.processInfo, &messageError);

    if (!message_data) {
        if (completion) {
            completion(messageError);
        }
        return;
    }

    dispatch_io_write(self.channel, 0, message_data, self.queue, ^ (bool done, __unused dispatch_data_t data, int write_error) {
        if (done && completion) {
            completion((write_error != 0 ? [NSError errorWithDomain:NSPOSIXErrorDomain code:write_error userInfo:nil] : nil));
        }
    });
}

#pragma mark - Private

- (void)_setupChannel
{
    dispatch_io_t channel = dispatch_io_create(DISPATCH_IO_STREAM, self.fd, self.queue, ^ (__unused int error) {});
    dispatch_io_set_low_water(channel, 1);
    dispatch_io_set_high_water(channel, SIZE_MAX);
    self.channel = channel;
    self.framedMessage = dispatch_data_empty;

    dispatch_io_read(channel, 0, SIZE_MAX, self.queue, ^ (bool done, dispatch_data_t data, int error) {
        if (error) {
            return;
        }

        if (self.framedMessage) {
            self.framedMessage = [self _readData:data toFramedMessage:self.framedMessage];
        }

        if (done) {
            [self invalidate];
        }
    });
}

@end
