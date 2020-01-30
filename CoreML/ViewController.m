//
//  ViewController.m
//  CoreML
//
//  Created by DayDream on 2019/3/14.
//  Copyright © 2019 蛤蛤. All rights reserved.
//
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IOS_11  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.f)
#define IS_IPHONE_X  (IS_IOS_11 && IS_IPHONE && (MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) >= 375 && MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) >= 812))
#define ScreenWidth self.view.frame.size.width
#define ScreenHeight self.view.frame.size.height
#import "ViewController.h"
#import "MobileNet.h"
#import  <Masonry.h>
#import <EasyReact.h>
@interface ViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (nonatomic,strong) UIImagePickerController *imageVC;

@property (nonatomic,strong) EZRMutableNode *imageNode;

@property (nonatomic,strong) UILabel *info;

@end

@implementation ViewController
-(UIImagePickerController *)imageVC
{
    if (!_imageVC) {
        _imageVC = [[UIImagePickerController alloc]init];
        _imageVC.delegate = self;
        
    }
    return _imageVC;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Core ML";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImage *image =[UIImage new];
    UIImageView *imageView = [[UIImageView alloc]initWithImage:image];
    
    [self.view addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(IS_IPHONE_X?88+20:64+20);
        make.height.mas_equalTo(ScreenWidth/2.0);
    }];
    self.imageNode =[EZRMutableNode value:image];
    
    
    UILabel *info = [[UILabel alloc]init];
    info.text = @"请先选择照片";
    info.textColor = [UIColor blackColor];
    info.font = [UIFont systemFontOfSize:16.f];
    [imageView addSubview:info];
    [info mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(imageView);
    }];
    self.info = info;
  
    UIButton *album = [UIButton buttonWithType:UIButtonTypeCustom];
    [album setTitle:@"Choose in Album" forState:UIControlStateNormal];
    [album setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [album  setBackgroundColor:[UIColor orangeColor]];
    album.layer.cornerRadius = 10.f;
    album.layer.masksToBounds= YES;
    [self.view addSubview:album];
    [album mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(imageView.mas_bottom).offset(20.0);
        make.width.mas_equalTo(ScreenWidth/2.0);
        make.height.mas_equalTo(44.0);
    }];
    album.tag = 101;
    [album addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *shoot = [UIButton buttonWithType:UIButtonTypeCustom];
    [shoot setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [shoot setBackgroundColor:[UIColor cyanColor]];
    shoot.layer.cornerRadius = 10.f;
    
    shoot.layer.masksToBounds = YES;
    shoot.tag = 102;
    [shoot setTitle:@"Take a shoot" forState:UIControlStateNormal];
    [shoot addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shoot];
    [shoot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(album.mas_bottom).offset(20.0);
        make.width.mas_equalTo(ScreenWidth/2.0);
        make.height.mas_equalTo(44.0);
    }];
    
    UILabel *label = [[UILabel alloc]init];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"";
    label.backgroundColor =[UIColor blackColor];
   
    [self.view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(shoot.mas_bottom).offset(80.0);
        make.height.mas_equalTo(44.0);
    }];
    
    [[self.imageNode listenedBy:self] withBlock:^(UIImage *   image) {
        
        imageView.image = image;
        label.text = [NSString stringWithFormat:@"Result: %@",[self preferedToImage:image]];
    }];
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(NSString *)preferedToImage:(UIImage *)image

{
    MobileNet *coreML = [[MobileNet alloc]init];
  
    UIImage *scaleImage = [self scaleToSize:CGSizeMake(224, 224) image:image];
    CVPixelBufferRef buffer = [self pixelBufferFromCGImage:scaleImage.CGImage];
    
    MobileNetOutput *output = [coreML predictionFromImage:buffer error:nil];
    
    return output.classLabel;

}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image{
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
- (UIImage *)scaleToSize:(CGSize)size image:(UIImage *)image {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}


-(void)buttonClick:(UIButton *)sender
{
    if (sender.tag == 101) {
        self.imageVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
    }
    else
        self.imageVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self.navigationController presentViewController:self.imageVC animated:YES completion:nil];
}


- (void) imageWasSavedSuccessfully:(UIImage *)paramImage didFinishSavingWithError:(NSError *)paramError contextInfo:(void *)paramContextInfo{
    
    if (paramError == nil){
        
        NSLog(@"Image was saved successfully.");
        
    } else {
        
        NSLog(@"An error happened while saving the image.");
        
        NSLog(@"Error = %@", paramError);
        
    }
    
}

// 当得到照片或者视频后，调用该方法

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    NSLog(@"Picker returned successfully.");
    
    NSLog(@"%@", info);
    
  //  NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        // 保存图片到相册中
        
//    SEL selectorToCall = @selector(imageWasSavedSuccessfully:didFinishSavingWithError:contextInfo:);
//        
//        UIImageWriteToSavedPhotosAlbum(image, self,selectorToCall, NULL);
    self.imageNode.value = image;
    self.info.hidden = YES;
    [picker dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - 摄像头和相册相关的公共类



// 判断设备是否有摄像头

- (BOOL) isCameraAvailable{
    
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    
}



// 前面的摄像头是否可用

- (BOOL) isFrontCameraAvailable{
    
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
    
}



// 后面的摄像头是否可用

- (BOOL) isRearCameraAvailable{
    
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
    
}






@end
