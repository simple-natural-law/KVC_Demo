//
//  BankAccount.h
//  KVC_Demo
//
//  Created by 张诗健 on 2018/7/15.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Person, Transaction;

/// 银行账户类
@interface BankAccount : NSObject

@property (nonatomic) NSNumber *currentBalance;              // An attribute
@property (nonatomic) Person *owner;                         // A to-one relation
@property (nonatomic) NSArray<Transaction *> *transactions; // A to-many relation

@end
