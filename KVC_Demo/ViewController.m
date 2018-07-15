//
//  ViewController.m
//  KVC_Demo
//
//  Created by 张诗健 on 2018/7/10.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import "ViewController.h"
#import "BankAccount.h"
#import "Person.h"
#import "Transaction.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    BankAccount *bankAccount = [[BankAccount alloc] init];
    
    bankAccount.currentBalance = [NSNumber numberWithFloat:100.0];
    
    Person *person = [[Person alloc] init];
    
    
    // 使用KVC给属性设置值
    // 使用key
    [bankAccount setValue:person forKey:@"owner"];
    // 使用keyPath
    [bankAccount setValue:@"ZhangSan" forKeyPath:@"owner.name"];
    NSLog(@"KVC设置属性值 ====== %@",bankAccount.owner.name);
    
    // 使用KVC读取属性值
    // 使用key
    NSString *currentBalance = [bankAccount valueForKey:@"currentBalance"];
    NSLog(@"KVC读取属性值(key) ====== %@",currentBalance);
    // 使用keyPath
    NSString *name = [bankAccount valueForKeyPath:@"owner.name"];
    NSLog(@"KVC读取属性值(key) ====== %@",name);
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
