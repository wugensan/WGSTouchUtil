#import <Foundation/Foundation.h>

typedef enum {
    STTouchMove = 0,
    STTouchDown,
    STTouchUp
} STTouchType;

//Library - libsimulatetouch.dylib
@interface CNSimulateTouch

//+ (instancetype)sharedCNSimulateTouchInstance;

/**
 *  初始化监听端口, 当需要录制点击事件的时候需要首先调用此函数, 模拟触摸不需要调用
 *
 *  @return NO : error  YES : succeed
 */
+(BOOL)configureMessagePort;

/**
 *  准备录制, 此函数hook了锁屏按钮, 调用此函数后, 按下锁屏键录制开始, 再次按下结束录制
 *
 *  @param fileName 录制脚本存储文件名, 文件默认存储在/private/var/cnsimtouch/script/路径下
 *
 *  @return 0 : 创建通信端口失败 ; 1 : 成功 ; -1 创建文件失败 ; -2 文件重名
 */
+(int)getRecordReadyToFile:(NSString*)fileName;


/**
 *  模拟手指按下及抬起事件
 *
 *  @param pathIndex 标识此触摸事件的索引
 *  @param point     触摸点(像素坐标)
 *  @param type      触摸类型，按下或者抬起
 *
 *  @return 0 : error  pathIndex : succeed
 */
+(int)simulateTouch:(int)pathIndex atPoint:(CGPoint)point withType:(STTouchType)type;

/**
 *  滑动到指定坐标点
 *
 *  @param toPoint 目标坐标点
 *
 *  @return 0 : error  pathIndex : succeed
 */
+(int)simulateSwipe:(int)pathIndex toPoint:(CGPoint)toPoint;

/**
 *  两点之间模拟滑动
 *
 *  @param fromPoint 起始坐标点
 *  @param toPoint   结束坐标点
 *  @param duration  滑动事件间隔
 *
 *  @return 0 : error  非0正值 : succeed
 */
+(int)simulateSwipeFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(float)duration;
@end