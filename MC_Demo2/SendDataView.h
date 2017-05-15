//
//  SendDataView.h
//  MC_Demo2
//
//  Created by double on 2017/5/12.
//  Copyright © 2017年 double. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SendDataView : UIView
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *sendDataBtn;
@property (weak, nonatomic) IBOutlet UIButton *sendResourceBtn;
@property (weak, nonatomic) IBOutlet UIButton *sendStream;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property(nonatomic,copy) void (^sendData)(NSData *data);
@property(nonatomic,copy) void (^sendResource)(NSString *filePath);
@property(nonatomic,copy) void (^sendStreamBlock)(NSString *path);

- (void)log:(NSString *)text;

@end
