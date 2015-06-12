#include <mach/mach.h>
#import <mach/mach_time.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CydiaSubstrate/CydiaSubstrate.h>
#import "IOKit/hid/IOHIDEvent.h"
#import "IOKit/hid/IOHIDEventSystem.h"
#import "IOKit/hid/IOHIDEventSystemClient.h"

//https://github.com/iolate/iOS-Private-Headers/tree/master/IOKit/hid
#import "IOKit/hid/IOHIDEvent7.h"
#import "IOKit/hid/IOHIDEventTypes7.h"
#import "IOKit/hid/IOHIDEventSystemConnection.h"
#import "CPDistributedMessagingCenter.h"

#import "rocketbootstrap.h"
#include <sys/types.h> 
#include <sys/stat.h>
#include <stdio.h>

#pragma mark - Common declaration

//#define DEBUG
#ifdef DEBUG
#   define DLog(...) NSLog(__VA_ARGS__)
#else
#   define DLog(...)
#endif


@interface STTouch : NSObject
{
@public
    int type; // 0: move/stay 1: down 2: up
    CGPoint point;
}
@end
@implementation STTouch
@end

static void SendTouchesEvent(mach_port_t port);

static NSMutableDictionary* STTouches = nil; //Dictionary{index:STTouch}
static unsigned int lastPort = 0;

static BOOL iOS7 = NO;

@interface CAWindowServer //in QuartzCore
+(id)serverIfRunning;
-(id)displayWithName:(id)name;
-(NSArray *)displays; //@property(readonly, assign) NSArray* displays;
@end

@interface CAWindowServerDisplay

-(unsigned)clientPortAtPosition:(CGPoint)position;
-(unsigned)contextIdAtPosition:(CGPoint)position;
- (unsigned int)clientPortOfContextId:(unsigned int)arg1;
-(CGRect)bounds;

//iOS7
- (unsigned int)taskPortOfContextId:(unsigned int)arg1; //New!
@end

@interface BKUserEventTimer
+ (id)sharedInstance;
- (void)userEventOccurred; //iOS6
- (void)userEventOccurredOnDisplay:(id)arg1; //iOS7

-(BOOL)respondsToSelector:(SEL)selector;
@end

@interface BKHIDSystemInterface
+ (id)sharedInstance;
- (void)injectHIDEvent:(IOHIDEventRef)arg1;
@end

@interface BKAccessibility
//IOHIDEventSystemConnectionRef
+ (id)_eventRoutingClientConnectionManager;
@end

@interface BKHIDClientConnectionManager
- (IOHIDEventSystemConnectionRef)clientForTaskPort:(unsigned int)arg1;
- (IOHIDEventSystemConnectionRef)clientForBundleID:(id)arg1;
@end

#define Int2String(i) [NSString stringWithFormat:@"%d", i]

#pragma mark - Implementation

static IOHIDEventSystemCallback original_callback;
static void iohid_event_callback (void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) {
    if (IOHIDEventGetType(event) == kIOHIDEventTypeDigitizer) {
        [STTouches removeAllObjects];
    }
    
    original_callback(target, refcon, service, event);
}
MSHook(Boolean, IOHIDEventSystemOpen, IOHIDEventSystemRef system, IOHIDEventSystemCallback callback, void* target, void* refcon, void* unused) {
    original_callback = callback;
    return _IOHIDEventSystemOpen(system, iohid_event_callback, target, refcon, unused);
}

static int getExtraIndexNumber()
{
    int r = arc4random()%14;
    r += 1; //except 0
    
    NSString* pin = Int2String(r);
    
    if ([[STTouches allKeys] containsObject:pin]) {
        return getExtraIndexNumber();
    }else{
        return r;
    }
}

static void SimulateTouchEvent(mach_port_t port, int pathIndex, int type, CGPoint touchPoint) {
    if (pathIndex == 0) return;
    
    STTouch* touch = [STTouches objectForKey:Int2String(pathIndex)] ?: [[STTouch alloc] init];
    
    touch->type = type;
    touch->point = touchPoint;
    
    [STTouches setObject:touch forKey:Int2String(pathIndex)];
    
    SendTouchesEvent(port);
}

// ============= from veency http://gitweb.saurik.com/veency.git
extern "C" {
    IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
    void IOHIDEventSystemClientDispatchEvent(IOHIDEventSystemClientRef client, IOHIDEventRef event);
}
static void SendHIDEvent(IOHIDEventRef event) {
    static IOHIDEventSystemClientRef client_(NULL);
    if (client_ == NULL)
        client_ = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    
    IOHIDEventSetSenderID(event, 0xDEFACEDBEEFFECE5);
    IOHIDEventSystemClientDispatchEvent(client_, event);
    CFRelease(event);
}
// =============
static uint64_t recCurrentTime = 0;
static uint64_t recLastTime = 0;
static int randomIndex = 0;
static FILE *file;
static NSString *filePath = nil;

double subtractTimes( uint64_t endTime, uint64_t startTime )
{
    uint64_t difference = endTime - startTime;
    static double conversion = 0.0;
    if( conversion == 0.0 )
    {
        mach_timebase_info_data_t info;
        kern_return_t err =mach_timebase_info( &info );
        //Convert the timebase into seconds
        if( err == 0  )
            conversion= 1e-6 * (double) info.numer / (double) info.denom;
    } 
    return conversion * (double)difference; 
}

void handle_event (void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) {
    NSLog(@"handle_event : %d", IOHIDEventGetType(event));
    if (IOHIDEventGetType(event)==kIOHIDEventTypeDigitizer){
        IOHIDFloat x=IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerX);
        IOHIDFloat y=IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerY);
        
        //int index = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldDigitizerIndex);
        int eventMask = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldDigitizerEventMask);
        int range = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldDigitizerRange);
        int touch = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldDigitizerTouch);
//        AbsoluteTime timeStamp = IOHIDEventGetTimeStamp(event);
        recCurrentTime = mach_absolute_time();
        id display = [[objc_getClass("CAWindowServer") serverIfRunning] displayWithName:@"LCD"];
        CGSize screen = [(CAWindowServerDisplay *)display bounds].size;
        float width = screen.width;
        float height = screen.height;
        int touchX = x * width;
        int touchY = y * height;
        NSLog(@"click : %f, %f", x*width, y*height) ;
        if (recLastTime != 0) {
            long long m_sec = subtractTimes(recCurrentTime, recLastTime);
            //NSLog(@"\ntype %d\n eventMask %d\n range %d\n touch %d\n timeStamp %lld",index,eventMask,range,touch,m_sec);
            const char *timCcontent = [[NSString stringWithFormat:@"mSleep(%lld)",m_sec] cStringUsingEncoding:NSUTF8StringEncoding];
            fwrite(timCcontent, strlen(timCcontent), 1, file);
            fwrite( "\n", 1, 1, file );
        }
        if (range == 1 && touch == 1 && eventMask != 4) {
            randomIndex = arc4random() % 10 + 1;
            const char *touchDown = [[NSString stringWithFormat:@"touchDown(%d,%d,%d)",randomIndex,touchX,touchY] cStringUsingEncoding:NSUTF8StringEncoding];
            fwrite(touchDown, strlen(touchDown), 1, file);
            fwrite( "\n", 1, 1, file );
        }
        else if (range == 1 && touch == 1 && eventMask == 4)
        {
            const char *touchMove = [[NSString stringWithFormat:@"touchMove(%d,%d,%d)",randomIndex,touchX,touchY] cStringUsingEncoding:NSUTF8StringEncoding];
            fwrite(touchMove, strlen(touchMove), 1, file);
            fwrite( "\n", 1, 1, file );
        }
        else if (range == 0 && touch == 0)
        {
            const char *touchUp = [[NSString stringWithFormat:@"touchUp(%d)",randomIndex] cStringUsingEncoding:NSUTF8StringEncoding];
            fwrite(touchUp, strlen(touchUp), 1, file);
            fwrite( "\n", 1, 1, file );
        }
        recLastTime = recCurrentTime;
    }
}
static IOHIDEventSystemClientRef ioHIDEventSystem;
static void RecordTouchesEvent()
{
    recCurrentTime = 0;
    recLastTime = 0;
    randomIndex = 0;
    NSLog(@"filePath in RecordTouchesEvent is : %@",filePath);
    if((file = fopen([filePath cStringUsingEncoding:NSUTF8StringEncoding],"wt+")))
    {
        NSLog(@"RecordTouchesEvent : 打开文件成功");
    }
    else
    {
        NSLog(@"RecordTouchesEvent : 打开文件失败");
        return;
    }
    ioHIDEventSystem = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    
    IOHIDEventSystemClientScheduleWithRunLoop(ioHIDEventSystem, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDEventSystemClientRegisterEventCallback(ioHIDEventSystem, (IOHIDEventSystemClientEventCallback)handle_event, NULL, NULL);
    
}
static void EndRecordTouchEvent()
{
    int r = fclose(file);
    if (r == 0) {
        NSLog(@"EndRecordTouchEvent : 关闭文件成功 ... ... ...");
    }
    else
    {
        NSLog(@"EndRecordTouchEvent : 关闭文件失败 ... ... ...");
    }
    IOHIDEventSystemClientUnregisterEventCallback(ioHIDEventSystem);
    IOHIDEventSystemClientUnscheduleWithRunLoop(ioHIDEventSystem, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}

static void SendTouchesEvent(mach_port_t port) {
    
    int touchCount = (int)[[STTouches allKeys] count];
    
    if (touchCount == 0) {
        return;
    }
    
    uint64_t abTime = mach_absolute_time();
    AbsoluteTime timeStamp = *(AbsoluteTime *) &abTime;
    
    //iOS6 kIOHIDDigitizerTransducerTypeHand == 35
    //iOS7 kIOHIDTransducerTypeHand == 3
    IOHIDEventRef handEvent = IOHIDEventCreateDigitizerEvent(kCFAllocatorDefault, timeStamp, iOS7 ? kIOHIDTransducerTypeHand : kIOHIDDigitizerTransducerTypeHand, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    
    //Got on iOS7.
    IOHIDEventSetIntegerValueWithOptions(handEvent, kIOHIDEventFieldDigitizerDisplayIntegrated, 1, -268435456); //-268435456
    IOHIDEventSetIntegerValueWithOptions(handEvent, kIOHIDEventFieldBuiltIn, 1, -268435456); //-268435456
    
    //It looks changing each time, but it doens't care. just don't use 0
#define kIOHIDEventDigitizerSenderID 0x000000010000027F
    IOHIDEventSetSenderID(handEvent, kIOHIDEventDigitizerSenderID);
    //
    
    int handEventMask = 0;
    int handEventTouch = 0;
    int touchingCount = 0; //except Up touch
    
    int i = 0;
    for (NSString* pIndex in [STTouches allKeys])
    {
        STTouch* touch = [STTouches objectForKey:pIndex];
        int touchType = touch->type;
        
        int eventM = (touchType == 0) ? kIOHIDDigitizerEventPosition : (kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch); //Originally, 0, 1 and 2 are used too...
        int touch_ = (touchType == 2) ? 0 : 1;
        
        float x = touch->point.x;
        float y = touch->point.y;
        
        float rX, rY;
        
        //=========================
        
        //0~1 point
        id display = [[objc_getClass("CAWindowServer") serverIfRunning] displayWithName:@"LCD"];
        CGSize screen = [(CAWindowServerDisplay *)display bounds].size;
        
        float width = MIN(screen.width, screen.height);
        float height = MAX(screen.width, screen.height);
        
//        float factor = 1.0f;
//        if (width == 640 || width == 1536) factor = 2.0f;
        
        rX = x/width;
        rY = y/height;
        
        //=========================
        
        IOHIDEventRef fingerEvent = IOHIDEventCreateDigitizerFingerEventWithQuality(kCFAllocatorDefault, timeStamp,
                                                                                    [pIndex intValue], i + 2, eventM, rX, rY, 0, 0, 0, 0, 0, 0, 0, 0, touch_, touch_, 0);
        IOHIDEventAppendEvent(handEvent, fingerEvent);
        i++;
        
        handEventTouch |= touch_;
        if (touchType == 0) {
            handEventMask |= kIOHIDDigitizerEventPosition; //4
        }else{
            handEventMask |= (kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventIdentity); //1 + 2 + 32 = 35
        }
        
        if (touchType == 2) {
            handEventMask |= kIOHIDDigitizerEventPosition;
            [STTouches removeObjectForKey:pIndex];
            //[touch release];
        }else{
            touchingCount++;
        }
    }
    
    
    //Got on iOS7.
    IOHIDEventSetIntegerValueWithOptions(handEvent, kIOHIDEventFieldDigitizerEventMask, handEventMask, -268435456);
    IOHIDEventSetIntegerValueWithOptions(handEvent, kIOHIDEventFieldDigitizerRange, handEventTouch, -268435456);
    IOHIDEventSetIntegerValueWithOptions(handEvent, kIOHIDEventFieldDigitizerTouch, handEventTouch, -268435456);
    //IOHIDEventSetIntegerValueWithOptions(handEvent, kIOHIDEventFieldDigitizerIndex, (1<<22) + (int)pow(2.0, (double)(touchingCount+1)) - 2, -268435456);
    
    BKUserEventTimer* etimer = [NSClassFromString(@"BKUserEventTimer") sharedInstance];
    
    if ([etimer respondsToSelector:@selector(userEventOccurred)]) {
        [etimer userEventOccurred];
    }else if ([etimer respondsToSelector:@selector(userEventOccurredOnDisplay:)]) {
        [etimer userEventOccurredOnDisplay:nil];
    }
    
    if (iOS7) {
        SendHIDEvent(handEvent);
    }
    else {
        original_callback(NULL, NULL, NULL, handEvent);
    }
}

#pragma mark - Communicate with Library

//typedef struct {
//    int type;
//    int index;
//    float point_x;
//    float point_y;
//} STEvent;
#define POINT(a) CGPointMake(a->point_x, a->point_y)

//static CFDataRef messageCallBack(CFMessagePortRef local, SInt32 msgid, CFDataRef cfData, void *info)
//{
//    DLog(@"### ST: Receive Message Id: %d", (int)msgid);
//    int ret = 1;
//    if (msgid == 1) {
//        if (CFDataGetLength(cfData) == sizeof(STEvent)) {
//            STEvent* touch = (STEvent *)[(NSData *)cfData bytes];
//            if (touch != NULL) {
//                
//                unsigned int port = 0;
//                if (iOS7) {
//                    id display = [[objc_getClass("CAWindowServer") serverIfRunning] displayWithName:@"LCD"];
//                    unsigned int contextId = [display contextIdAtPosition:POINT(touch)];
//                    port = [display taskPortOfContextId:contextId];
//                    
//                    if (lastPort && lastPort != port) {
//                        [STTouches removeAllObjects];
//                    }
//                    lastPort = port;
//                }
//                
//                int pathIndex = touch->index;
//                DLog(@"### ST: Received Path Index: %d", pathIndex);
//                if (pathIndex == 0) {
//                    pathIndex = getExtraIndexNumber();
//                }
//                
//                SimulateTouchEvent(port, pathIndex, touch->type, POINT(touch));
//                
//                return (CFDataRef)[[NSData alloc] initWithBytes:&pathIndex length:sizeof(pathIndex)];
//            }else{
//                DLog(@"### ST: Received STEvent is nil");
//                return NULL;
//            }
//        }
//        DLog(@"### ST: Received data is not STEvent. event size: %lu received size: %lu", sizeof(STEvent), CFDataGetLength(cfData));
//    }
//    else if(msgid == 2)
//    {
//        const char* file_path = (const char*)[(NSData *)cfData bytes];
//        filePath = [NSString stringWithUTF8String:file_path];
//        NSLog(@"Received file path is : %@",filePath);
//        RecordTouchesEvent();
//        
//        return (CFDataRef)[[NSData alloc] initWithBytes:&ret length:sizeof(ret)];
//    }
//    else if(msgid == 3)
//    {
//        EndRecordTouchEvent();
//        return (CFDataRef)[[NSData alloc] initWithBytes:&ret length:sizeof(ret)];
//    }
//    else
//    {
//        NSLog(@"### ST: Unknown message type: %d", (int)msgid); //%x
//    }
//    
//    return NULL;
//}

@interface STEvent : NSObject
{
@public
    int type;
    int index;
    float point_x;
    float point_y;
}
@end
@implementation STEvent

@end

@interface MessageServer : NSObject

+(void)handleMessageNamed:(NSString*)name withUserInfo:(NSDictionary*)message;

@end

@implementation MessageServer

+(void)handleMessageNamed:(NSString*)name withUserInfo:(NSDictionary*)message
{
    if (![name isEqualToString:@"simulateTouchMessage"]) {
        return;
    }
    if ([[message objectForKey:@"simulateTouchEvent"] intValue] == 2) {
        filePath = [message objectForKey:@"scriptPath"];
        NSLog(@"Received file path is : %@",filePath);
        RecordTouchesEvent();
    }
    if ([[message objectForKey:@"simulateTouchEvent"] intValue] == 3) {
        EndRecordTouchEvent();
    }
    if ([[message objectForKey:@"simulateTouchEvent"] intValue] == 1) {
        int type = [[message objectForKey:@"simulateTouchType"] intValue];
        int index = [[message objectForKey:@"simulateTouchIndex"] intValue];
        float pointX = [[message objectForKey:@"simulateTouchPointX"] floatValue];
        float pointY = [[message objectForKey:@"simulateTouchPointY"] floatValue];
//        NSLog(@"----- received type : %d , index : %d , x : %f , y : %f",type,index,pointX,pointY);
        //if (event) {
            
            unsigned int port = 0;
            if (iOS7) {
//                NSLog(@"----- ios7 and above ...");
                id display = [[objc_getClass("CAWindowServer") serverIfRunning] displayWithName:@"LCD"];
                unsigned int contextId = [display contextIdAtPosition:CGPointMake(pointX, pointY)];
                port = [display taskPortOfContextId:contextId];
                
                NSLog(@"----- current mach port is : %d",port);
                
                if (lastPort && lastPort != port) {
                    [STTouches removeAllObjects];
                }
                lastPort = port;
            }
            
            int pathIndex = index;
            DLog(@"### ST: Received Path Index: %d", pathIndex);
            if (pathIndex == 0) {
                pathIndex = getExtraIndexNumber();
            }
            
            SimulateTouchEvent(port, pathIndex, type, CGPointMake(pointX, pointY));
            
//        }else{
//            DLog(@"### ST: Received STEvent is nil");
//        }
    }
}

@end

#pragma mark - MSInitialize

#define MACH_PORT_NAME "com.wugensan.cnsimulatetouch"

#ifdef __cplusplus
extern "C" {
#endif
    //Cydia Substrate
    typedef const void *MSImageRef;
    
    MSImageRef MSGetImageByName(const char *file);
    void *MSFindSymbol(MSImageRef image, const char *name);
#ifdef __cplusplus
}
#endif

//static void startServerNotificationCallBack(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
//{
//    NSLog(@"##### start server tweak received start notification...");
//    
//}
MSInitialize {
    STTouches = [[NSMutableDictionary alloc] init];
    
    if (objc_getClass("BKHIDSystemInterface")) {
        iOS7 = YES;
    }
    else{
        //iOS6
        MSHookFunction(IOHIDEventSystemOpen, MSHake(IOHIDEventSystemOpen));
        iOS7 = NO;
    }

//    CFStringRef startListeningServer = CFSTR("com.wugensan.startlisteningserver");
//    CFNotificationCenterRef notificationCenter = CFNotificationCenterGetDarwinNotifyCenter();
//    CFNotificationCenterAddObserver(notificationCenter, NULL, startServerNotificationCallBack, startListeningServer, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"com.wugensan.simulatetouchcenter"];
    rocketbootstrap_distributedmessagingcenter_apply(center);
    [center runServerOnCurrentThread];
    [center registerForMessageName:@"simulateTouchMessage" target:[MessageServer class] selector:@selector(handleMessageNamed:withUserInfo:)];
}