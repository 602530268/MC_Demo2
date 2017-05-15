//
//  ViewController.m
//  MC_Demo2
//
//  Created by double on 2017/5/11.
//  Copyright © 2017年 double. All rights reserved.
//

#import "ViewController.h"
#import "CreateVC.h"
#import "JoinVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)createRoom:(id)sender {
    
    CreateVC *vc = [[CreateVC alloc] initWithNibName:NSStringFromClass([CreateVC class]) bundle:[NSBundle mainBundle]];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)joinRoom:(id)sender {
    
    JoinVC *vc = [[JoinVC alloc] initWithNibName:NSStringFromClass([JoinVC class]) bundle:[NSBundle mainBundle]];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
