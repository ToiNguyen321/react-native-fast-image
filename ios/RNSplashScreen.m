/**
 * SplashScreen
 * 启动屏
 * from：http://www.devio.org
 * Author:CrazyCodeBoy
 * GitHub:https://github.com/crazycodeboy
 * Email:crazycodeboy@gmail.com
 */

#import "RNSplashScreen.h"
#import <React/RCTBridge.h>
#import "FileUtils.h"
#import "Utils.h"
#import <SDWebImage/UIImageView+WebCache.h>

static bool waiting = true;
static bool addedJsLoadErrorObserver = false;
static UIView* loadingView = nil;

static NSString* _userDefaultsKey = @"dynamicSplashConfig";
static NSString* _fileName = @"LaunchImage";
@implementation RNSplashScreen
- (dispatch_queue_t)methodQueue{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE(SplashScreen)

+ (void)show {
    if (!addedJsLoadErrorObserver) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jsLoadError:) name:RCTJavaScriptDidFailToLoadNotification object:nil];
        addedJsLoadErrorObserver = true;
    }

    while (waiting) {
        NSDate* later = [NSDate dateWithTimeIntervalSinceNow:0.1];
        [[NSRunLoop mainRunLoop] runUntilDate:later];
    }
}

+ (void)showSplashWithRootView:(RCTRootView *)rootView imageUrl:(NSString *) imageUrl {
    if (!loadingView) {
        loadingView = [self getImageView:imageUrl];
        CGRect frame = rootView.frame;
        frame.origin = CGPointMake(0, 0);
        loadingView.frame = frame;
    }
    waiting = false;
    [rootView addSubview:loadingView];
    [RNSplashScreen downloadSplashImg:imageUrl];
}

+ (void)hide {
    if (waiting) {
        dispatch_async(dispatch_get_main_queue(), ^{
            waiting = false;
        });
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [loadingView removeFromSuperview];
        });
    }
}

+ (void) jsLoadError:(NSNotification*)notification
{
    // If there was an error loading javascript, hide the splash screen so it can be shown.  Otherwise the splash screen will remain forever, which is a hassle to debug.
    [RNSplashScreen hide];
}

+ (UIImageView *)getImageView:(NSString *) imageUrl{
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
//    imageView.image = [self getImage];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.backgroundColor = [UIColor whiteColor];
    imageView.userInteractionEnabled = YES;
//    UIImage *imageCache = [RNSplashScreen getImageCache];
//    if(imageCache != nil){
//        imageView.image = imageCache;
//    }else{
        [imageView sd_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage imageNamed:@"LaunchImage"] options:SDWebImageRefreshCached completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        }];
//    }
    return imageView;
}

+ (UIImage *)getImageCache {
    return [FileUtils loadImage:_fileName inDirectory:[RNSplashScreen getDocumentPath]];
    
}

+ (UIImage *)getImage {
    UIImage * localImage = [FileUtils loadImage:_fileName inDirectory:[RNSplashScreen getDocumentPath]];
    if(localImage != nil) {
        return localImage;
    }

    NSString *launchImageName = [[NSBundle mainBundle] pathForResource:_fileName ofType:@"png"];
    if(![Utils isBlankString: launchImageName]) {
      return [UIImage imageNamed:launchImageName];
    }
    return [UIImage imageNamed:_fileName];
}

+ (void)downloadSplashImg:(NSString *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *imageUrl = url;
        if(![Utils isBlankString: imageUrl]) {
            UIImage *image = [FileUtils getImageFromURL:imageUrl];
            [FileUtils saveImage:image withFileName:_fileName inDirectory:[RNSplashScreen getDocumentPath]];
        }
    });
}

+(NSString *)getDocumentPath{
    NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [docsdir stringByAppendingPathComponent:@"splashDynamic"];
}

RCT_EXPORT_METHOD(downloadSplash:(NSString *)url) {
    [RNSplashScreen downloadSplashImg:url];
}

RCT_EXPORT_METHOD(hide) {
    [RNSplashScreen hide];
}

RCT_EXPORT_METHOD(show) {
    [RNSplashScreen show];
}

@end
