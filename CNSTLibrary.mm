#import <mach/mach_time.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CPDistributedMessagingCenter.h"
#import "rocketbootstrap.h"
#include <sys/types.h>
#include <sys/stat.h>

#define LOOP_TIMES_IN_SECOND 40
//60
#define MACH_PORT_NAME "com.wugensan.cnsimulatetouch"
#define GET_READY_PORT_NAME @"com.wugensan.cncustomlockbutton"
#define MESSAGE_BACK_FROM_LOCKBUTTON "com.wugensan.messagebackfromlockbutton"
#define SCRIPT_PATH @"/private/var/cnsimtouch/script/"
#define SCRIPT_PATH_KEY @"SCRIPT_PATH_KEY"

typedef enum {
    STTouchMove = 0,
    STTouchDown,
    STTouchUp
} STTouchType;

//typedef struct {
//    int type;
//    int index;
//    float point_x;
//    float point_y;
//} STEvent;

//typedef enum {
//    UIInterfaceOrientationPortrait           = 1,//UIDeviceOrientationPortrait,
//    UIInterfaceOrientationPortraitUpsideDown = 2,//UIDeviceOrientationPortraitUpsideDown,
//    UIInterfaceOrientationLandscapeLeft      = 4,//UIDeviceOrientationLandscapeRight,
//    UIInterfaceOrientationLandscapeRight     = 3,//UIDeviceOrientationLandscapeLeft
//} UIInterfaceOrientation;

//@interface UIScreen
//+(id)mainScreen;
//-(CGRect)bounds;
//@end

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


@interface STTouchA : NSObject
{
@public
    int type; //0: move/stay| 1: down| 2: up
    int pathIndex;
    CGPoint startPoint;
    CGPoint endPoint;
    uint64_t startTime;
    float requestedTime;
}
@end
@implementation STTouchA
@end

//static CFMessagePortRef messagePortSmulateTouch = NULL;
//static CFMessagePortRef messagePortRecordTouch = NULL;
//static CFMessagePortRef messagePortEndRecordTouch = NULL;
//static CFMessagePortRef messagePortCustomLockButton = NULL;
//static CFMessagePortRef local = NULL;
static NSMutableArray* ATouchEvents = nil;
static BOOL FTLoopIsRunning = FALSE;

#pragma mark -

static int simulate_touch_event(int index, int type, CGPoint point) {
    
//    if (messagePortSmulateTouch && !CFMessagePortIsValid(messagePortSmulateTouch)){
//        CFRelease(messagePortSmulateTouch);
//        messagePortSmulateTouch = NULL;
//    }
//    if (!messagePortSmulateTouch) {
//        messagePortSmulateTouch = rocketbootstrap_cfmessageportcreateremote(NULL, CFSTR(MACH_PORT_NAME));
//        //messagePort = CFMessagePortCreateRemote(NULL, CFSTR(MACH_PORT_NAME));
//    }
//    if (!messagePortSmulateTouch || !CFMessagePortIsValid(messagePortSmulateTouch)) {
//        return 0; //kCFMessagePortIsInvalid;
//    }
//    
//
//    STEvent event;
//    event.type = type;
//    event.index = index;
//    event.point_x = point.x;
//    event.point_y = point.y;
//
//    CFDataRef cfData = CFDataCreate(NULL, (uint8_t*)&event, sizeof(event));
//    CFDataRef rData = NULL;
//    
//    CFMessagePortSendRequest(messagePortSmulateTouch, 1/*type*/, cfData, 1, 1, kCFRunLoopDefaultMode, &rData);
//    
//    if (cfData) {
//        CFRelease(cfData);
//    }
//    
//    int pathIndex;
//    [(NSData *)rData getBytes:&pathIndex length:sizeof(pathIndex)];
//    
//    if (rData) {
//        CFRelease(rData);
//    }
//    
//    return pathIndex;
    @autoreleasepool {
        STEvent *event = [STEvent new];
        event->type = type;
        event->index = index;
        event->point_x = point.x;
        event->point_y = point.y;
        
        CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:@"com.wugensan.simulatetouchcenter"];
        rocketbootstrap_distributedmessagingcenter_apply(c);
        [c sendMessageName:@"simulateTouchMessage" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@1,@"simulateTouchEvent",[NSNumber numberWithInt:type],@"simulateTouchType",[NSNumber numberWithInt:index],@"simulateTouchIndex",[NSNumber numberWithFloat:point.x],@"simulateTouchPointX",[NSNumber numberWithFloat:point.y],@"simulateTouchPointY", nil]];
        return 0;
    }
    
}

static int record_touch_event()
{
//    if (messagePortRecordTouch && !CFMessagePortIsValid(messagePortRecordTouch)){
//        CFRelease(messagePortRecordTouch);
//        messagePortRecordTouch = NULL;
//    }
//    if (!messagePortRecordTouch) {
//        messagePortRecordTouch = rocketbootstrap_cfmessageportcreateremote(NULL, CFSTR(MACH_PORT_NAME));
//        //messagePort = CFMessagePortCreateRemote(NULL, CFSTR(MACH_PORT_NAME));
//    }
//    if (!messagePortRecordTouch || !CFMessagePortIsValid(messagePortRecordTouch)) {
//        return 0; //kCFMessagePortIsInvalid;
//    }
//    NSString *filePath = [[NSUserDefaults standardUserDefaults] objectForKey:SCRIPT_PATH_KEY];
//    const char* message = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
//    NSLog(@"message in record_touch_event() is : %s",message);
//    CFDataRef data;
//    data = CFDataCreate(NULL, (UInt8 *)message, strlen(message)+1);
////    char message[255]="There comes the data...";
////    CFDataRef data;
////    data = CFDataCreate(NULL, (UInt8 *)message, strlen(message)+1);
//    
//    CFDataRef rData = NULL;
//    CFMessagePortSendRequest(messagePortRecordTouch, 2/*type*/, data, 1, 1, kCFRunLoopDefaultMode, &rData);
//    if (data) {
//        CFRelease(data);
//    }
//    int pathIndex;
//    [(NSData *)rData getBytes:&pathIndex length:sizeof(pathIndex)];
//    if (rData) {
//        CFRelease(rData);
//    }
//    return pathIndex;
    @autoreleasepool {
        NSString *filePath = [[NSUserDefaults standardUserDefaults] objectForKey:SCRIPT_PATH_KEY];
        CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:@"com.wugensan.simulatetouchcenter"];
        rocketbootstrap_distributedmessagingcenter_apply(c);
        [c sendMessageName:@"simulateTouchMessage" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@2,@"simulateTouchEvent",filePath,@"scriptPath", nil]];
        return 0;
    }
    
}

static int end_record_touch_event()
{
//    if (messagePortEndRecordTouch && !CFMessagePortIsValid(messagePortEndRecordTouch)){
//        CFRelease(messagePortEndRecordTouch);
//        messagePortEndRecordTouch = NULL;
//    }
//    if (!messagePortEndRecordTouch) {
//        messagePortEndRecordTouch = rocketbootstrap_cfmessageportcreateremote(NULL, CFSTR(MACH_PORT_NAME));
//        //messagePort = CFMessagePortCreateRemote(NULL, CFSTR(MACH_PORT_NAME));
//    }
//    if (!messagePortEndRecordTouch || !CFMessagePortIsValid(messagePortEndRecordTouch)) {
//        return 0; //kCFMessagePortIsInvalid;
//    }
//    char message[255]="There comes the data...";
//    CFDataRef data;
//    data = CFDataCreate(NULL, (UInt8 *)message, strlen(message)+1);
//    
//    CFDataRef rData = NULL;
//    CFMessagePortSendRequest(messagePortEndRecordTouch, 3/*type*/, data, 1, 1, kCFRunLoopDefaultMode, &rData);
//    if (data) {
//        CFRelease(data);
//    }
//    int pathIndex;
//    [(NSData *)rData getBytes:&pathIndex length:sizeof(pathIndex)];
//    if (rData) {
//        CFRelease(rData);
//    }
//    return pathIndex;
    @autoreleasepool {
        CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:@"com.wugensan.simulatetouchcenter"];
        rocketbootstrap_distributedmessagingcenter_apply(c);
        [c sendMessageName:@"simulateTouchMessage" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@3,@"simulateTouchEvent", nil]];
        return 0;
    }
    
}

static int get_record_ready()
{
//    if (messagePortCustomLockButton && !CFMessagePortIsValid(messagePortCustomLockButton)){
//        CFRelease(messagePortCustomLockButton);
//        messagePortCustomLockButton = NULL;
//    }
//    if (!messagePortCustomLockButton) {
//        messagePortCustomLockButton = rocketbootstrap_cfmessageportcreateremote(NULL, CFSTR(GET_READY_PORT_NAME));
//        //messagePort = CFMessagePortCreateRemote(NULL, CFSTR(MACH_PORT_NAME));
//    }
//    if (!messagePortCustomLockButton || !CFMessagePortIsValid(messagePortCustomLockButton)) {
//        return 0; //kCFMessagePortIsInvalid;
//    }
//    char message[255]="There comes the data...";
//    CFDataRef data;
//    data = CFDataCreate(NULL, (UInt8 *)message, strlen(message)+1);
//    
//    CFDataRef rData = NULL;
//    CFMessagePortSendRequest(messagePortCustomLockButton, 4/*type*/, data, 1, 1, kCFRunLoopDefaultMode, &rData);
//    if (data) {
//        CFRelease(data);
//    }
//    int retVal;
//    [(NSData *)rData getBytes:&retVal length:sizeof(retVal)];
//    if (rData) {
//        CFRelease(rData);
//    }
//    return retVal;
    
    
    CFNotificationCenterRef distributedCenter =
    CFNotificationCenterGetDarwinNotifyCenter();
    
    CFNotificationCenterPostNotification(distributedCenter,
                                         CFSTR("com.wugensan.initlockbutton"),
                                         nil,
                                         nil,
                                         true);
    return 0;
}

//static CFDataRef messageCallBack(CFMessagePortRef local, SInt32 msgid, CFDataRef cfData, void *info)
//{
//    if (msgid == 5)
//    {
//        int ret = record_touch_event();
//        NSLog(@"开始录制 return %d... ... ... ...",ret);
//        return (CFDataRef)[[NSData alloc] initWithBytes:&ret length:sizeof(ret)];
//    }
//    else if (msgid == 6)
//    {
//        int ret = end_record_touch_event();
//        NSLog(@"结束录制 return %d... ... ... ...",ret);
//        return (CFDataRef)[[NSData alloc] initWithBytes:&ret length:sizeof(ret)];
//    }
//    return NULL;
//}

//static BOOL configure_message_port()
//{
//    if (!local) {
//        local = CFMessagePortCreateLocal(NULL, CFSTR(MESSAGE_BACK_FROM_LOCKBUTTON), messageCallBack, NULL, NULL);
//        if (rocketbootstrap_cfmessageportexposelocal(local) != 0) {
//            NSLog(@"### ST: RocketBootstrap failed");
//            return NO;
//        }
//        
//        CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(NULL, local, 0);
//        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
//        return YES;
//    }
//    return YES;
//}

double MachTimeToSecs(uint64_t time)
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer / (double)timebase.denom / 1e9;
}


static void _simulateTouchLoop()
{
    if (FTLoopIsRunning == FALSE) {
        return;
    }
    int touchCount = (int)[ATouchEvents count];
    
    if (touchCount == 0) {
        FTLoopIsRunning = FALSE;
        return;
    }
    
    NSMutableArray* willRemoveObjects = [NSMutableArray array];
    uint64_t curTime = mach_absolute_time();
    
    for (int i = 0; i < touchCount; i++)
    {
        STTouchA* touch = [ATouchEvents objectAtIndex:i];
        
        int touchType = touch->type;
        //0: move/stay 1: down 2: up
        
        if (touchType == 1) {
            //Already simulate_touch_event is called
            touch->type = STTouchMove;
        }else {
            double dif = MachTimeToSecs(curTime - touch->startTime);
            
            float req = touch->requestedTime;
            if (dif >= 0 && dif < req) {
                //Move
                
                float dx = touch->endPoint.x - touch->startPoint.x;
                float dy = touch->endPoint.y - touch->startPoint.y;
                
                double per = dif / (double)req;
                CGPoint point = CGPointMake(touch->startPoint.x + (float)(dx * per), touch->startPoint.y + (float)(dy * per));
                
                int r = simulate_touch_event(touch->pathIndex, STTouchMove, point);
                if (r != 0) {
                    NSLog(@"ST Error: touchLoop type:0 index:%d, point:(%d,%d) pathIndex:0", touch->pathIndex, (int)point.x, (int)point.y);
                    continue;
                }
                
            }else {
                //Up
                simulate_touch_event(touch->pathIndex, STTouchMove, touch->endPoint);
                int r = simulate_touch_event(touch->pathIndex, STTouchUp, touch->endPoint);
                if (r != 0) {
                    NSLog(@"ST Error: touchLoop type:2 index:%d, point:(%d,%d) pathIndex:0", touch->pathIndex, (int)touch->endPoint.x, (int)touch->endPoint.y);
                    continue;
                }
                
                [willRemoveObjects addObject:touch];
            }
        }
    }
    
    for (STTouchA* touch in willRemoveObjects) {
        [ATouchEvents removeObject:touch];
        //[touch release];
    }
    
    willRemoveObjects = nil;
    
    //recursive
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / LOOP_TIMES_IN_SECOND);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        _simulateTouchLoop();
    });
}

#pragma mark -

@interface MessageUtil : NSObject

+(void)handleMessageNamed:(NSString*)name withUserInfo:(NSDictionary*)info;

@end

@implementation MessageUtil

+(void)handleMessageNamed:(NSString*)name withUserInfo:(NSDictionary*)info
{
    if ([name isEqualToString:@"lockButtonMessage"]) {
        if ([[info objectForKey:@"lockButtonEvent"] intValue] == 1) {
            NSLog(@"----- begin recording ...");
            int ret = record_touch_event();
            NSLog(@"----- record_touch_event returned : %d",ret);
        }
        if ([[info objectForKey:@"lockButtonEvent"] intValue] == 2) {
            NSLog(@"----- end recording ...");
            int ret = end_record_touch_event();
            NSLog(@"----- end_record_touch_event returned : %d",ret);
        }
    }
}

@end

@interface CNSimulateTouch : NSObject
@end

@implementation CNSimulateTouch

//+ (instancetype)sharedCNSimulateTouchInstance
//{
//    static CNSimulateTouch *instance = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        instance = [[CNSimulateTouch alloc] init];
//    });
//    return instance;
//}

+(CGPoint)STScreenToWindowPoint:(CGPoint)point withOrientation:(UIInterfaceOrientation)orientation {
    CGSize screen = [[UIScreen mainScreen] bounds].size;
    
    if (orientation == UIInterfaceOrientationPortrait) {
        return point;
    }else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGPointMake(screen.width - point.x, screen.height - point.y);
    }else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        //Homebutton is left
        return CGPointMake(screen.height - point.y, point.x);
    }else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGPointMake(point.y, screen.width - point.x);
    }else return point;
}

+(CGPoint)STWindowToScreenPoint:(CGPoint)point withOrientation:(UIInterfaceOrientation)orientation {
    CGSize screen = [[UIScreen mainScreen] bounds].size;
    
    if (orientation == UIInterfaceOrientationPortrait) {
        return point;
    }else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGPointMake(screen.width - point.x, screen.height - point.y);
    }else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        //Homebutton is left
        return CGPointMake(point.y, screen.height - point.x);
    }else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGPointMake(screen.width - point.y, point.x);
    }else return point;
}

+(BOOL)configureMessagePort
{
    CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:@"com.wugensan.lockbuttoncenter"];
    rocketbootstrap_distributedmessagingcenter_apply(c);
    [c runServerOnCurrentThread];
    [c registerForMessageName:@"lockButtonMessage" target:[MessageUtil class] selector:@selector(handleMessageNamed:withUserInfo:)];
    
    return YES;
}

+(int)getRecordReadyToFile:(NSString*)fileName
{

    NSString *file_path = [SCRIPT_PATH stringByAppendingString:fileName];
    const char* filePath = [file_path cStringUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"file_path in getRecordReadyToFile is : %@",file_path);
    [[NSUserDefaults standardUserDefaults] setObject:file_path forKey:SCRIPT_PATH_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    int isExsit = access(filePath, 0);
    if (isExsit == 0) {
        NSLog(@"文件重名 ... ... ...");
        //return -2;
    }
    FILE *fp;
    if((fp = fopen(filePath,"wt+")))
    {
        NSLog(@"getRecordReadyToFile: 打开文件成功");
        fclose(fp);
        if(chmod(filePath, 0777) == 0)
        {
            NSLog(@"getRecordReadyToFile: 修改权限成功");
        }
        else
        {
            NSLog(@"getRecordReadyToFile: 修改权限失败");
        }
    }
    else
    {
        NSLog(@"打开文件失败");
        return -1;
    }
    
    
    
    int r = get_record_ready();
    if (r == 0) {
        NSLog(@"get_record_ready : 初始化锁屏键成功");
        return 1;
    }
    else{
        NSLog(@"get_record_ready : 初始化通讯接口失败");
    }
    return 0;
}

+(int)simulateTouch:(int)pathIndex atPoint:(CGPoint)point withType:(STTouchType)type
{
    int r = simulate_touch_event(pathIndex, type, point);
    
    if (r != 0) {
        NSLog(@"ST Error: simulateTouch:atPoint:withType: index:%d type:%d pathIndex:0", pathIndex, type);
        return 0;
    }
    return r;
}

+(int)simulateSwipe:(int)pathIndex toPoint:(CGPoint)toPoint
{
    int r = simulate_touch_event(pathIndex, STTouchMove, toPoint);
    
    if (r != 0) {
        NSLog(@"ST Error: simulateTouch:atPoint:withType: index:%d type:%d pathIndex:0", pathIndex, STTouchMove);
        return 0;
    }
    return r;
}

+(int)simulateSwipeFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(float)duration
{
    if (ATouchEvents == nil) {
        ATouchEvents = [[NSMutableArray alloc] init];
    }
    
    STTouchA* touch = [[STTouchA alloc] init];
    
    touch->type = STTouchMove;
    touch->startPoint = fromPoint;
    touch->endPoint = toPoint;
    touch->requestedTime = duration;
    touch->startTime = mach_absolute_time();
    
    [ATouchEvents addObject:touch];
    
    int r = simulate_touch_event(0, STTouchDown, fromPoint);
    if (r != 0) {
        NSLog(@"ST Error: simulateSwipeFromPoint:toPoint:duration: pathIndex:0");
        return 0;
    }
    touch->pathIndex = r;
    
    if (!FTLoopIsRunning) {
        FTLoopIsRunning = TRUE;
        _simulateTouchLoop();
    }
    
    return r;
}

@end