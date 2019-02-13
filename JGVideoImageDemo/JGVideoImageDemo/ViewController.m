//
//  ViewController.m
//  JGVideoImageDemo
//
//  Created by mtgao on 2018/12/29.
//  Copyright © 2018 ggd. All rights reserved.
//

#import "ViewController.h"
#import "JGCamera.h"
#import "JGImageConverter.h"
#import "JGCameraPreview.h"

@interface ViewController ()
@property (strong, nonatomic)JGCamera *camera;
@property (strong, nonatomic) IBOutlet JGCameraPreview *cameraView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.camera = [[JGCamera alloc]init];
    self.camera.preview = self.cameraView;
    __weak typeof(self) weakSelf = self;
    [self.camera captureVideoData:^(CMSampleBufferRef  _Nonnull samplebuffer, NSError * _Nonnull error) {
        CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(samplebuffer);
        __strong typeof(self) strongSelf = weakSelf;
        
//        NSLog(@"capture frame:(%zu,%zu)",CVPixelBufferGetWidth(pb),CVPixelBufferGetHeight(pb));
    }];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)doRemove{
    for(id view in self.view.subviews){
        if([view isKindOfClass:[UIImageView class]]){
            UIImageView *tmp = view;
            if(tmp.tag == 10){
                [tmp removeFromSuperview];
            }
        }
    }
}

- (IBAction)switchCamera:(id)sender {
    [self.camera switchCamera];
   
}

- (IBAction)livePhotoEnable:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    
    BOOL isLivePhotoCaptureEnabled = self.camera.isLivePhotoCaptureEnabled;
    self.camera.livePhotoCaptureEnabled = !isLivePhotoCaptureEnabled;
    
    if(self.camera.isLivePhotoCaptureEnabled){
        [btn setTitle:@"livephoto on" forState:UIControlStateNormal];
    }else{
        [btn setTitle:@"livephoto off" forState:UIControlStateNormal];
    }
}


- (IBAction)switchPreset:(id)sender {
    
    NSString *oldPreset = self.camera.sessionPreset;
    
    NSString *newPreset = nil;
    if(oldPreset == AVCaptureSessionPresetPhoto){
        newPreset = AVCaptureSessionPreset1280x720;
    }else if(oldPreset == AVCaptureSessionPreset1280x720){
        newPreset = AVCaptureSessionPresetPhoto;
    }else{
        
    }
    
    self.camera.sessionPreset = newPreset;
    
    UIButton *btn = (UIButton *)sender;
    [btn setTitle:self.camera.sessionPreset forState:UIControlStateNormal];
}


- (IBAction)takephoto:(id)sender {
    
    AVCaptureDevicePosition position = self.camera.camera.device.position;
    
    [self.camera takePhoto:^(AVCapturePhoto * _Nonnull photo, NSError * _Nonnull error) {
        CVPixelBufferRef pixelPhoto = photo.pixelBuffer;
        NSLog(@"OSType = %d",CVPixelBufferGetPixelFormatType(pixelPhoto));
        
        if(pixelPhoto == nil){
            UIImage *jpegImage = [[UIImage alloc]initWithData:photo.fileDataRepresentation];
            UIImage *fixImage = nil;
            if(position == AVCaptureDevicePositionFront){
                fixImage = [UIImage imageWithCGImage:jpegImage.CGImage scale:jpegImage.scale orientation:UIImageOrientationLeftMirrored];
            }else{
                fixImage = jpegImage;
            }

            UIImageView *imageView = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
            imageView.tag = 10;
            [imageView setContentMode:UIViewContentModeScaleAspectFit];
            imageView.image = fixImage;
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doRemove)];
            tap.numberOfTouchesRequired = 1;
            imageView.userInteractionEnabled = YES;
            
            [imageView addGestureRecognizer:tap];
            [self.view addSubview:imageView];
        }
    }];
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.camera cameraDebugInfo];
}
@end
