//
//  SendDataView.m
//  MC_Demo2
//
//  Created by double on 2017/5/12.
//  Copyright © 2017年 double. All rights reserved.
//

#import "SendDataView.h"

@implementation SendDataView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (IBAction)sendDataAction:(id)sender {
    if (_sendData && self.textField.text.length) {
        NSData *data = [self.textField.text dataUsingEncoding:NSUTF8StringEncoding];
        _sendData(data);
    }
}
- (IBAction)sendResourceAction:(id)sender {
    if (_sendResource) {
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"iOS技能树" ofType:@"jpg"];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"陶喆-寂寞的季节" ofType:@"mp4"];
        _sendResource(path);
    }
}
- (IBAction)sendStreamAction:(id)sender {
    if (_sendStreamBlock) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"iOS技能树" ofType:@"jpg"];
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"陶喆-寂寞的季节" ofType:@"mp4"];
        _sendStreamBlock(path);
    }
}
- (IBAction)sliderValueChange:(UISlider *)sender {
    NSLog(@"%f",sender.value);
    if (_sendData) {
        NSString *dataString = [NSString stringWithFormat:@"%f",sender.value];
        NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        _sendData(data);
    }
}

#pragma mark - 接口方法
- (void)log:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableString *mString = [[NSMutableString alloc] initWithString:self.logTextView.text];
        [mString appendString:text];
        [mString appendString:@"\n"];
        self.logTextView.text = mString;
    });
}

@end
